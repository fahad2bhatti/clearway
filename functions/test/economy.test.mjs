import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  boundedAmount,
  economyItem,
  requestId,
  safeBalance,
} from '../lib/economy.js';

test('economy catalog rejects unknown items', () => {
  assert.equal(economyItem('hint-pack').cost, 50);
  assert.throws(() => economyItem('free-coins'), /invalid-item/);
});

test('economy validation rejects forged amounts and balances', () => {
  assert.equal(boundedAmount(100), 100);
  assert.throws(() => boundedAmount(0), /invalid-amount/);
  assert.throws(() => boundedAmount(1001), /invalid-amount/);
  assert.equal(safeBalance(undefined), 0);
  assert.throws(() => safeBalance(-1), /invalid-balance/);
  assert.throws(() => safeBalance(1.5), /invalid-balance/);
});

test('idempotency keys are bounded and non-empty', () => {
  assert.equal(requestId('purchase:abc123'), 'purchase:abc123');
  assert.throws(() => requestId('x'), /invalid-request-id/);
  assert.throws(() => requestId('not safe!'), /invalid-request-id/);
});
