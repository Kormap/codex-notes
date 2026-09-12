import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';

const defaultValidator = path.resolve(path.dirname(new URL(import.meta.url).pathname), 'validate-routing-contract.mjs');
const validator = process.argv[2] ? path.resolve(process.argv[2]) : defaultValidator;
const selectedCase = process.argv[3];
const cases = [
  {
    name: 'valid-subtree-assignments',
    scopes: [['fixtures/module-a/**'], ['fixtures/module-b/**']],
    expectedExit: 0
  },
  {
    name: 'out-of-scope-assignment',
    scopes: [['fixtures/module-a/**'], ['fixtures/shared/**']],
    expectedExit: 1,
    expectedEvidence: 'writer scopes='
  },
  {
    name: 'parent-traversal-assignment',
    scopes: [['fixtures/module-a/**'], ['../module-b/**']],
    expectedExit: 1,
    expectedEvidence: 'invalid path segment'
  },
  {
    name: 'out-of-scope-changed-file',
    scopes: [['fixtures/module-a/**'], ['fixtures/module-b/**']],
    extraChangedFile: 'fixtures/shared/outside.mjs',
    expectedExit: 1,
    expectedEvidence: 'actual changes='
  },
  {
    name: 'overlapping-subtrees-ignore-self-report',
    scopes: [['fixtures/module-a/**'], ['fixtures/module-a/nested/**']],
    expectedExit: 1,
    expectedEvidence: 'overlapping writer scopes'
  },
  {
    name: 'similar-prefix-is-not-overlap',
    scopes: [['fixtures/module-a/**'], ['fixtures/module-ab/**']],
    expectedExit: 1,
    expectedEvidence: 'writer scopes=',
    forbiddenEvidence: 'overlapping writer scopes'
  },
  {
    name: 'duplicate-exact-ignore-self-report',
    scopes: [['fixtures/module-a/module.mjs'], ['fixtures/module-a/module.mjs']],
    expectedExit: 1,
    expectedEvidence: 'overlapping writer scopes'
  },
  {
    name: 'absolute-assignment',
    scopes: [['/fixtures/module-a/**'], ['fixtures/module-b/**']],
    expectedExit: 1,
    expectedEvidence: 'relative POSIX path'
  },
  {
    name: 'non-normal-assignment',
    scopes: [['fixtures/./module-a/**'], ['fixtures/module-b/**']],
    expectedExit: 1,
    expectedEvidence: 'not normalized'
  },
  {
    name: 'unsupported-glob-assignment',
    scopes: [['fixtures/module-a/*.mjs'], ['fixtures/module-b/**']],
    expectedExit: 1,
    expectedEvidence: 'unsupported glob'
  }
].filter((testCase) => !selectedCase || testCase.name === selectedCase);

if (selectedCase && cases.length === 0) {
  console.error(`unknown fixture case: ${selectedCase}`);
  process.exit(2);
}

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`${command} ${args.join(' ')} failed: ${result.stderr || result.stdout}`);
}

function createWorkspace(testCase) {
  const workspace = mkdtempSync(path.join(tmpdir(), 'routing-validator-'));
  mkdirSync(path.join(workspace, 'fixtures/module-a'), { recursive: true });
  mkdirSync(path.join(workspace, 'fixtures/module-b'), { recursive: true });
  mkdirSync(path.join(workspace, 'evaluation'), { recursive: true });
  writeFileSync(path.join(workspace, 'fixtures/module-a/module.mjs'), 'export const value = 0;\n');
  writeFileSync(path.join(workspace, 'fixtures/module-b/module.mjs'), 'export const value = 0;\n');
  writeFileSync(path.join(workspace, 'evaluation/validate-scenario.sh'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
  run('git', ['init', '-q'], workspace);
  run('git', ['config', 'user.name', 'Harness Fixture'], workspace);
  run('git', ['config', 'user.email', 'harness-fixture@example.invalid'], workspace);
  run('git', ['add', '.'], workspace);
  run('git', ['-c', 'commit.gpgsign=false', 'commit', '-q', '-m', 'validator fixture'], workspace);
  writeFileSync(path.join(workspace, 'fixtures/module-a/module.mjs'), 'export const value = 1;\n');
  writeFileSync(path.join(workspace, 'fixtures/module-b/module.mjs'), 'export const value = 1;\n');
  if (testCase.extraChangedFile) {
    mkdirSync(path.dirname(path.join(workspace, testCase.extraChangedFile)), { recursive: true });
    writeFileSync(path.join(workspace, testCase.extraChangedFile), 'export const outside = true;\n');
  }
  return workspace;
}

function createResult(testCase, workspace) {
  const changedFiles = ['fixtures/module-a/module.mjs', 'fixtures/module-b/module.mjs'];
  if (testCase.extraChangedFile) changedFiles.push(testCase.extraChangedFile);
  const result = {
    scenario: 'SCN-05',
    gates: { g1: 'YES', g2: 'YES', g3: 'YES', g4: 'YES' },
    gate_reasons: { g1: 'independent', g2: 'separate', g3: 'fixed', g4: 'beneficial' },
    routing_decision: 'MULTI',
    delegation_allowed: true,
    actual_execution: 'MULTI',
    fallback_reason: 'NONE',
    assignments: testCase.scopes.map((writablePaths, index) => ({
      id: `writer-${index + 1}`,
      role: 'Implementer',
      scope: `module ${index + 1}`,
      writable_paths: writablePaths
    })),
    delegations: [
      { to: 'writer-1', result_adopted: 'ADOPTED', evidence: 'focused test passed' },
      { to: 'writer-2', result_adopted: 'ADOPTED', evidence: 'focused test passed' }
    ],
    adopted_results: ['writer-1', 'writer-2'],
    rejected_results: [],
    writer_overlap: false,
    changed_files: changedFiles,
    integration_evaluator: 'PASS',
    integration_command: './evaluation/validate-scenario.sh SCN-05',
    rework_count: 0,
    unverified: [],
    remaining_risks: [],
    evidence_summary: 'controlled validator regression fixture'
  };
  const resultPath = path.join(workspace, '.git', 'routing-result.json');
  writeFileSync(resultPath, `${JSON.stringify(result, null, 2)}\n`);
  return resultPath;
}

let failures = 0;
for (const testCase of cases) {
  const workspace = createWorkspace(testCase);
  try {
    const resultPath = createResult(testCase, workspace);
    const validation = spawnSync(process.execPath, [validator, resultPath, 'SCN-05', workspace], { encoding: 'utf8' });
    const output = `${validation.stdout}\n${validation.stderr}`;
    const exitMatches = validation.status === testCase.expectedExit;
    const evidenceMatches = !testCase.expectedEvidence || output.includes(testCase.expectedEvidence);
    const forbiddenEvidenceAbsent = !testCase.forbiddenEvidence || !output.includes(testCase.forbiddenEvidence);
    const passed = exitMatches && evidenceMatches && forbiddenEvidenceAbsent;
    console.log(`${passed ? 'PASS' : 'FAIL'} ${testCase.name} expected_exit=${testCase.expectedExit} actual_exit=${validation.status}`);
    if (!passed) {
      failures += 1;
      console.error(output.trim());
    }
  } finally {
    rmSync(workspace, { recursive: true, force: true });
  }
}

process.exit(failures === 0 ? 0 : 1);
