import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentData,
  type DocumentSnapshot,
  type QuerySnapshot,
} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { dailySeed } from './daily.js';
import {
  boundedAmount,
  economyItem,
  requestId,
  safeBalance,
  type EconomyItem,
} from './economy.js';

initializeApp();

const db = getFirestore();
const region = process.env.FUNCTIONS_REGION ?? 'asia-south1';
const appCheckRequired = process.env.ENFORCE_APP_CHECK === 'true';
const callableOptions = {
  region,
  maxInstances: 10,
  enforceAppCheck: appCheckRequired,
};

type CallableRequest = {
  auth?: { uid: string } | null;
  data?: Record<string, unknown>;
};

function uidFrom(request: { auth?: { uid: string } | null }): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  return uid;
}

function dataFrom(request: CallableRequest): Record<string, unknown> {
  return request.data ?? {};
}

function invalidArgument(message: string): never {
  throw new HttpsError('invalid-argument', message);
}

type EconomyState = {
  coins: number;
  hints: number;
  undos: number;
  ownedSkins: string[];
};

function economyResponse(state: EconomyState): EconomyState {
  return {
    coins: state.coins,
    hints: state.hints,
    undos: state.undos,
    ownedSkins: state.ownedSkins,
  };
}

function readEconomyState(snapshot: DocumentSnapshot): EconomyState {
  try {
    const rawSkins = snapshot.get('ownedSkins');
    const ownedSkins =
      rawSkins === undefined
        ? ['classic']
        : Array.isArray(rawSkins) &&
            rawSkins.every((skin): skin is string => typeof skin === 'string')
          ? rawSkins
          : null;
    if (ownedSkins === null || ownedSkins.length > 20) {
      throw new Error('invalid-skins');
    }
    return {
      coins: safeBalance(snapshot.get('coins')),
      hints: safeBalance(snapshot.get('hints')),
      undos: safeBalance(snapshot.get('undos')),
      ownedSkins: [...new Set(ownedSkins)],
    };
  } catch {
    throw new HttpsError('data-loss', 'The economy state is invalid.');
  }
}

async function assertNotBanned(uid: string): Promise<void> {
  const user = await db.collection('users').doc(uid).get();
  if (user.get('banned') === true) {
    throw new HttpsError('permission-denied', 'This account cannot use online features.');
  }
}

async function enforceRateLimit(uid: string, action: string, intervalMs: number): Promise<void> {
  const ref = db.collection('functionRateLimits').doc(`${uid}_${action}`);
  const now = Date.now();
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const lastCall = snapshot.get('lastCallAt') as Timestamp | undefined;
    if (lastCall && now - lastCall.toMillis() < intervalMs) {
      throw new HttpsError('resource-exhausted', 'Please wait before trying again.');
    }
    transaction.set(ref, {
      uid,
      action,
      lastCallAt: Timestamp.fromMillis(now),
      schemaVersion: 1,
    });
  });
}

/** Grants a once-per-UTC-day reward using an idempotent server ledger entry. */
export const claimDailyReward = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await assertNotBanned(uid);
  await enforceRateLimit(uid, 'claimDailyReward', 1500);

  const now = new Date();
  const userRef = db.collection('users').doc(uid);
  const dayKey = now.toISOString().slice(0, 10);
  const economyRef = db.collection('users').doc(uid).collection('economy').doc('state');
  const configRef = db.doc('config/public');
  const claimRef = userRef.collection('daily').doc(dayKey);
  const ledgerRef = db.collection('users').doc(uid).collection('ledger').doc(`${dayKey}-daily-reward`);
  const reward = 20;

  const result = await db.runTransaction(async (transaction) => {
    const [claim, economy, config] = await Promise.all([
      transaction.get(claimRef),
      transaction.get(economyRef),
      transaction.get(configRef),
    ]);
    if (claim.exists) {
      throw new HttpsError('already-exists', 'Daily reward already claimed.');
    }
    const state = readEconomyState(economy);
    const oldBalance = state.coins;
    const configuredReward = Number(config.get('dailyRewardCoins') ?? reward);
    if (!Number.isSafeInteger(configuredReward) || configuredReward < 1 || configuredReward > 500) {
      throw new HttpsError('failed-precondition', 'Daily rewards are not configured.');
    }
    const balance = oldBalance + configuredReward;
    transaction.set(economyRef, {
      coins: balance,
      hints: state.hints,
      undos: state.undos,
      ownedSkins: state.ownedSkins,
      schemaVersion: 1,
      updatedAt: FieldValue.serverTimestamp(),
      ...(!economy.exists ? { createdAt: FieldValue.serverTimestamp() } : {}),
    }, { merge: true });
    transaction.create(claimRef, {
      completed: true,
      claimedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    transaction.create(ledgerRef, {
      type: 'earn',
      amount: configuredReward,
      reason: 'daily_reward',
      source: dayKey,
      createdAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    return { balance, reward: configuredReward };
  });

  logger.info('daily_reward_claimed', { uid, dayKey });
  return {
    dayKey,
    coinsGranted: result.reward,
    newBalance: result.balance,
  };
});

export const purchaseEconomyItem = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await assertNotBanned(uid);
  await enforceRateLimit(uid, 'purchaseEconomyItem', 500);
  const data = dataFrom(request);
  let item: EconomyItem;
  let idempotencyKey: string;
  try {
    item = economyItem(data.itemId);
    idempotencyKey = requestId(data.requestId);
  } catch (error) {
    invalidArgument(error instanceof Error ? error.message : 'invalid-request');
  }
  const economyRef = db.collection('users').doc(uid).collection('economy').doc('state');
  const ledgerRef = db.collection('users').doc(uid).collection('ledger').doc(idempotencyKey);
  const result = await db.runTransaction(async (transaction) => {
    const [economy, ledger] = await Promise.all([
      transaction.get(economyRef),
      transaction.get(ledgerRef),
    ]);
    const state = readEconomyState(economy);
    if (ledger.exists) return { alreadyApplied: true, balance: state.coins };
    const coins = state.coins;
    const hints = state.hints;
    const undos = state.undos;
    const ownedSkins = new Set(state.ownedSkins);
    if (coins < item.cost) {
      throw new HttpsError('failed-precondition', 'insufficient-coins');
    }
    if (item.skinId && ownedSkins.has(item.skinId)) {
      throw new HttpsError('already-exists', 'item-already-owned');
    }
    if (item.skinId) ownedSkins.add(item.skinId);
    const balance = coins - item.cost;
    transaction.set(
      economyRef,
      {
        coins: balance,
        hints: hints + item.hints,
        undos: undos + item.undos,
        ownedSkins: [...ownedSkins].sort(),
        schemaVersion: 1,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.create(ledgerRef, {
      type: 'purchase',
      itemId: item.id,
      amount: item.cost,
      idempotencyKey,
      createdAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    return { alreadyApplied: false, balance };
  });
  const economy = await economyRef.get();
  return {
    ...result,
    itemId: item.id,
    state: economyResponse(readEconomyState(economy)),
  };
});

export const spendEconomyResource = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await assertNotBanned(uid);
  await enforceRateLimit(uid, 'spendEconomyResource', 250);
  const data = dataFrom(request);
  const action = data.action;
  if (action !== 'hint' && action !== 'undo' && action !== 'revive') {
    invalidArgument('invalid-action');
  }
  let idempotencyKey: string;
  try {
    idempotencyKey = requestId(data.requestId);
  } catch (error) {
    invalidArgument(error instanceof Error ? error.message : 'invalid-request');
  }
  const economyRef = db.collection('users').doc(uid).collection('economy').doc('state');
  const ledgerRef = db.collection('users').doc(uid).collection('ledger').doc(idempotencyKey);
  const result = await db.runTransaction(async (transaction) => {
    const [economy, ledger] = await Promise.all([
      transaction.get(economyRef),
      transaction.get(ledgerRef),
    ]);
    const state = readEconomyState(economy);
    if (ledger.exists) return { alreadyApplied: true, state };
    const next = { ...state };
    if (action === 'hint') {
      if (next.hints < 1) throw new HttpsError('failed-precondition', 'insufficient-hints');
      next.hints--;
    } else if (action === 'undo') {
      if (next.undos < 1) throw new HttpsError('failed-precondition', 'insufficient-undos');
      next.undos--;
    } else {
      if (next.coins < 30) throw new HttpsError('failed-precondition', 'insufficient-coins');
      next.coins -= 30;
    }
    transaction.set(economyRef, {
      ...next,
      schemaVersion: 1,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    transaction.create(ledgerRef, {
      type: 'spend',
      action,
      amount: action === 'revive' ? 30 : 1,
      idempotencyKey,
      createdAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    return { alreadyApplied: false, state: next };
  });
  return { ...result, state: economyResponse(result.state) };
});

export const claimEconomyReward = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await assertNotBanned(uid);
  await enforceRateLimit(uid, 'claimEconomyReward', 500);
  const data = dataFrom(request);
  let claimId: string;
  let idempotencyKey: string;
  try {
    claimId = requestId(data.claimId);
    idempotencyKey = requestId(data.requestId);
  } catch (error) {
    invalidArgument(error instanceof Error ? error.message : 'invalid-request');
  }
  const claimRef = db.collection('users').doc(uid).collection('claimables').doc(claimId);
  const economyRef = db.collection('users').doc(uid).collection('economy').doc('state');
  const ledgerRef = db.collection('users').doc(uid).collection('ledger').doc(idempotencyKey);
  const result = await db.runTransaction(async (transaction) => {
    const [claim, economy, ledger] = await Promise.all([
      transaction.get(claimRef),
      transaction.get(economyRef),
      transaction.get(ledgerRef),
    ]);
    const state = readEconomyState(economy);
    if (ledger.exists) return { alreadyApplied: true, balance: state.coins };
    if (!claim.exists || claim.get('uid') !== uid || claim.get('claimed') === true) {
      throw new HttpsError('failed-precondition', 'reward-not-claimable');
    }
    const amount = (() => {
      try {
        return boundedAmount(claim.get('coins'));
      } catch {
        throw new HttpsError('data-loss', 'reward-configuration-invalid');
      }
    })();
    const balance = state.coins + amount;
    transaction.set(
      economyRef,
      {
        coins: balance,
        hints: state.hints,
        undos: state.undos,
        ownedSkins: state.ownedSkins,
        schemaVersion: 1,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.update(claimRef, {
      claimed: true,
      claimedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(ledgerRef, {
      type: 'earn',
      amount,
      reason: claim.get('reason') ?? 'reward',
      claimId,
      idempotencyKey,
      createdAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    return { alreadyApplied: false, balance };
  });
  const economy = await economyRef.get();
  return {
    ...result,
    claimId,
    state: economyResponse(readEconomyState(economy)),
  };
});

/** Exports a signed-in player's own account data for a privacy request. */
export const exportMyData = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await enforceRateLimit(uid, 'exportMyData', 60_000);

  const userRef = db.collection('users').doc(uid);
  const [profile, progress, ledger, purchases, daily] = await Promise.all([
    userRef.get(),
    userRef.collection('progress').get(),
    userRef.collection('ledger').limit(500).get(),
    userRef.collection('purchases').limit(100).get(),
    userRef.collection('daily').limit(400).get(),
  ]);
  const serialize = (snapshot: QuerySnapshot<DocumentData>) =>
    snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  logger.info('user_data_exported', { uid });
  return {
    schemaVersion: 1,
    exportedAt: nowIso(),
    profile: profile.exists ? profile.data() : null,
    progress: serialize(progress),
    ledger: serialize(ledger),
    purchases: serialize(purchases),
    daily: serialize(daily),
  };
});

/** Deletes all account documents and then removes the Firebase Auth user. */
export const deleteAccount = onCall(callableOptions, async (request) => {
  const uid = uidFrom(request);
  await enforceRateLimit(uid, 'deleteAccount', 5000);
  const userRef = db.collection('users').doc(uid);
  try {
    await db.recursiveDelete(userRef);
    await deleteUserIndexRows(uid);
    await getAuth().deleteUser(uid);
  } catch (error) {
    logger.error('account_deletion_failed', { uid, error });
    throw new HttpsError('internal', 'Account deletion could not be completed.');
  }
  logger.info('account_deleted', { uid });
  return { deleted: true };
});

/** Creates tomorrow's shared UTC daily seed; the game client expands the seed. */
export const generateDailyChallenge = onSchedule(
  { schedule: '0 0 * * *', timeZone: 'Etc/UTC', region, maxInstances: 1 },
  async () => {
    const today = new Date();
    for (const offset of [0, 1]) {
      const date = new Date(today);
      date.setUTCDate(date.getUTCDate() + offset);
      const dayKey = date.toISOString().slice(0, 10);
      const seed = dailySeed(dayKey);
      const ref = db.collection('dailyChallenges').doc(dayKey);
      try {
        await ref.create({
          seed,
          gridSize: 6,
          difficulty: 'daily',
          schemaVersion: 1,
          createdAt: FieldValue.serverTimestamp(),
        });
        logger.info('daily_challenge_generated', { dayKey, seed });
      } catch (error) {
        const code = (error as { code?: number | string }).code;
        if (code === 6 || code === 'already-exists') continue;
        throw error;
      }
    }
  },
);

async function deleteUserIndexRows(uid: string): Promise<void> {
  const targets = [
    db.collectionGroup('entries').where('uid', '==', uid),
    db.collection('reports').where('uid', '==', uid),
    db.collection('functionRateLimits').where('uid', '==', uid),
  ];
  for (const query of targets) {
    const snapshot = await query.get();
    for (let offset = 0; offset < snapshot.docs.length; offset += 400) {
      const batch = db.batch();
      for (const document of snapshot.docs.slice(offset, offset + 400)) {
        batch.delete(document.ref);
      }
      await batch.commit();
    }
  }
}

function nowIso(): string {
  return new Date().toISOString();
}
