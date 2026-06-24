'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  Ace Technologies – Appium Test Suite  ·  Excel Report Generator
// ─────────────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');
const CONFIG = require('../config/test-config');

// ── Helpers ──────────────────────────────────────────────────────────────────

function ensureDirs() {
  fs.mkdirSync(CONFIG.paths.reports, { recursive: true });
  fs.mkdirSync(CONFIG.paths.evidence, { recursive: true });
}

function statusColor(status) {
  if (status === 'PASS') return '00B050'; // green
  if (status === 'FAIL') return 'FF0000'; // red
  if (status === 'WARN') return 'FFA500'; // orange
  if (status === 'SKIP') return 'AAAAAA'; // grey
  return 'CCCCCC';
}

function centeredStyle(bgRgb, bold = false) {
  return {
    font: { bold, color: { rgb: 'FFFFFF' } },
    fill: { type: 'pattern', patternType: 'solid', fgColor: { rgb: bgRgb } },
    alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
    border: {
      top: { style: 'thin', color: { rgb: 'CCCCCC' } },
      bottom: { style: 'thin', color: { rgb: 'CCCCCC' } },
      left: { style: 'thin', color: { rgb: 'CCCCCC' } },
      right: { style: 'thin', color: { rgb: 'CCCCCC' } },
    },
  };
}

function headerStyle() {
  return {
    font: { bold: true, color: { rgb: 'FFFFFF' }, sz: 11 },
    fill: { type: 'pattern', patternType: 'solid', fgColor: { rgb: '172033' } },
    alignment: { horizontal: 'center', vertical: 'center', wrapText: true },
    border: {
      top: { style: 'medium', color: { rgb: '000000' } },
      bottom: { style: 'medium', color: { rgb: '000000' } },
      left: { style: 'thin', color: { rgb: '888888' } },
      right: { style: 'thin', color: { rgb: '888888' } },
    },
  };
}

/** Append a styled sheet to the workbook. */
function appendStyledSheet(wb, name, rows, colWidths = []) {
  const ws = XLSX.utils.json_to_sheet(rows);

  // Apply header styles
  const headers = Object.keys(rows[0] || {});
  headers.forEach((_, ci) => {
    const cellAddr = XLSX.utils.encode_cell({ r: 0, c: ci });
    if (ws[cellAddr]) ws[cellAddr].s = headerStyle();
  });

  // Apply row styles for Status column
  rows.forEach((row, ri) => {
    headers.forEach((col, ci) => {
      const cellAddr = XLSX.utils.encode_cell({ r: ri + 1, c: ci });
      if (!ws[cellAddr]) return;
      const style = {
        alignment: { vertical: 'center', wrapText: true },
        border: {
          top: { style: 'thin', color: { rgb: 'DDDDDD' } },
          bottom: { style: 'thin', color: { rgb: 'DDDDDD' } },
          left: { style: 'thin', color: { rgb: 'DDDDDD' } },
          right: { style: 'thin', color: { rgb: 'DDDDDD' } },
        },
      };
      if (col === 'Status') {
        style.font = { bold: true, color: { rgb: 'FFFFFF' } };
        style.fill = {
          type: 'pattern',
          patternType: 'solid',
          fgColor: { rgb: statusColor(row[col]) }
        };
        style.alignment = { horizontal: 'center', vertical: 'center' };
      }
      // Alternating row background
      if (ri % 2 === 0) {
        style.fill = style.fill || {
          type: 'pattern',
          patternType: 'solid',
          fgColor: { rgb: 'F7F9FC' }
        };
      }
      ws[cellAddr].s = style;
    });
  });

  // Set column widths
  if (colWidths.length) {
    ws['!cols'] = colWidths.map((w) => ({ wch: w }));
  }

  XLSX.utils.book_append_sheet(wb, ws, name);
}

// ── Main report writer ────────────────────────────────────────────────────────

/**
 * Generate the Excel Appium test report.
 *
 * @param {object[]} allResults  Array of test runs
 * @param {object[]} allCases    Full case manifest
 * @param {Date}     startedAt   When the run started.
 * @param {boolean}  isMock      Whether mock driver was active.
 */
function generateReport(allResults, allCases, startedAt, isMock = false) {
  ensureDirs();
  const now = new Date();
  const filename = `Ace_Technologies_Appium_TestReport_${startedAt.toISOString().replace(/[:.]/g, '-')}.xlsx`;
  const filepath = path.join(CONFIG.paths.reports, filename);

  const passed = allResults.filter((r) => r.status === 'PASS').length;
  const failed = allResults.filter((r) => r.status === 'FAIL').length;
  const warned = allResults.filter((r) => r.status === 'WARN').length;
  const skipped = allResults.filter((r) => r.status === 'SKIP').length;
  const total = allCases.length;

  const wb = XLSX.utils.book_new();

  // ── Sheet 1: Executive Dashboard ─────────────────────────────────────────
  const dashboardAoa = [
    ['ACE TECHNOLOGIES – MOBILE APPLICATION TEST REPORT'],
    [],
    ['Application', CONFIG.app.name],
    ['App Package', CONFIG.app.package],
    ['Test Started', startedAt.toISOString()],
    ['Report Generated', now.toISOString()],
    ['Environment', process.env.NODE_ENV || 'development'],
    ['Automation Driver', isMock ? 'Appium Mock Simulator' : 'Appium UiAutomator2 (Android)'],
    ['Target Device / Emulator', isMock ? 'N/A' : CONFIG.capabilities['appium:deviceName']],
    [],
    ['METRIC', 'VALUE', 'PERCENTAGE'],
    ['Total Test Cases', total, '100%'],
    ['Tests Executed', allResults.length, `${Math.round(allResults.length / total * 100) || 0}%`],
    ['PASSED', passed, `${Math.round(passed / (allResults.length || 1) * 100)}%`],
    ['FAILED', failed, `${Math.round(failed / (allResults.length || 1) * 100)}%`],
    ['WARNINGS', warned, `${Math.round(warned / (allResults.length || 1) * 100)}%`],
    ['SKIPPED', skipped, `${Math.round(skipped / (allResults.length || 1) * 100)}%`],
    ['Not Run', total - allResults.length, ''],
    [],
    ['SUITES COVERED'],
    ['1. Functional Testing'],
    ['2. UI/UX Testing'],
    ['3. Compatibility Testing'],
    ['4. End-to-End (E2E) Testing'],
  ];

  const dashWs = XLSX.utils.aoa_to_sheet(dashboardAoa);
  dashWs['!merges'] = [{ s: { r: 0, c: 0 }, e: { r: 0, c: 2 } }];
  dashWs['!cols'] = [{ wch: 30 }, { wch: 50 }, { wch: 15 }];
  
  // Title style
  if (dashWs['A1']) dashWs['A1'].s = centeredStyle('0F8A70', true);
  XLSX.utils.book_append_sheet(wb, dashWs, 'Dashboard');

  // ── Sheet 2: All Test Results ─────────────────────────────────────────────
  const detailRows = allResults.map((r) => ({
    'Test ID': r.id,
    'Suite': r.suite,
    'Module / Area': r.area,
    'Priority': r.priority,
    'Route': r.route,
    'Test Scenario': r.title,
    'Expected Result': r.expected,
    'Status': r.status,
    'Actual Result': r.actual,
    'Duration (ms)': r.durationMs,
    'Timestamp': r.timestamp,
    'Evidence (path)': r.evidence || '',
  }));
  appendStyledSheet(wb, 'All Test Results', detailRows,
    [10, 18, 20, 10, 30, 45, 40, 10, 50, 14, 25, 50]);

  // ── Sheets 3-6: Per-suite sheets ──────────────────────────────────────────
  const sanitizeSheetName = (name) =>
    name.replace(/[:/\\?*[\]]/g, '-').slice(0, 31);

  const suites = [...new Set(allResults.map((r) => r.suite))];
  for (const suite of suites) {
    const rows = allResults
      .filter((r) => r.suite === suite)
      .map((r) => ({
        'Test ID': r.id,
        'Module / Area': r.area,
        'Priority': r.priority,
        'Route': r.route,
        'Test Scenario': r.title,
        'Expected Result': r.expected,
        'Status': r.status,
        'Actual Result': r.actual,
        'Duration (ms)': r.durationMs,
        'Timestamp': r.timestamp,
      }));
    if (rows.length) {
      const sheetName = sanitizeSheetName(suite);
      appendStyledSheet(wb, sheetName, rows,
        [10, 20, 10, 28, 45, 38, 10, 50, 12, 25]);
    }
  }

  // ── Sheet: Coverage Matrix ────────────────────────────────────────────────
  const coverageRows = allCases.map((c) => {
    const r = allResults.find((x) => x.id === c.id);
    return {
      'Test ID': c.id,
      'Suite': c.suite,
      'Module / Area': c.area,
      'Priority': c.priority,
      'Route': c.route,
      'Test Scenario': c.title,
      'Status': r ? r.status : 'NOT RUN',
    };
  });
  appendStyledSheet(wb, 'Coverage Matrix', coverageRows,
    [10, 18, 20, 10, 30, 50, 12]);

  // ── Sheet: Failures ───────────────────────────────────────────────────────
  const failRows = allResults
    .filter((r) => r.status === 'FAIL')
    .map((r) => ({
      'Test ID': r.id,
      'Suite': r.suite,
      'Module / Area': r.area,
      'Route': r.route,
      'Test Scenario': r.title,
      'Failure Detail': r.actual,
      'Duration (ms)': r.durationMs,
      'Evidence': r.evidence || 'N/A',
      'Timestamp': r.timestamp,
    }));
  if (failRows.length) {
    appendStyledSheet(wb, 'Failures', failRows,
      [10, 16, 18, 28, 45, 60, 12, 55, 25]);
  }

  // Write workbook
  const tmp = filepath.replace(/\.xlsx$/i, '.tmp.xlsx');
  XLSX.writeFile(wb, tmp);
  fs.copyFileSync(tmp, filepath);
  fs.unlinkSync(tmp);

  return filepath;
}

module.exports = { generateReport, ensureDirs };
