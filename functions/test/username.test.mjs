import assert from 'node:assert/strict';
import { test } from 'node:test';

import { normalizeUsername, RESERVED_USERNAMES } from '../lib/username.js';

test('valid usernames keep their casing and get a lowercase key', () => {
  const name = normalizeUsername('Fahad_1');
  assert.equal(name.display, 'Fahad_1');
  assert.equal(name.key, 'fahad_1');
});

test('usernames that differ only by case share one key', () => {
  assert.equal(normalizeUsername('Abc').key, normalizeUsername('aBC').key);
});

test('invalid usernames are rejected', () => {
  for (const value of ['ab', 'a'.repeat(16), 'a b', 'ab!', 'user-1', 'abc\n', '', 42, null, undefined]) {
    assert.throws(() => normalizeUsername(value), /invalid-username/, String(value));
  }
});

test('reserved names are listed in lowercase', () => {
  assert.ok(RESERVED_USERNAMES.has('admin'));
  assert.ok(RESERVED_USERNAMES.has('clearway'));
  for (const name of RESERVED_USERNAMES) assert.equal(name, name.toLowerCase());
});
