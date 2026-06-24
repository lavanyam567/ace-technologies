'use strict';

const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

// Configuration
const REPORTS_DIR = process.env.REPORTS_DIR
  ? path.resolve(process.env.REPORTS_DIR)
  : path.resolve(__dirname, '../reports');
const OUTPUT_PATH = process.env.SUMMARY_OUTPUT
  ? path.resolve(process.env.SUMMARY_OUTPUT)
  : path.resolve(__dirname, '../TEST_SUMMARY.md');

function findLatestReport() {
  if (!fs.existsSync(REPORTS_DIR)) {
    throw new Error(`Reports directory does not exist: ${REPORTS_DIR}`);
  }

  const files = fs.readdirSync(REPORTS_DIR)
    .filter(file => file.endsWith('.xlsx') && !file.startsWith('~$') && !file.includes('.tmp.'))
    .map(file => {
      const filePath = path.join(REPORTS_DIR, file);
      const stat = fs.statSync(filePath);
      return { file, filePath, mtime: stat.mtime };
    });

  if (files.length === 0) {
    return null;
  }

  // Sort by modification time descending
  files.sort((a, b) => b.mtime - a.mtime);
  return files[0];
}

function getRelativeEvidencePath(evidencePath) {
  if (!evidencePath) return '';
  // Convert absolute path to relative path from my_app folder
  const normEvidence = path.normalize(evidencePath);
  const myAppDir = path.resolve(__dirname, '..');
  
  if (normEvidence.startsWith(myAppDir)) {
    return path.relative(myAppDir, normEvidence).replace(/\\/g, '/');
  }
  
  // If it's already relative or starts with reports/
  const reportsIndex = normEvidence.indexOf('reports');
  if (reportsIndex !== -1) {
    return normEvidence.slice(reportsIndex).replace(/\\/g, '/');
  }
  
  return normEvidence.replace(/\\/g, '/');
}

function parseRunnerReport(wb) {
  // Format: selenium_tests/runner.js (sheets: Dashboard, All Test Results, Failures, etc.)
  const dashSheet = wb.Sheets['Dashboard'];
  const dashboardAoa = XLSX.utils.sheet_to_json(dashSheet, { header: 1 });

  const metadata = {};
  const stats = {};
  
  // Parse Dashboard key-values
  dashboardAoa.forEach(row => {
    if (!row || row.length === 0) return;
    const key = String(row[0]).trim();
    const val = row[1];
    
    if (['Application', 'Base URL', 'Test Started', 'Report Generated', 'Environment', 'Browser', 'Headless Mode'].includes(key)) {
      metadata[key] = val;
    }
    
    if (['Total Test Cases', 'Tests Executed', 'PASSED', 'FAILED', 'WARNINGS', 'SKIPPED', 'Not Run'].includes(key)) {
      stats[key] = val;
    }
  });

  // Parse All Test Results
  const resultsSheet = wb.Sheets['All Test Results'];
  const results = resultsSheet ? XLSX.utils.sheet_to_json(resultsSheet) : [];

  // Parse Failures
  const failuresSheet = wb.Sheets['Failures'];
  const failures = failuresSheet ? XLSX.utils.sheet_to_json(failuresSheet) : [];

  // Normalize results format
  const normalizedResults = results.map(r => ({
    id: r['Test ID'] || r['Test Case ID'],
    module: r['Module / Area'] || r['Module'] || 'General',
    priority: r['Priority'],
    route: r['Route'],
    scenario: r['Test Scenario'],
    status: r['Status'],
    actual: r['Actual Result'] || r['Failure Detail'],
    duration: r['Duration (ms)'],
    evidence: getRelativeEvidencePath(r['Evidence (path)'] || r['Evidence'])
  }));

  const normalizedFailures = failures.map(f => ({
    id: f['Test ID'] || f['Test Case ID'],
    module: f['Module / Area'] || f['Module'] || 'General',
    route: f['Route'],
    scenario: f['Test Scenario'],
    actual: f['Failure Detail'] || f['Actual Result'],
    evidence: getRelativeEvidencePath(f['Evidence'])
  }));

  return {
    type: 'runner',
    metadata: {
      application: metadata['Application'] || 'Ace Technologies',
      baseUrl: metadata['Base URL'] || '',
      startedAt: metadata['Test Started'] || '',
      generatedAt: metadata['Report Generated'] || '',
      environment: metadata['Environment'] || '',
      browser: metadata['Browser'] || '',
      headless: metadata['Headless Mode'] || ''
    },
    stats: {
      total: stats['Total Test Cases'] || normalizedResults.length,
      executed: stats['Tests Executed'] || normalizedResults.length,
      passed: stats['PASSED'] || 0,
      failed: stats['FAILED'] || 0,
      warnings: stats['WARNINGS'] || 0,
      skipped: stats['SKIPPED'] || 0,
      notRun: stats['Not Run'] || 0
    },
    results: normalizedResults,
    failures: normalizedFailures
  };
}

function parseE2eReport(wb) {
  // Format: tests/e2e/selenium-e2e.js (sheets: Summary, E2E Test Cases, Failures, etc.)
  const summarySheet = wb.Sheets['Summary'];
  const summaryAoa = XLSX.utils.sheet_to_json(summarySheet, { header: 1 });

  const metadata = {};
  summaryAoa.forEach(row => {
    if (!row || row.length < 2) return;
    metadata[row[0]] = row[1];
  });

  const resultsSheet = wb.Sheets['E2E Test Cases'];
  const results = resultsSheet ? XLSX.utils.sheet_to_json(resultsSheet) : [];

  const failuresSheet = wb.Sheets['Failures'];
  const failures = failuresSheet ? XLSX.utils.sheet_to_json(failuresSheet) : [];

  const normalizedResults = results.map(r => ({
    id: r['Test Case ID'] || r['Test ID'],
    module: r['Module'] || r['Module / Area'] || 'General',
    priority: r['Priority'],
    route: r['Route'],
    scenario: r['Test Scenario'],
    status: r['Status'],
    actual: r['Actual Result'] || r['Failure Detail'],
    duration: r['Duration (ms)'],
    evidence: getRelativeEvidencePath(r['Evidence'])
  }));

  const normalizedFailures = failures.map(f => ({
    id: f['Test Case ID'] || f['Test ID'],
    module: f['Module'] || f['Module / Area'] || 'General',
    route: f['Route'],
    scenario: f['Test Scenario'] || '',
    actual: f['Failure Detail'] || f['Actual Result'],
    evidence: getRelativeEvidencePath(f['Evidence'])
  }));

  const total = Number(metadata['Total Planned Cases']) || normalizedResults.length;
  const executed = Number(metadata['Executed Cases']) || normalizedResults.length;
  const passed = Number(metadata['Passed']) || 0;
  const failed = Number(metadata['Failed']) || 0;
  const notRun = Number(metadata['Not Run']) || (total - executed);

  return {
    type: 'e2e',
    metadata: {
      application: metadata['Application'] || 'Ace Technologies',
      baseUrl: metadata['Base URL'] || '',
      startedAt: metadata['Started At'] || '',
      generatedAt: metadata['Report Generated At'] || '',
      environment: 'development',
      browser: 'Google Chrome (ChromeDriver)',
      headless: metadata['Headless'] || ''
    },
    stats: {
      total,
      executed,
      passed,
      failed,
      warnings: 0,
      skipped: 0,
      notRun
    },
    results: normalizedResults,
    failures: normalizedFailures
  };
}

function generateMarkdown(parsed) {
  const meta = parsed.metadata;
  const stats = parsed.stats;
  const passRate = stats.executed > 0 ? Math.round((stats.passed / stats.executed) * 100) : 0;

  // Group by modules for statistics table
  const modules = {};
  parsed.results.forEach(r => {
    if (!modules[r.module]) {
      modules[r.module] = { total: 0, passed: 0, failed: 0 };
    }
    modules[r.module].total += 1;
    if (r.status === 'PASS') modules[r.module].passed += 1;
    if (r.status === 'FAIL') modules[r.module].failed += 1;
  });

  let md = `# 📊 E2E Test Execution Summary

> [!NOTE]
> This summary is auto-generated from the latest Excel test report.

## 🛠️ Execution Metadata

| Parameter | Value |
|---|---|
| **Application** | ${meta.application} |
| **Base URL** | [${meta.baseUrl}](${meta.baseUrl}) |
| **Start Time** | ${meta.startedAt} |
| **Generated At** | ${meta.generatedAt} |
| **Browser** | ${meta.browser} |
| **Headless Mode** | ${meta.headless} |

## 📈 Summary Statistics

| Metric | Count | Percentage |
|---|---|---|
| **Total Planned Cases** | ${stats.total} | 100% |
| **Tests Executed** | ${stats.executed} | ${stats.total > 0 ? Math.round((stats.executed / stats.total) * 100) : 0}% |
| **Passed ✅** | ${stats.passed} | **${passRate}%** of executed |
| **Failed ❌** | ${stats.failed} | ${stats.executed > 0 ? Math.round((stats.failed / stats.executed) * 100) : 0}% of executed |
| **Not Run ⏳** | ${stats.notRun} | ${stats.total > 0 ? Math.round((stats.notRun / stats.total) * 100) : 0}% |

---

## 📂 Module / Area Breakdown

| Module / Area | Total | Passed | Failed | Pass Rate |
|---|---|---|---|---|
`;

  Object.keys(modules).forEach(modName => {
    const mod = modules[modName];
    const modRate = mod.total > 0 ? Math.round((mod.passed / mod.total) * 100) : 0;
    const statusEmoji = mod.failed > 0 ? '❌' : '✅';
    md += `| **${modName}** | ${mod.total} | ${mod.passed} | ${mod.failed} | ${statusEmoji} **${modRate}%** |\n`;
  });

  md += `
---

## 🚨 Failed Test Cases (${stats.failed})
`;

  if (parsed.failures.length === 0) {
    md += `\n> [!TIP]
> **All executed tests passed successfully! No failures to report.** 🎉
`;
  } else {
    md += `
| ID | Module | Route | Scenario / Error | Evidence |
|---|---|---|---|---|
`;
    parsed.failures.forEach(fail => {
      const rawEvidence = fail.evidence;
      const evidenceLink = rawEvidence ? `[Screenshot](${rawEvidence})` : 'N/A';
      // Clean up newlines in actual result for table format
      const cleanedActual = String(fail.actual || 'No failure detail provided')
        .replace(/[\r\n]+/g, ' ')
        .replace(/\|/g, '\\|')
        .slice(0, 150);
      
      md += `| \`${fail.id}\` | ${fail.module} | \`${fail.route}\` | **Scenario:** ${fail.scenario || ''}<br>**Error:** \`${cleanedActual}\` | ${evidenceLink} |\n`;
    });
  }

  md += `
---
*Summary generated on: ${new Date().toISOString()}*
`;

  return md;
}

function main() {
  console.log('🔍 Locating latest Excel test report...');
  const latest = findLatestReport();
  
  if (!latest) {
    console.error('❌ No Excel test reports found in reports/ folder.');
    process.exit(1);
  }
  
  console.log(`📄 Found latest report: ${latest.file} (modified: ${latest.mtime})`);
  
  const wb = XLSX.readFile(latest.filePath);
  let parsed;
  
  if (wb.SheetNames.includes('Summary')) {
    parsed = parseE2eReport(wb);
  } else if (wb.SheetNames.includes('Dashboard')) {
    parsed = parseRunnerReport(wb);
  } else {
    console.error('❌ Unsupported report format. Excel sheet must have "Summary" or "Dashboard" tab.');
    process.exit(1);
  }
  
  console.log(`📊 Parsed test results. Type: ${parsed.type}, Executed: ${parsed.stats.executed}, Passed: ${parsed.stats.passed}, Failed: ${parsed.stats.failed}`);
  
  const markdown = generateMarkdown(parsed);
  
  fs.writeFileSync(OUTPUT_PATH, markdown, 'utf8');
  console.log(`✅ Markdown summary successfully written to: ${OUTPUT_PATH}`);
}

if (require.main === module) {
  main();
}
