'use strict';

const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

function usage() {
  console.error('Usage: node k6_tests/generate-xlsx-report.js <summary-json-path>');
  process.exit(1);
}

const summaryPath = process.argv[2];
if (!summaryPath) {
  usage();
}

const absoluteSummaryPath = path.resolve(summaryPath);
if (!fs.existsSync(absoluteSummaryPath)) {
  console.error(`Summary JSON not found: ${absoluteSummaryPath}`);
  process.exit(1);
}

const summary = JSON.parse(fs.readFileSync(absoluteSummaryPath, 'utf8'));
const metrics = summary.metrics || {};

// Make sure output goes to k6_tests/results/load-test-report.xlsx
const resultsDir = path.join(__dirname, 'results');
if (!fs.existsSync(resultsDir)) {
  fs.mkdirSync(resultsDir, { recursive: true });
}
const workbookPath = path.join(resultsDir, 'load-test-report.xlsx');

function metricValues(name) {
  if (!metrics[name]) return {};
  if (metrics[name].values) return metrics[name].values;
  return metrics[name];
}

function thresholdState(name) {
  const thresholds = metrics[name] && metrics[name].thresholds;
  if (!thresholds) return '';
  return Object.entries(thresholds)
    .map(([threshold, state]) => {
      const crossed = typeof state === 'boolean' ? state : !state.ok;
      return `${threshold}: ${crossed ? 'FAIL' : 'PASS'}`;
    })
    .join('; ');
}

const httpReqs = metricValues('http_reqs');
const httpReqDuration = metricValues('http_req_duration');
const checks = metricValues('checks') || { rate: 0 };
const failedRate = metricValues('http_req_failed') || { rate: 0 };
const vusMax = metricValues('vus_max') || { max: 0 };
const vus = metricValues('vus') || { value: 0 };
const runDurationMs = summary.state && summary.state.testRunDurationMs ? summary.state.testRunDurationMs : 0;

const dashboardRows = [
  ['ACE TECHNOLOGIES - K6 LOAD TEST REPORT'],
  [],
  ['Scenario', 'Load Testing'],
  ['Virtual Users (Max)', vusMax.max || vus.max || vus.value || 0],
  ['Configured Duration', `${Math.round(runDurationMs / 1000)} seconds`],
  ['Total Requests', httpReqs.count || 0],
  ['Requests Per Second (RPS)', Number(httpReqs.rate || 0).toFixed(2)],
  ['Check Pass Rate', `${((checks.rate || 0) * 100).toFixed(2)}%`],
  ['Failure Rate', `${((failedRate.rate || 0) * 100).toFixed(2)}%`],
  [],
  ['HTTP Response Time', 'Milliseconds'],
  ['Average', Number(httpReqDuration.avg || 0).toFixed(2)],
  ['Minimum', Number(httpReqDuration.min || 0).toFixed(2)],
  ['Median', Number(httpReqDuration.med || 0).toFixed(2)],
  ['Maximum', Number(httpReqDuration.max || 0).toFixed(2)],
  ['P90', Number(httpReqDuration['p(90)'] || 0).toFixed(2)],
  ['P95', Number(httpReqDuration['p(95)'] || 0).toFixed(2)],
  [],
  ['Threshold Summary', thresholdState('http_req_duration')],
  ['Current VUs', vus.value || 0],
];

const endpointMetricNames = [
  ['Products API', 'products_response_time'],
  ['Services API', 'services_response_time'],
  ['Categories API', 'categories_response_time'],
  ['Reviews API', 'reviews_response_time'],
];

const endpointRows = endpointMetricNames.map(([label, metricName]) => {
  const values = metricValues(metricName);
  return {
    Endpoint: label,
    'Average (ms)': Number(values.avg || 0).toFixed(2),
    'Minimum (ms)': Number(values.min || 0).toFixed(2),
    'Median (ms)': Number(values.med || 0).toFixed(2),
    'Maximum (ms)': Number(values.max || 0).toFixed(2),
    'P90 (ms)': Number(values['p(90)'] || 0).toFixed(2),
    'P95 (ms)': Number(values['p(95)'] || 0).toFixed(2),
    Thresholds: thresholdState(metricName),
  };
}).filter(row => row['Average (ms)'] !== '0.00' || row['Maximum (ms)'] !== '0.00');

function flattenChecks(group, acc = []) {
  if (!group) return acc;
  for (const check of Object.values(group.checks || {})) {
    const total = (check.passes || 0) + (check.fails || 0);
    acc.push({
      Group: group.name || 'root',
      Check: check.name,
      Passes: check.passes || 0,
      Fails: check.fails || 0,
      'Pass Rate': total ? `${(((check.passes || 0) / total) * 100).toFixed(2)}%` : '0.00%',
    });
  }
  for (const child of Object.values(group.groups || {})) {
    flattenChecks(child, acc);
  }
  return acc;
}

const checkRows = flattenChecks(summary.root_group);

const rawMetricRows = Object.entries(metrics).map(([name, metric]) => {
  const values = metric.values || {};
  return {
    Metric: name,
    Type: metric.type || '',
    Count: values.count ?? '',
    Rate: values.rate ?? '',
    Avg: values.avg ?? '',
    Min: values.min ?? '',
    Med: values.med ?? '',
    Max: values.max ?? '',
    P90: values['p(90)'] ?? '',
    P95: values['p(95)'] ?? '',
    Thresholds: thresholdState(name),
  };
});

const wb = XLSX.utils.book_new();

const dashboardSheet = XLSX.utils.aoa_to_sheet(dashboardRows);
dashboardSheet['!cols'] = [{ wch: 32 }, { wch: 28 }];
dashboardSheet['!merges'] = [{ s: { r: 0, c: 0 }, e: { r: 0, c: 1 } }];
XLSX.utils.book_append_sheet(wb, dashboardSheet, 'Dashboard');

const endpointSheet = XLSX.utils.json_to_sheet(endpointRows);
endpointSheet['!cols'] = [
  { wch: 20 }, { wch: 14 }, { wch: 14 }, { wch: 14 },
  { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 24 },
];
XLSX.utils.book_append_sheet(wb, endpointSheet, 'Endpoint Metrics');

const checksSheet = XLSX.utils.json_to_sheet(checkRows);
checksSheet['!cols'] = [{ wch: 18 }, { wch: 44 }, { wch: 10 }, { wch: 10 }, { wch: 12 }];
XLSX.utils.book_append_sheet(wb, checksSheet, 'Checks');

const rawSheet = XLSX.utils.json_to_sheet(rawMetricRows);
rawSheet['!cols'] = [
  { wch: 32 }, { wch: 10 }, { wch: 14 }, { wch: 14 }, { wch: 14 },
  { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 24 },
];
XLSX.utils.book_append_sheet(wb, rawSheet, 'Raw Metrics');

XLSX.writeFile(wb, workbookPath);
console.log(workbookPath);
