import assert from 'node:assert/strict';
import test from 'node:test';

import { retryDelay } from './module.mjs';

test('uses exponential retry delay', () => {
  assert.equal(retryDelay(1), 100);
  assert.equal(retryDelay(2), 200);
  assert.equal(retryDelay(3), 400);
});
