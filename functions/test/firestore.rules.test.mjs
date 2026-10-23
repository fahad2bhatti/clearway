import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';

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
