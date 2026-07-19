const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '../..');
const frontendDir = path.join(rootDir, 'frontend');
const backendDir = path.join(rootDir, 'backend');
const distReportsDir = path.join(frontendDir, 'dist', 'reports');

// Ensure output directory exists
if (!fs.existsSync(distReportsDir)) {
    fs.mkdirSync(distReportsDir, { recursive: true });
}

// Find most recent file matching a pattern
function getLatestFile(dir, pattern) {
    if (!fs.existsSync(dir)) return null;
    const files = fs.readdirSync(dir)
        .filter(f => pattern.test(f))
        .map(f => ({ name: f, time: fs.statSync(path.join(dir, f)).mtime.getTime() }))
        .sort((a, b) => b.time - a.time);
    return files.length > 0 ? path.join(dir, files[0].name) : null;
}

// List of source files and their target names
const mappings = [
    // 1. Selenium report
    {
        src: path.join(frontendDir, 'selenium-report.xlsx'),
        dest: path.join(distReportsDir, 'AceTechnologies_E2E_Report.xlsx')
    },
    // 2. Appium report (most recent)
    {
        src: () => getLatestFile(path.join(frontendDir, 'appium_tests', 'reports'), /Ace_Technologies_Appium_TestReport_.*\.xlsx$/),
        dest: path.join(distReportsDir, 'Appium_E2E_Report_AceTechnologies.xlsx')
    },
    // 3. Load test report
    {
        src: path.join(frontendDir, 'k6_tests', 'results', 'load-test-report.xlsx'),
        dest: path.join(distReportsDir, 'Load_Test_Report.xlsx')
    },
    // 4. Vulnerability scan report
    {
        src: path.join(frontendDir, 'automated_test', 'dast_report.xlsx'),
        dest: path.join(distReportsDir, 'Vulnerability_Scan_Report.xlsx')
    },
    // 5. Backend security findings
    {
        src: path.join(backendDir, 'backend-findings.xlsx'),
        dest: path.join(distReportsDir, 'backend-findings.xlsx')
    },
    // 6. Web security findings
    {
        src: path.join(frontendDir, 'web-security-findings.xlsx'),
        dest: path.join(distReportsDir, 'web-security-findings.xlsx')
    }
];

console.log("Starting report repackaging and rebranding...");

mappings.forEach(m => {
    let sourcePath = typeof m.src === 'function' ? m.src() : m.src;
    
    if (sourcePath && fs.existsSync(sourcePath)) {
        console.log(`Copying and rebranding: ${sourcePath} -> ${m.dest}`);
        try {
            // Run the python rebranding script
            const pythonScript = path.join(frontendDir, 'scripts', 'rebrand_excel.py');
            execSync(`python "${pythonScript}" "${sourcePath}" "${m.dest}"`, { stdio: 'inherit' });
            console.log(`Rebranding completed for: ${path.basename(m.dest)}`);
        } catch (err) {
            console.error(`Error rebranding ${sourcePath}:`, err.message);
            // Fallback: simple copy
            fs.copyFileSync(sourcePath, m.dest);
        }
    } else {
        console.warn(`Warning: Source file not found: ${sourcePath || 'N/A'}`);
    }
});

console.log("Repackaging and rebranding complete. Files stored in:", distReportsDir);
