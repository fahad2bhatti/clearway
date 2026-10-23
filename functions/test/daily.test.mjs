import assert from 'node:assert/strict';
import { test } from 'node:test';

import { dailySeed } from '../lib/daily.js';

test('dailySeed matches the shared Dart and TypeScript vectors', () => {
  assert.equal(dailySeed('2026-10-24'), 4006804975);
  assert.equal(dailySeed('2026-01-01'), 4082560732);
  assert.equal(dailySeed('2027-02-28'), 1737354936);
});
