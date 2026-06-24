const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

const inputPath = path.join(__dirname, 'discovered_endpoints.json');
const outputPath = path.join(__dirname, 'dast_report.xlsx');

if (!fs.existsSync(inputPath)) {
  throw new Error(`Missing input file: ${inputPath}`);
}

const raw = fs.readFileSync(inputPath, 'utf8').replace(/^\uFEFF/, '');
const discovery = JSON.parse(raw);

const endpoints = Array.isArray(discovery.endpoints) ? discovery.endpoints : [];
const probes = Array.isArray(discovery.specProbeResults)
  ? discovery.specProbeResults
  : [];

const methodCounts = endpoints.reduce((acc, endpoint) => {
  const method = endpoint.method || 'UNKNOWN';
  acc[method] = (acc[method] || 0) + 1;
  return acc;
}, {});

const authCounts = endpoints.reduce(
  (acc, endpoint) => {
    const access = String(endpoint.access || '').toLowerCase();
    if (access.includes('public')) acc.public += 1;
    else if (access.includes('admin-only')) acc.adminOnly += 1;
    else if (access.includes('requires-auth')) acc.requiresAuth += 1;
    else acc.other += 1;
    return acc;
  },
  { public: 0, requiresAuth: 0, adminOnly: 0, other: 0 },
);

const summaryRows = [
  ['DAST Report', 'Discovery Status'],
  ['Base URL', discovery.baseUrl || ''],
  ['Generated At (UTC)', discovery.generatedAt || ''],
  ['Report Type', 'Endpoint discovery and test readiness'],
  ['Discovery Success', 'Yes'],
  ['Total Endpoints', endpoints.length],
  ['GET Endpoints', methodCounts.GET || 0],
  ['POST Endpoints', methodCounts.POST || 0],
  ['Public Endpoints', authCounts.public],
  ['Requires Auth Endpoints', authCounts.requiresAuth],
  ['Admin-only Endpoints', authCounts.adminOnly],
  ['Other/Unclassified', authCounts.other],
  ['Spec Probe Reachable Count', probes.filter((p) => p.reachable).length],
  ['Findings Executed', 0],
  ['Current Status', 'Discovery complete; active DAST probes not executed yet'],
];

const endpointRows = endpoints.map((endpoint, index) => ({
  id: index + 1,
  method: endpoint.method || '',
  path: endpoint.path || '',
  expected_access: endpoint.access || '',
  category: endpoint.path && endpoint.path.includes('/functions/v1/')
    ? 'Edge Function'
    : endpoint.path && endpoint.path.includes('/rpc/')
      ? 'RPC'
      : 'PostgREST',
  test_status: 'Not run',
  finding: 'Pending',
  note: 'Discovered from codebase and safe host probes',
}));

const probeRows = probes.map((probe, index) => ({
  id: index + 1,
  url: probe.url || '',
  reachable: probe.reachable ? 'Yes' : 'No',
  status: probe.status == null ? '' : probe.status,
  note: probe.note || '',
}));

const plannedTests = [
  'AuthN bypass',
  'AuthZ / privilege escalation',
  'IDOR',
  'RBAC matrix',
  'Token tampering',
  'Injection probe',
  'Rate limiting',
  'Hardcoded credential scan',
].map((name, index) => ({
  id: index + 1,
  test_category: name,
  status: 'Not run',
  note: 'Workbook created from discovery stage only',
}));

const wb = XLSX.utils.book_new();

const summarySheet = XLSX.utils.aoa_to_sheet(summaryRows);
summarySheet['!cols'] = [{ wch: 28 }, { wch: 80 }];

const endpointsSheet = XLSX.utils.json_to_sheet(endpointRows);
endpointsSheet['!cols'] = [
  { wch: 6 },
  { wch: 10 },
  { wch: 70 },
  { wch: 55 },
  { wch: 14 },
  { wch: 12 },
  { wch: 12 },
  { wch: 42 },
];

const probesSheet = XLSX.utils.json_to_sheet(probeRows);
probesSheet['!cols'] = [
  { wch: 6 },
  { wch: 65 },
  { wch: 10 },
  { wch: 10 },
  { wch: 80 },
];

const testsSheet = XLSX.utils.json_to_sheet(plannedTests);
testsSheet['!cols'] = [
  { wch: 6 },
  { wch: 32 },
  { wch: 12 },
  { wch: 45 },
];

XLSX.utils.book_append_sheet(wb, summarySheet, 'Summary');
XLSX.utils.book_append_sheet(wb, endpointsSheet, 'Endpoints');
XLSX.utils.book_append_sheet(wb, probesSheet, 'Spec Probes');
XLSX.utils.book_append_sheet(wb, testsSheet, 'Test Matrix');

XLSX.writeFile(wb, outputPath);

console.log(
  JSON.stringify(
    {
      success: true,
      outputPath,
      sheetNames: wb.SheetNames,
      endpointCount: endpoints.length,
      probeCount: probes.length,
    },
    null,
    2,
  ),
);
