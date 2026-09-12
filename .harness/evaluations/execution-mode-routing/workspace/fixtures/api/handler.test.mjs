import assert from 'node:assert/strict';
import test from 'node:test';

import { responseStatus } from './handler.mjs';

test('maps an unexpected API failure to 500', () => {
  assert.equal(responseStatus(new Error('database unavailable')), 500);
});

test('preserves success and not-found behavior', () => {
  assert.equal(responseStatus(null), 200);
  assert.equal(responseStatus({ code: 'NOT_FOUND' }), 404);
});
