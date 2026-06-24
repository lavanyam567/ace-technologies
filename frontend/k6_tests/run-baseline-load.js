'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function loadEnvFile(envPath) {
  if (!envPath || !fs.existsSync(envPath)) {
    return {};
  }
  return JSON.parse(fs.readFileSync(envPath, 'utf8'));
}

const projectRoot = path.resolve(__dirname, '..');
const resultsDir = path.resolve(__dirname, 'results');
fs.mkdirSync(resultsDir, { recursive: true });

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const summaryPath = path.join(resultsDir, `baseline_summary_${timestamp}.json`);
const envFilePath = process.env.K6_ENV_FILE
  ? path.resolve(projectRoot, process.env.K6_ENV_FILE)
  : path.resolve(projectRoot, 'env.production.json');
const envFromFile = loadEnvFile(envFilePath);

const k6Binary = process.env.K6_BIN ||
  (process.platform === 'win32'
    ? path.resolve(__dirname, 'k6_bin', 'k6-v2.0.0-windows-amd64', 'k6.exe')
    : 'k6');

const env = {
  ...process.env,
  ...envFromFile,
  BASELINE_VUS: process.env.BASELINE_VUS || '100',
  BASELINE_DURATION: process.env.BASELINE_DURATION || '1m',
  K6_SLEEP_SECONDS: process.env.K6_SLEEP_SECONDS || '0.2',
};

const runArgs = [
  'run',
  '--summary-export',
  summaryPath,
  path.resolve(__dirname, 'baseline-load.js'),
];

const run = spawnSync(k6Binary, runArgs, {
  cwd: projectRoot,
  env,
  stdio: 'inherit',
});

const report = spawnSync(process.execPath, [path.resolve(__dirname, 'generate-xlsx-report.js'), summaryPath], {
  cwd: projectRoot,
  stdio: 'inherit',
});

if (report.status !== 0) {
  process.exit(report.status || 1);
}

if (run.status !== 0) {
  process.exit(run.status || 1);
}
