import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const [resultPath, scenario, workspace] = process.argv.slice(2);
if (!resultPath || !scenario || !workspace) {
  console.error('usage: node validate-routing-contract.mjs <result.json> <scenario> <workspace>');
  process.exit(2);
}

const expected = {
  'SCN-01': { gates: ['YES', 'YES', 'YES', 'YES'], decision: 'MULTI', expectedChangedFiles: [], allowedWriterScopes: [] },
  'SCN-02': {
    gates: ['NO', 'NO', 'YES', 'NO'],
    decision: 'MAIN',
    expectedChangedFiles: ['fixtures/api/handler.mjs'],
    allowedWriterScopes: []
  },
  'SCN-03': { gates: ['YES', 'YES', 'YES', 'YES'], decision: 'MULTI', expectedChangedFiles: [], allowedWriterScopes: [] },
  'SCN-04': {
    gates: ['YES', 'NO', 'YES', 'NO'],
    decision: 'MAIN',
    expectedChangedFiles: ['fixtures/shared/app.conf', 'fixtures/shared/migrations/V002__account_index.sql'],
    allowedWriterScopes: []
  },
  'SCN-05': {
    gates: ['YES', 'YES', 'YES', 'YES'],
    decision: 'MULTI',
    expectedChangedFiles: ['fixtures/module-a/module.mjs', 'fixtures/module-b/module.mjs'],
    allowedWriterScopes: ['fixtures/module-a/**', 'fixtures/module-b/**']
  }
};

if (!expected[scenario]) {
  console.error(`unknown scenario: ${scenario}`);
  process.exit(2);
}

const result = JSON.parse(readFileSync(resultPath, 'utf8'));
const target = expected[scenario];
const errors = {
  'EV-ROUTING-01': [],
  'EV-ROUTING-02': [],
  'EV-ROUTING-03': [],
  'EV-ROUTING-04': []
};

function check(evaluator, condition, message) {
  if (!condition) errors[evaluator].push(message);
}

function parseRelativePath(value, label, { allowSubtree = false } = {}) {
  if (typeof value !== 'string' || value.length === 0) {
    return { error: `${label} must be a non-empty string` };
  }
  if (value.includes('\\') || path.posix.isAbsolute(value) || path.win32.isAbsolute(value)) {
    return { error: `${label} must be a relative POSIX path: ${value}` };
  }

  const subtree = allowSubtree && value.endsWith('/**');
  const relativePath = subtree ? value.slice(0, -3) : value;
  if (/[*?[\]{}]/u.test(relativePath) || (!subtree && /[*?[\]{}]/u.test(value))) {
    return { error: `${label} uses an unsupported glob: ${value}` };
  }
  if (!relativePath || path.posix.normalize(relativePath) !== relativePath) {
    return { error: `${label} is not normalized: ${value}` };
  }

  const segments = relativePath.split('/');
  if (segments.some((segment) => segment === '' || segment === '.' || segment === '..')) {
    return { error: `${label} contains an invalid path segment: ${value}` };
  }

  return {
    raw: value,
    path: relativePath,
    segments,
    kind: subtree ? 'subtree' : 'exact'
  };
}

function isPathInsideWorkspace(relativePath) {
  const workspaceRoot = path.resolve(workspace);
  const resolvedPath = path.resolve(workspaceRoot, relativePath);
  return resolvedPath.startsWith(`${workspaceRoot}${path.sep}`);
}

function scopeContainsFile(scope, file) {
  if (scope.kind === 'exact') return scope.path === file.path;
  return file.segments.length > scope.segments.length
    && scope.segments.every((segment, index) => file.segments[index] === segment);
}

function scopesOverlap(left, right) {
  if (left.kind === 'exact' && right.kind === 'exact') return left.path === right.path;
  if (left.kind === 'subtree' && right.kind === 'exact') return scopeContainsFile(left, right);
  if (left.kind === 'exact' && right.kind === 'subtree') return scopeContainsFile(right, left);

  const sharedLength = Math.min(left.segments.length, right.segments.length);
  return left.segments.slice(0, sharedLength).every((segment, index) => segment === right.segments[index]);
}

function readActualChangedFiles() {
  const status = spawnSync('git', ['status', '--porcelain=v1', '-z', '--untracked-files=all'], {
    cwd: workspace,
    encoding: 'utf8'
  });
  check('EV-ROUTING-03', status.status === 0, `git status failed: ${status.stderr.trim()}`);
  if (status.status !== 0) return [];

  const entries = status.stdout.split('\0').filter(Boolean);
  const files = [];
  for (let index = 0; index < entries.length; index += 1) {
    const entry = entries[index];
    const statusCode = entry.slice(0, 2);
    files.push(entry.slice(3));
    if (statusCode.includes('R') || statusCode.includes('C')) index += 1;
  }
  return files.sort();
}

const actualGates = [result.gates.g1, result.gates.g2, result.gates.g3, result.gates.g4];
check('EV-ROUTING-01', result.scenario === scenario, `scenario=${result.scenario}; expected=${scenario}`);
check('EV-ROUTING-01', JSON.stringify(actualGates) === JSON.stringify(target.gates), `gates=${actualGates.join('/')}; expected=${target.gates.join('/')}`);
check('EV-ROUTING-01', result.routing_decision === target.decision, `routing_decision=${result.routing_decision}; expected=${target.decision}`);

if (result.routing_decision === 'MAIN') {
  check('EV-ROUTING-02', result.actual_execution === 'MAIN', `MAIN decision used actual_execution=${result.actual_execution}`);
  check('EV-ROUTING-02', result.fallback_reason === 'NONE', `MAIN decision used fallback_reason=${result.fallback_reason}`);
  check('EV-ROUTING-02', result.delegations.length === 0, 'MAIN execution delegated work');
} else if (result.actual_execution === 'MULTI') {
  check('EV-ROUTING-02', result.delegation_allowed === true, 'MULTI execution reported delegation_allowed=false');
  check('EV-ROUTING-02', result.assignments.length >= 2, 'MULTI execution has fewer than two assignments');
  check('EV-ROUTING-02', result.delegations.length >= 2, 'MULTI execution has fewer than two delegations');
  check('EV-ROUTING-02', result.fallback_reason === 'NONE', `MULTI execution used fallback_reason=${result.fallback_reason}`);
} else if (result.actual_execution === 'MAIN_FALLBACK') {
  check('EV-ROUTING-02', result.delegation_allowed === false, 'MAIN_FALLBACK reported delegation_allowed=true');
  check(
    'EV-ROUTING-02',
    ['DELEGATION_FORBIDDEN_BY_HIGHER_INSTRUCTION', 'DELEGATION_TOOL_UNAVAILABLE', 'CONCURRENCY_CAPACITY_UNAVAILABLE'].includes(result.fallback_reason),
    `invalid fallback_reason=${result.fallback_reason}`
  );
  check('EV-ROUTING-02', result.unverified.length > 0, 'MAIN_FALLBACK omitted unverified parallel effects');
} else {
  check('EV-ROUTING-02', false, `MULTI decision used actual_execution=${result.actual_execution}`);
}

const actualChangedFiles = readActualChangedFiles();
const claimedChangedFiles = [...result.changed_files].sort();
check('EV-ROUTING-03', result.writer_overlap === false, 'writer_overlap=true');
check('EV-ROUTING-03', JSON.stringify(claimedChangedFiles) === JSON.stringify(actualChangedFiles), `claimed changes=${claimedChangedFiles.join(',')}; actual=${actualChangedFiles.join(',')}`);
check(
  'EV-ROUTING-03',
  JSON.stringify(actualChangedFiles) === JSON.stringify([...target.expectedChangedFiles].sort()),
  `actual changes=${actualChangedFiles.join(',')}; expected=${target.expectedChangedFiles.join(',')}`
);

const parsedChangedFiles = actualChangedFiles.map((changedFile) => {
  const parsed = parseRelativePath(changedFile, 'actual changed file');
  check('EV-ROUTING-03', !parsed.error, parsed.error);
  if (!parsed.error) check('EV-ROUTING-03', isPathInsideWorkspace(parsed.path), `actual changed file escapes workspace: ${changedFile}`);
  return parsed.error ? null : parsed;
}).filter(Boolean);
for (const claimedChangedFile of claimedChangedFiles) {
  const parsed = parseRelativePath(claimedChangedFile, 'claimed changed file');
  check('EV-ROUTING-03', !parsed.error, parsed.error);
  if (!parsed.error) check('EV-ROUTING-03', isPathInsideWorkspace(parsed.path), `claimed changed file escapes workspace: ${claimedChangedFile}`);
}

const writerScopes = [];
for (let assignmentIndex = 0; assignmentIndex < result.assignments.length; assignmentIndex += 1) {
  const assignment = result.assignments[assignmentIndex];
  for (const writablePath of assignment.writable_paths) {
    const parsed = parseRelativePath(writablePath, 'writer scope', { allowSubtree: true });
    check('EV-ROUTING-03', !parsed.error, parsed.error);
    if (parsed.error) continue;
    check('EV-ROUTING-03', isPathInsideWorkspace(parsed.path), `writer scope escapes workspace: ${writablePath}`);
    writerScopes.push({ ...parsed, assignmentIndex, assignmentId: assignment.id });
  }
}

if (target.allowedWriterScopes.length > 0 && result.actual_execution === 'MULTI') {
  const actualScopes = writerScopes.map((scope) => scope.raw).sort();
  check(
    'EV-ROUTING-03',
    JSON.stringify(actualScopes) === JSON.stringify([...target.allowedWriterScopes].sort()),
    `writer scopes=${actualScopes.join(',')}; allowed=${target.allowedWriterScopes.join(',')}`
  );
}

for (let leftIndex = 0; leftIndex < writerScopes.length; leftIndex += 1) {
  for (let rightIndex = leftIndex + 1; rightIndex < writerScopes.length; rightIndex += 1) {
    const left = writerScopes[leftIndex];
    const right = writerScopes[rightIndex];
    if (left.assignmentIndex === right.assignmentIndex) continue;
    check(
      'EV-ROUTING-03',
      !scopesOverlap(left, right),
      `overlapping writer scopes: ${left.assignmentId}:${left.raw} and ${right.assignmentId}:${right.raw}`
    );
  }
}

if (result.actual_execution === 'MULTI') {
  for (const changedFile of parsedChangedFiles) {
    const owningWriters = new Set(
      writerScopes.filter((scope) => scopeContainsFile(scope, changedFile)).map((scope) => scope.assignmentIndex)
    );
    check(
      'EV-ROUTING-03',
      owningWriters.size === 1,
      `changed file must have exactly one writer: ${changedFile.path}; writers=${owningWriters.size}`
    );
  }
}
if (result.actual_execution === 'MAIN_FALLBACK') {
  check('EV-ROUTING-03', result.assignments.length === 0, 'MAIN_FALLBACK must not report agent assignments');
}

const validation = spawnSync('./evaluation/validate-scenario.sh', [scenario], {
  cwd: workspace,
  encoding: 'utf8'
});
check('EV-ROUTING-04', validation.status === 0, `independent integration validation failed: ${(validation.stderr || validation.stdout).trim()}`);
check('EV-ROUTING-04', result.integration_evaluator === 'PASS', `integration_evaluator=${result.integration_evaluator}`);
check('EV-ROUTING-04', result.integration_command === `./evaluation/validate-scenario.sh ${scenario}`, `integration_command=${result.integration_command}`);
if (result.actual_execution === 'MULTI') {
  check('EV-ROUTING-04', result.delegations.length >= 2, 'MULTI results do not include two delegation returns');
  check('EV-ROUTING-04', result.delegations.every((item) => item.result_adopted), 'delegation adoption decision missing');
}

const checks = Object.fromEntries(
  Object.entries(errors).map(([evaluator, evaluatorErrors]) => [
    evaluator,
    {
      result: evaluatorErrors.length === 0 ? 'PASS' : 'FAIL',
      evidence: evaluatorErrors.length === 0 ? 'contract satisfied' : evaluatorErrors.join('; ')
    }
  ])
);
const finalResult = Object.values(checks).every((item) => item.result === 'PASS') ? 'PASS' : 'FAIL';

console.log(JSON.stringify({ scenario, final_result: finalResult, checks }, null, 2));
process.exit(finalResult === 'PASS' ? 0 : 1);
