const fs = require('fs');
const path = require('path');

function generateHtmlReport(results, typeStats) {
  const total = results.length;
  const passed = results.filter(r => r.Status === 'PASS').length;
  const failed = results.filter(r => r.Status === 'FAIL').length;
  const passRate = ((passed / total) * 100).toFixed(2);

  let html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Mega Web E2E Test Execution Report</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #1e1e2f; color: #fff; margin: 0; padding: 20px; }
    h1 { text-align: center; color: #4ade80; margin-bottom: 5px; }
    h2 { border-bottom: 2px solid #3b3b54; padding-bottom: 10px; margin-top: 30px; }
    .badges { display: flex; justify-content: center; gap: 15px; margin-bottom: 30px; }
    .badge { padding: 10px 20px; border-radius: 8px; font-weight: bold; font-size: 1.1em; }
    .badge.total { background-color: #3b82f6; }
    .badge.passed { background-color: #22c55e; }
    .badge.failed { background-color: #ef4444; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 30px; background-color: #2a2a40; border-radius: 8px; overflow: hidden; }
    th, td { padding: 12px 15px; text-align: left; }
    th { background-color: #3b3b54; font-weight: bold; }
    tr:nth-child(even) { background-color: #32324e; }
    tr:hover { background-color: #3f3f5a; }
    .status-pass { color: #4ade80; font-weight: bold; }
    .status-fail { color: #f87171; font-weight: bold; }
  </style>
</head>
<body>
  <h1>ACE Technologies E2E Test Report</h1>
  
  <div class="badges">
    <div class="badge total">Total: ${total}</div>
    <div class="badge passed">Passed: ${passed}</div>
    <div class="badge failed">Failed: ${failed}</div>
    <div class="badge ${passRate === '100.00' ? 'passed' : 'failed'}">Pass Rate: ${passRate}%</div>
  </div>

  <h2>Testing Types Summary</h2>
  <table>
    <tr><th>Category Type</th><th>Total</th><th>Passed</th><th>Failed</th><th>Pass Rate</th></tr>
    ${Object.keys(typeStats).map(type => {
      const st = typeStats[type];
      const rate = ((st.passed / st.total) * 100).toFixed(2);
      return `<tr>
        <td>${type}</td>
        <td>${st.total}</td>
        <td>${st.passed}</td>
        <td>${st.failed}</td>
        <td>${rate}%</td>
      </tr>`;
    }).join('')}
  </table>

  <h2>Test Cases Execution Details</h2>
  <table>
    <tr><th>Suite Name</th><th>Test Case</th><th>Duration (ms)</th><th>Status</th></tr>
    ${results.map(r => `
      <tr>
        <td>${r.Suite}</td>
        <td>${r.Test}</td>
        <td>${r.DurationMs}ms</td>
        <td class="${r.Status === 'PASS' ? 'status-pass' : 'status-fail'}">${r.Status}</td>
      </tr>
    `).join('')}
  </table>
</body>
</html>`;

  const reportDir = path.join(__dirname, '../dist/reports/latest');
  fs.mkdirSync(reportDir, { recursive: true });
  const htmlPath = path.join(reportDir, 'execution-report.html');
  fs.writeFileSync(htmlPath, html);
  console.log(`HTML report generated: ${htmlPath}`);
}

module.exports = generateHtmlReport;
