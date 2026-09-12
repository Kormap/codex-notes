import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const config = readFileSync(new URL('./app.conf', import.meta.url), 'utf8').trim();
const migration = readFileSync(new URL('./migrations/V002__account_index.sql', import.meta.url), 'utf8');

assert.equal(config, 'schema_version=2');
assert.match(migration, /^-- schema-version: 2$/m);
