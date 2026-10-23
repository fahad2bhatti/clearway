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

test('a user can create their own valid progress document', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 12,
    stars: { '1': 3, '12': 2 },
    schemaVersion: 1,
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

test('progress rules reject out-of-range stars and levels', async () => {
  const db = environment.authenticatedContext('player-a').firestore();
  await assertFails(setDoc(doc(db, 'users/player-a/progress/state'), {
    highestLevel: 81,
    stars: { '1': 5 },
    schemaVersion: 1,
    updatedAt: serverTimestamp(),
  }));
});
