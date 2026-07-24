const path = require('path');
const XLSX = require('xlsx');

const file = path.resolve(__dirname, '../selenium_tests/reports/Ace_Technologies_TestReport_2026-06-13T03-50-35-248Z.xlsx');
const wb = XLSX.readFile(file);
console.log("Sheets in 03-50-35-248Z:");
wb.SheetNames.forEach(name => {
    const ws = wb.Sheets[name];
    const data = XLSX.utils.sheet_to_json(ws);
    console.log(`  - "${name}" row count: ${data.length}`);
    if (data.length > 0) {
        console.log(`    Keys: ${Object.keys(data[0]).join(', ')}`);
    }
});
