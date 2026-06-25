const fs = require('fs');
const path = require('path');

const resultsPath = path.join(__dirname, '../reports/latest/results.json');
if (!fs.existsSync(resultsPath)) {
  console.log("results.json not found.");
  process.exit(0);
}

const data = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
const total = data.summary.find(s => s.Metric === 'Total Tests').Value;
const pass = data.summary.find(s => s.Metric === 'Passed').Value;
const fail = data.summary.find(s => s.Metric === 'Failed').Value;

const summaryMd = `
### 📱 Mobile Appium E2E Test Suite Completed
- **Total Tests:** ${total}
- **Passed:** ✅ ${pass}
- **Failed:** ❌ ${fail}
- **Success Rate:** ${data.summary.find(s => s.Metric === 'Success Rate (%)').Value}%

_Detailed Excel and HTML reports are available in the workflow artifacts._
`;

const dest = process.env.GITHUB_STEP_SUMMARY;
if (dest && fs.existsSync(dest)) {
  fs.appendFileSync(dest, summaryMd);
} else {
  console.log("GITHUB_STEP_SUMMARY not found. Outputting to console:");
  console.log(summaryMd);
}
