const path = require('path');
const {
  createWorkbook,
  ensureReportsDir,
  reportsDir,
  styleDataRows,
  styleHeaderRow,
} = require('./securityReportUtils');

function parseSummary(markdown) {
  const get = (label) => {
    const match = markdown.match(new RegExp(`- ${label}: (.+)`));
    return match ? match[1].trim() : '';
  };

  return {
    technology: get('Technology Detected'),
    score: get('Security Score'),
    risk: get('Risk Rating'),
    total: get('Total Findings'),
    critical: get('Critical Findings'),
    high: get('High Findings'),
    medium: get('Medium Findings'),
    low: get('Low Findings'),
  };
}

async function main() {
  ensureReportsDir();
  const fs = require('fs');
  const reportRoot = reportsDir();
  const webSummaryPath = path.join(reportRoot, 'web-executive-summary.md');
  const backendSummaryPath = path.join(reportRoot, 'executive-summary.md');

  if (!fs.existsSync(webSummaryPath) || !fs.existsSync(backendSummaryPath)) {
    throw new Error(
      'Missing security summaries. Generate the web and backend security suites before creating the pipeline workbook.',
    );
  }

  const webSummary = parseSummary(fs.readFileSync(webSummaryPath, 'utf8'));
  const backendSummary = parseSummary(fs.readFileSync(backendSummaryPath, 'utf8'));

  const { workbook, outputPath, engine } = await createWorkbook(
    'security-pipelines-report.xlsx',
  );

  const overview = workbook.addWorksheet('Pipeline Overview');
  overview.columns = [
    { header: 'Pipeline', key: 'pipeline', width: 24 },
    { header: 'Technology', key: 'technology', width: 52 },
    { header: 'Score', key: 'score', width: 16 },
    { header: 'Risk', key: 'risk', width: 16 },
    { header: 'Critical', key: 'critical', width: 12 },
    { header: 'High', key: 'high', width: 12 },
    { header: 'Medium', key: 'medium', width: 12 },
    { header: 'Low', key: 'low', width: 12 },
    { header: 'Total Findings', key: 'total', width: 16 },
  ];
  overview.addRow({ pipeline: 'Web Frontend', ...webSummary });
  overview.addRow({ pipeline: 'Backend API', ...backendSummary });
  styleHeaderRow(overview.getRow(1), '1D4ED8');
  styleDataRows(overview);

  const artifacts = workbook.addWorksheet('Artifacts');
  artifacts.columns = [
    { header: 'Pipeline', key: 'pipeline', width: 24 },
    { header: 'Workbook', key: 'workbook', width: 42 },
    { header: 'Markdown Review', key: 'review', width: 42 },
    { header: 'Executive Summary', key: 'summary', width: 42 },
  ];
  artifacts.addRow({
    pipeline: 'Web Frontend',
    workbook: 'automated_test/reports/web-security-findings.xlsx',
    review: 'automated_test/reports/web-security-review.md',
    summary: 'automated_test/reports/web-executive-summary.md',
  });
  artifacts.addRow({
    pipeline: 'Backend API',
    workbook: 'automated_test/reports/findings.xlsx',
    review: 'automated_test/reports/security-review.md',
    summary: 'automated_test/reports/executive-summary.md',
  });
  styleHeaderRow(artifacts.getRow(1), '7C3AED');
  styleDataRows(artifacts);

  const gates = workbook.addWorksheet('Policy Gates');
  gates.columns = [
    { header: 'Policy', key: 'policy', width: 32 },
    { header: 'Frontend', key: 'frontend', width: 24 },
    { header: 'Backend', key: 'backend', width: 24 },
    { header: 'Status', key: 'status', width: 16 },
  ];
  gates.addRow({
    policy: 'Zero Critical Findings',
    frontend: webSummary.critical,
    backend: backendSummary.critical,
    status:
      webSummary.critical === '0' && backendSummary.critical === '0'
        ? 'PASS'
        : 'FAIL',
  });
  gates.addRow({
    policy: 'Zero High Findings',
    frontend: webSummary.high,
    backend: backendSummary.high,
    status:
      webSummary.high === '0' && backendSummary.high === '0' ? 'PASS' : 'FAIL',
  });
  gates.addRow({
    policy: 'Target Score 72/100',
    frontend: webSummary.score,
    backend: backendSummary.score,
    status:
      webSummary.score === '72/100' && backendSummary.score === '72/100'
        ? 'PASS'
        : 'FAIL',
  });
  styleHeaderRow(gates.getRow(1), '0F766E');
  styleDataRows(gates);

  await workbook.xlsx.writeFile(outputPath);

  console.log(
    JSON.stringify(
      {
        ok: true,
        engine,
        output: path.relative(process.cwd(), outputPath),
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
