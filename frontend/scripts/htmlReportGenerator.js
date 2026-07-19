const fs = require('fs');

function generateHTML(results, categoryStats) {
    let totalPassed = 0;
    let totalFailed = 0;
    let totalDuration = 0;

    const categoryRows = Object.keys(categoryStats).map(cat => {
        const stats = categoryStats[cat];
        totalPassed += stats.Passed;
        totalFailed += stats.Failed;
        totalDuration += stats.Duration;

        return `
            <tr>
                <td>${cat}</td>
                <td>${stats.Total}</td>
                <td style="color: #4caf50;">${stats.Passed}</td>
                <td style="color: #f44336;">${stats.Failed}</td>
                <td>${stats.Duration}ms</td>
            </tr>
        `;
    }).join('');

    const totalTests = totalPassed + totalFailed;

    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>ACE Technologies - E2E Execution Report</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #121212; color: #e0e0e0; margin: 0; padding: 20px; }
        h1 { color: #ffffff; text-align: center; }
        .summary-container { display: flex; justify-content: space-around; background: #1e1e1e; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .stat-box { text-align: center; }
        .stat-box h3 { margin: 0 0 10px 0; color: #b3b3b3; }
        .stat-box p { font-size: 24px; font-weight: bold; margin: 0; }
        .pass { color: #4caf50; }
        .fail { color: #f44336; }
        table { width: 100%; border-collapse: collapse; background: #1e1e1e; border-radius: 8px; overflow: hidden; }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #333; }
        th { background-color: #2c2c2c; color: #ffffff; }
        tr:hover { background-color: #2a2a2a; }
    </style>
</head>
<body>
    <h1>ACE Technologies - E2E Test Execution Report</h1>
    
    <div class="summary-container">
        <div class="stat-box">
            <h3>Total Tests</h3>
            <p>${totalTests}</p>
        </div>
        <div class="stat-box">
            <h3>Passed</h3>
            <p class="pass">${totalPassed}</p>
        </div>
        <div class="stat-box">
            <h3>Failed</h3>
            <p class="fail">${totalFailed}</p>
        </div>
        <div class="stat-box">
            <h3>Total Duration</h3>
            <p>${totalDuration}ms</p>
        </div>
    </div>

    <h2>Category Breakdown</h2>
    <table>
        <thead>
            <tr>
                <th>Category</th>
                <th>Total</th>
                <th>Passed</th>
                <th>Failed</th>
                <th>Duration</th>
            </tr>
        </thead>
        <tbody>
            ${categoryRows}
        </tbody>
    </table>
</body>
</html>
    `;

    fs.writeFileSync('execution-report.html', htmlContent);
    console.log('HTML report saved to execution-report.html');
}

module.exports = { generateHTML };
