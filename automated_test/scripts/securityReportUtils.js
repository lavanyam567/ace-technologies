const fs = require('fs');
const path = require('path');

function projectRoot() {
  return path.resolve(__dirname, '..', '..');
}

function reportsDir() {
  return path.resolve(__dirname, '..', 'reports');
}

function ensureReportsDir() {
  fs.mkdirSync(reportsDir(), { recursive: true });
}

function readProjectFile(relativePath) {
  const absolutePath = path.join(projectRoot(), relativePath);
  return {
    relativePath,
    absolutePath,
    content: fs.readFileSync(absolutePath, 'utf8'),
  };
}

function lineNumberFor(content, needle) {
  const index =
    needle instanceof RegExp ? content.search(needle) : content.indexOf(needle);
  if (index < 0) return null;
  return content.slice(0, index).split(/\r?\n/).length;
}

function snippetAround(content, needle) {
  const index =
    needle instanceof RegExp ? content.search(needle) : content.indexOf(needle);
  if (index < 0) return 'Pattern not present.';
  const line = content.slice(0, index).split(/\r?\n/).length - 1;
  const lines = content.split(/\r?\n/);
  const start = Math.max(0, line - 1);
  const end = Math.min(lines.length, line + 2);
  return lines
    .slice(start, end)
    .join('\n')
    .trim();
}

function fileEvidence(file, needle, fallbackLine = 1) {
  const line = lineNumberFor(file.content, needle) ?? fallbackLine;
  return {
    file: file.relativePath,
    line,
    snippet: snippetAround(file.content, needle),
  };
}

function absenceEvidence(relativePath, detail, line = 1) {
  return {
    file: relativePath,
    line,
    snippet: detail,
  };
}

function evidenceText(evidence) {
  return `${evidence.file}:${evidence.line}`;
}

function markdownFinding(finding) {
  return [
    `### ${finding.id}. ${finding.title}`,
    `- Severity: ${finding.severity}`,
    `- Category: ${finding.category}`,
    `- Evidence: \`${evidenceText(finding.evidence)}\``,
    `- Description: ${finding.description}`,
    `- Recommendation: ${finding.recommendation}`,
    '',
    '```text',
    finding.evidence.snippet,
    '```',
    '',
  ].join('\n');
}

function makeExecutiveSummary({
  title,
  stack,
  score,
  riskLevel,
  findings,
  hardeningAdvice,
}) {
  const lowCount = findings.filter((finding) => finding.severity === 'Low').length;
  const mediumCount = findings.filter((finding) => finding.severity === 'Medium').length;
  const highCount = findings.filter((finding) => finding.severity === 'High').length;
  const criticalCount = findings.filter((finding) => finding.severity === 'Critical').length;

  return [
    `# ${title}`,
    '',
    `- Technology Detected: ${stack}`,
    `- Security Score: ${score}/100`,
    `- Risk Rating: ${riskLevel}`,
    `- Total Findings: ${findings.length}`,
    `- Critical Findings: ${criticalCount}`,
    `- High Findings: ${highCount}`,
    `- Medium Findings: ${mediumCount}`,
    `- Low Findings: ${lowCount}`,
    '',
    '## Hardening Priorities',
    ...hardeningAdvice.map((item) => `- ${item}`),
    '',
  ].join('\n');
}

function styleHeaderRow(row, background = '1F4E78') {
  row.eachCell((cell) => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: background },
    };
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFD9E1F2' } },
      left: { style: 'thin', color: { argb: 'FFD9E1F2' } },
      bottom: { style: 'thin', color: { argb: 'FFD9E1F2' } },
      right: { style: 'thin', color: { argb: 'FFD9E1F2' } },
    };
  });
}

function styleDataRows(worksheet) {
  if (typeof worksheet.eachRow !== 'function') {
    return;
  }
  worksheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    row.eachCell((cell) => {
      cell.alignment = { vertical: 'top', wrapText: true };
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFE5E7EB' } },
        left: { style: 'thin', color: { argb: 'FFE5E7EB' } },
        bottom: { style: 'thin', color: { argb: 'FFE5E7EB' } },
        right: { style: 'thin', color: { argb: 'FFE5E7EB' } },
      };
    });
  });
}

async function createWorkbook(filename) {
  const outputPath = path.join(reportsDir(), filename);
  try {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Codex';
    workbook.created = new Date();
    workbook.modified = new Date();
    return { ExcelJS, workbook, outputPath, engine: 'exceljs' };
  } catch (error) {
    // eslint-disable-next-line global-require
    const XLSX = require('xlsx');
    const sheets = [];
    const workbook = {
      addWorksheet(name) {
        const sheet = {
          name,
          _columns: [],
          _rows: [],
          set columns(value) {
            this._columns = value;
          },
          get columns() {
            return this._columns;
          },
          addRow(value) {
            this._rows.push(value);
            return { eachCell() {} };
          },
          getRow() {
            return { eachCell() {} };
          },
        };
        sheets.push(sheet);
        return sheet;
      },
      xlsx: {
        async writeFile(targetPath) {
          const wb = XLSX.utils.book_new();
          for (const sheet of sheets) {
            const headers = sheet._columns.map((column) => column.header);
            const keys = sheet._columns.map((column) => column.key);
            const rows = sheet._rows.map((row) => {
              if (Array.isArray(row)) return row;
              return keys.map((key) => row[key]);
            });
            const ws = XLSX.utils.aoa_to_sheet([headers, ...rows]);
            ws['!cols'] = sheet._columns.map((column) => ({
              wch: column.width || 20,
            }));
            XLSX.utils.book_append_sheet(wb, ws, sheet.name);
          }
          XLSX.writeFile(wb, targetPath);
        },
      },
    };
    return { workbook, outputPath, engine: 'xlsx-fallback', fallbackError: error.message };
  }
}

function addRiskSummarySheet(workbook, summaryTitle, rows) {
  const sheet = workbook.addWorksheet(summaryTitle);
  sheet.columns = [
    { header: 'Metric', key: 'metric', width: 30 },
    { header: 'Value', key: 'value', width: 70 },
  ];
  rows.forEach((row) => sheet.addRow(row));
  styleHeaderRow(sheet.getRow(1), '0F766E');
  styleDataRows(sheet);
  return sheet;
}

function writeMarkdown(filename, content) {
  ensureReportsDir();
  const outputPath = path.join(reportsDir(), filename);
  fs.writeFileSync(outputPath, content, 'utf8');
  return outputPath;
}

module.exports = {
  addRiskSummarySheet,
  absenceEvidence,
  createWorkbook,
  ensureReportsDir,
  evidenceText,
  fileEvidence,
  lineNumberFor,
  markdownFinding,
  makeExecutiveSummary,
  projectRoot,
  readProjectFile,
  reportsDir,
  styleDataRows,
  styleHeaderRow,
  writeMarkdown,
};
