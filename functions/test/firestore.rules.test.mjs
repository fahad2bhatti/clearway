import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
} from 'firebase/firestore';

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-clearway-rules',
    firestore: {
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

test('a user can create progress using the compact stars format', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 12,
    starsCode: '300000000002',
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
});

test('a user cannot read another account progress', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(getDoc(doc(db, 'users/player-b/progress/state')));
});

test('client cannot write coin balances on the user profile', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-a'), { coins: 999999 }));
});

test('client cannot create ledger or purchase records', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-a/ledger/fake'), {
    type: 'earn', amount: 50000, reason: 'fake', schemaVersion: 1,
  }));
  await assertFails(setDoc(doc(db, 'users/player-a/purchases/fake'), {
    productId: 'remove_ads', state: 'verified', schemaVersion: 1,
  }));
});

test('progress rejects invalid star characters and excessive data', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 12,
    starsCode: '30x2',
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 1001,
    starsCode: '0',
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 1,
    starsCode: '0'.repeat(1001),
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
});

test('progress rejects the legacy map format and unexpected fields', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  const ref = doc(db, 'users/player-a/progress/state');
  await assertFails(setDoc(ref, {
    highestLevel: 12,
    stars: { '1': 3 },
    schemaVersion: 1,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(ref, {
    highestLevel: 12,
    starsCode: '3',
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
    coins: 999,
  }));
});

test('a user cannot write another account progress document', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-b/progress/state'), {
    highestLevel: 12,
    starsCode: '300000000002',
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
});

test('progress updates cannot lower the level or shorten starsCode', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  const ref = doc(db, 'users/player-a/progress/state');
  await assertSucceeds(setDoc(ref, {
    highestLevel: 50,
    starsCode: '3'.repeat(50),
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(ref, {
    highestLevel: 49,
    starsCode: '3'.repeat(50),
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(ref, {
    highestLevel: 50,
    starsCode: '3'.repeat(49),
    schemaVersion: 2,
    updatedAt: serverTimestamp(),
  }));
});

const validProgress = (overrides = {}) => ({
  highestLevel: 5,
  starsCode: '33333',
  schemaVersion: 2,
  updatedAt: serverTimestamp(),
  ...overrides,
});

const validReport = (overrides = {}) => ({
  uid: 'player-a',
  type: 'bug',
  text: 'The yard froze on level 12.',
  appVersion: '1.0.0',
  device: 'Pixel 7',
  ...overrides,
});

test('signed-out clients can neither read nor write anything', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/player-a/progress/state')));
  await assertFails(setDoc(doc(db, 'users/player-a/progress/state'), validProgress()));
  await assertFails(getDoc(doc(db, 'dailyChallenges/2026-10-24')));
  await assertFails(setDoc(doc(db, 'reports/r1'), validReport()));
});

test('progress rejects a client-supplied timestamp, floats and strings', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  const ref = doc(db, 'users/player-a/progress/state');
  await assertFails(setDoc(ref, validProgress({
    updatedAt: Timestamp.fromMillis(Date.now() - 86_400_000),
  })));
  await assertFails(setDoc(ref, validProgress({ highestLevel: 12.5 })));
  await assertFails(setDoc(ref, validProgress({ highestLevel: '12' })));
  await assertFails(setDoc(ref, validProgress({ highestLevel: 0 })));
  await assertFails(setDoc(ref, validProgress({ schemaVersion: 1 })));
});

test('progress only lives at progress/state and can never be deleted', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-a/progress/other'), validProgress()));
  const ref = doc(db, 'users/player-a/progress/state');
  await assertSucceeds(setDoc(ref, validProgress()));
  await assertFails(deleteDoc(ref));
});

test('users collection cannot be listed or written, own profile is readable', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(deleteDoc(doc(db, 'users/player-a')));
  await assertSucceeds(getDoc(doc(db, 'users/player-a')));
  await assertFails(getDoc(doc(db, 'users/player-b')));
});

test('daily challenges are readable when signed in but never writable', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'dailyChallenges/2026-10-24'), { seed: 7 });
  });
  const db = environment.authenticatedContext('player-a').firestore();
  await assertSucceeds(getDoc(doc(db, 'dailyChallenges/2026-10-24')));
  await assertFails(setDoc(doc(db, 'dailyChallenges/2026-10-25'), { seed: 1 }));
  await assertFails(setDoc(doc(db, 'dailyChallenges/2026-10-24'), { seed: 1 }));
});

test('leaderboards and public config are server-only writes', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'leaderboards/2026-W43/entries/player-a'), {
    uid: 'player-a', score: 999999,
  }));
  await assertFails(setDoc(doc(db, 'config/public'), { dailyRewardCoins: 500 }));
  await assertFails(setDoc(doc(db, 'users/player-a/daily/2026-10-24'), { completed: true }));
});

test('reports accept a well-formed message and nothing else', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertSucceeds(setDoc(doc(db, 'reports/ok'), validReport()));
  await assertFails(getDoc(doc(db, 'reports/ok')));
  await assertFails(setDoc(doc(db, 'reports/spoof'), validReport({ uid: 'player-b' })));
  await assertFails(setDoc(doc(db, 'reports/long'), validReport({ text: 'x'.repeat(2001) })));
  await assertFails(setDoc(doc(db, 'reports/extra'), validReport({ admin: true })));
  await assertFails(setDoc(doc(db, 'reports/bad-type'), validReport({ type: 5 })));
  await assertFails(deleteDoc(doc(db, 'reports/ok')));
});
