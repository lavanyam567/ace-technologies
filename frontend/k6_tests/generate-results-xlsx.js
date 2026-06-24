const XLSX = require('xlsx');

const data = [
  { Metric: "Total Requests", Value: "1443" },
  { Metric: "Requests/sec", Value: "11.98" },
  { Metric: "Failed Requests (HTTP Errors)", Value: "0 (0%)" },
  { Metric: "Status 200 OK", Value: "1443 (100%)" },
  { Metric: "Failed SLA (Response > 1s)", Value: "8 requests" },
  { Metric: "Average Response Time", Value: "242.21 ms" },
  { Metric: "Median Response Time", Value: "200.23 ms" },
  { Metric: "95th Percentile Response Time", Value: "498.12 ms" },
  { Metric: "Max Response Time", Value: "1.86 s" },
  { Metric: "Peak Virtual Users", Value: "30" },
  { Metric: "Data Received", Value: "39 MB" }
];

const worksheet = XLSX.utils.json_to_sheet(data);
const workbook = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(workbook, worksheet, "Load Test Results");

XLSX.writeFile(workbook, "k6_tests/results/load-test-report.xlsx");
console.log("XLSX generated successfully at k6_tests/results/load-test-report.xlsx");
