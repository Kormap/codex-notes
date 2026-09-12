import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeUsername } from './module.mjs';

test('normalizes surrounding whitespace and case', () => {
  assert.equal(normalizeUsername('  Alice  '), 'alice');
});
