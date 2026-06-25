const fs = require('fs');
const path = require('path');

const summaryPath = path.join(__dirname, '../dist/reports/latest/test-summary.json');

if (!fs.existsSync(summaryPath)) {
  console.warn('test-summary.json not found, skipping markdown summary generation.');
  process.exit(0);
}

const summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));

let markdown = `## 🧪 Web E2E Test Execution Summary

| Metric | Count |
| :--- | :--- |
| **Total Tests** | ${summary.total} |
| **✅ Passed** | ${summary.passed} |
| **❌ Failed** | ${summary.failed} |
| **📈 Pass Rate** | ${((summary.passed / summary.total) * 100).toFixed(2)}% |

### Breakdown by Category
| Category | Total | Passed | Failed | Pass Rate |
| :--- | :--- | :--- | :--- | :--- |
`;

for (const [type, st] of Object.entries(summary.typeStats)) {
  const rate = ((st.passed / st.total) * 100).toFixed(2);
  markdown += `| ${type} | ${st.total} | ${st.passed} | ${st.failed} | ${rate}% |\n`;
}

markdown += `\n[🔗 View Full HTML Execution Report](https://${process.env.GITHUB_REPOSITORY_OWNER}.github.io/${process.env.GITHUB_REPOSITORY ? process.env.GITHUB_REPOSITORY.split('/')[1] : 'ace-technologies'}/reports/latest/execution-report.html)\n`;

// Append to GITHUB_STEP_SUMMARY if available
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdown + '\n');
  console.log('Successfully appended summary to GITHUB_STEP_SUMMARY');
} else {
  console.log(markdown);
}
