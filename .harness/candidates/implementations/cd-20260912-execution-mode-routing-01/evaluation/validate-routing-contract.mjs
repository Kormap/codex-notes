import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const [resultPath, scenario, workspace] = process.argv.slice(2);
if (!resultPath || !scenario || !workspace) {
  console.error('usage: node validate-routing-contract.mjs <result.json> <scenario> <workspace>');
  process.exit(2);
}

const expected = {
  'SCN-01': { gates: ['YES', 'YES', 'YES', 'YES'], decision: 'MULTI', writable: [] },
  'SCN-02': { gates: ['NO', 'NO', 'YES', 'NO'], decision: 'MAIN', writable: ['fixtures/api/handler.mjs'] },
  'SCN-03': { gates: ['YES', 'YES', 'YES', 'YES'], decision: 'MULTI', writable: [] },
  'SCN-04': { gates: ['YES', 'NO', 'YES', 'NO'], decision: 'MAIN', writable: ['fixtures/shared/app.conf', 'fixtures/shared/migrations/V002__account_index.sql'] },
  'SCN-05': { gates: ['YES', 'YES', 'YES', 'YES'], decision: 'MULTI', writable: ['fixtures/module-a/module.mjs', 'fixtures/module-b/module.mjs'] }
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

const status = spawnSync('git', ['status', '--porcelain'], { cwd: workspace, encoding: 'utf8' });
check('EV-ROUTING-03', status.status === 0, `git status failed: ${status.stderr.trim()}`);
const actualChangedFiles = status.stdout
  .split('\n')
  .filter(Boolean)
  .map((line) => line.slice(3))
  .sort();
const claimedChangedFiles = [...result.changed_files].sort();
check('EV-ROUTING-03', result.writer_overlap === false, 'writer_overlap=true');
check('EV-ROUTING-03', JSON.stringify(claimedChangedFiles) === JSON.stringify(actualChangedFiles), `claimed changes=${claimedChangedFiles.join(',')}; actual=${actualChangedFiles.join(',')}`);
check('EV-ROUTING-03', JSON.stringify(actualChangedFiles) === JSON.stringify([...target.writable].sort()), `actual changes=${actualChangedFiles.join(',')}; allowed=${target.writable.join(',')}`);
for (const assignment of result.assignments) {
  for (const writablePath of assignment.writable_paths) {
    check('EV-ROUTING-03', !writablePath.startsWith('/'), `absolute writable path assigned: ${writablePath}`);
    check('EV-ROUTING-03', target.writable.includes(writablePath), `out-of-scope writable path assigned: ${writablePath}`);
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
