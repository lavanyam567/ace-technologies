const fs = require('fs');
const path = require('path');

const reportDir = path.join(__dirname, '../reports/latest');
const resultsPath = path.join(reportDir, 'results.json');

if (!fs.existsSync(resultsPath)) {
  console.log("No results.json found, skipping HTML generation.");
  process.exit(0);
}

const data = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));

let html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Appium Android E2E Execution Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #121212; color: #e0e0e0; padding: 2rem; margin: 0; }
        h1, h2 { color: #ffffff; }
        .card { background-color: #1e1e1e; border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; }
        .metric { font-size: 2rem; font-weight: bold; color: #4caf50; }
        .metric.fail { color: #f44336; }
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #333; }
        th { background-color: #2c2c2c; }
        .pass { color: #4caf50; font-weight: bold; }
        .fail { color: #f44336; font-weight: bold; }
    </style>
</head>
<body>
    <h1>📱 Mobile Appium E2E Report</h1>
    
    <div class="card">
        <h2>Execution Summary</h2>
        <div class="grid">
            <div>Total Tests<br><span class="metric">${data.summary.find(s => s.Metric === 'Total Tests').Value}</span></div>
            <div>Passed<br><span class="metric">${data.summary.find(s => s.Metric === 'Passed').Value}</span></div>
            <div>Failed<br><span class="metric fail">${data.summary.find(s => s.Metric === 'Failed').Value}</span></div>
            <div>Success Rate<br><span class="metric">${data.summary.find(s => s.Metric === 'Success Rate (%)').Value}%</span></div>
        </div>
    </div>

    <div class="card">
        <h2>Category Breakdown</h2>
        <table>
            <tr><th>Category</th><th>Passed</th><th>Failed</th><th>Total Time (ms)</th></tr>
            ${data.categoryRows.map(c => `<tr><td>${c.Category}</td><td>${c.Passed}</td><td>${c.Failed}</td><td>${c.TotalTime}</td></tr>`).join('')}
        </table>
    </div>
</body>
</html>
`;

fs.writeFileSync(path.join(reportDir, 'execution-report.html'), html);
console.log("HTML Execution Report successfully generated.");
