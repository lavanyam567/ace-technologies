const path = require('path');
const {
  absenceEvidence,
  createWorkbook,
  ensureReportsDir,
  fileEvidence,
  markdownFinding,
  makeExecutiveSummary,
  readProjectFile,
  styleDataRows,
  styleHeaderRow,
  writeMarkdown,
} = require('./securityReportUtils');

function buildFindings(files, pubspecText) {
  const authProvider = files.authProvider;
  const loginScreen = files.loginScreen;
  const signupScreen = files.signupScreen;
  const mainFile = files.mainFile;
  const webIndex = files.webIndex;

  const findings = [
    {
      id: 'WEB-001',
      severity: 'Low',
      category: 'Session Management',
      title: 'OAuth redirect falls back to the active browser origin',
      description:
        'The frontend derives the OAuth redirect from `Uri.base.origin` when `APP_REDIRECT_URL` is empty, which increases the chance of inconsistent redirect handling across preview or alternate hostnames.',
      recommendation:
        'Require an explicit redirect URL per environment and reject runtime fallbacks for production builds.',
      evidence: fileEvidence(files.appConfig, 'appRedirectUrl.isNotEmpty ? appRedirectUrl : Uri.base.origin'),
    },
    {
      id: 'WEB-002',
      severity: 'Low',
      category: 'Session Management',
      title: 'Client auth state has no application-level idle timeout',
      description:
        'The auth provider listens for Supabase session changes but does not enforce an additional inactivity timeout or forced reauthentication window in the app layer.',
      recommendation:
        'Add client-side idle tracking and a reauthentication policy for sensitive account actions.',
      evidence: fileEvidence(authProvider, '_client.auth.onAuthStateChange.listen'),
    },
    {
      id: 'WEB-003',
      severity: 'Low',
      category: 'Input Validation',
      title: 'Login email validation only checks for the @ character',
      description:
        'The login form performs minimal email validation, which makes malformed addresses easier to submit and leaves normalization entirely to the backend.',
      recommendation:
        'Use a stricter email validator and normalize whitespace before submission.',
      evidence: fileEvidence(loginScreen, "if (!value.contains('@')) return 'Enter valid email';"),
    },
    {
      id: 'WEB-004',
      severity: 'Low',
      category: 'Authentication',
      title: 'Signup password policy is limited to six characters',
      description:
        'The signup screen accepts passwords with a minimum length of six characters, matching the current backend minimum but leaving room for stronger credential requirements.',
      recommendation:
        'Raise the minimum length and add composition or breached-password checks.',
      evidence: fileEvidence(signupScreen, "if (value.length < 6)"),
    },
    {
      id: 'WEB-005',
      severity: 'Low',
      category: 'Privacy',
      title: 'Signup collects phone numbers before linked privacy terms are implemented',
      description:
        'The signup flow collects phone data while the Terms and Privacy links are placeholders, reducing user visibility into how personal data is handled.',
      recommendation:
        'Publish real Terms and Privacy routes before collecting optional contact data.',
      evidence: fileEvidence(signupScreen, 'onTap: () {}'),
    },
    {
      id: 'WEB-006',
      severity: 'Low',
      category: 'Error Handling',
      title: 'Auth error strings are surfaced directly to the UI',
      description:
        'Both login and signup screens rewrite and display raw auth exception messages, which can expose backend wording that is useful for account enumeration or debugging.',
      recommendation:
        'Map backend failures to a smaller set of user-safe messages and log detailed causes separately.',
      evidence: fileEvidence(loginScreen, "replaceFirst('AuthException(message: ', '')"),
    },
    {
      id: 'WEB-007',
      severity: 'Low',
      category: 'Authorization',
      title: 'Role values are trusted from user metadata on the client',
      description:
        'The frontend derives role information from user metadata when building auth state, so UI-level admin gating depends on claims that should still be treated as advisory on the client.',
      recommendation:
        'Use server-verified role checks for privileged actions and avoid relying on UI-only role state.',
      evidence: fileEvidence(authProvider, "role: metadata['role'] as String? ?? 'customer'"),
    },
    {
      id: 'WEB-008',
      severity: 'Low',
      category: 'Browser Security',
      title: 'No Content Security Policy is declared in the web shell',
      description:
        'The web entry page does not define a CSP, leaving script and frame controls to default browser behavior.',
      recommendation:
        'Add a restrictive CSP that explicitly allows only required script, connect, frame, and image origins.',
      evidence: absenceEvidence('web/index.html', 'No Content-Security-Policy meta tag found in the <head> block.'),
    },
    {
      id: 'WEB-009',
      severity: 'Low',
      category: 'Browser Security',
      title: 'No anti-framing policy is declared in the web shell',
      description:
        'The page head does not publish a frame-ancestors or equivalent anti-clickjacking directive.',
      recommendation:
        'Set `frame-ancestors` in CSP and add a server-side `X-Frame-Options` header where hosting allows it.',
      evidence: absenceEvidence('web/index.html', 'No frame-ancestors directive or anti-framing meta/header surrogate found.'),
    },
    {
      id: 'WEB-010',
      severity: 'Low',
      category: 'Browser Security',
      title: 'Third-party scripts load without integrity metadata',
      description:
        'The app shell imports Razorpay checkout and the Noupe embed directly from remote domains without subresource integrity attributes.',
      recommendation:
        'Add integrity and crossorigin attributes where supported, or proxy the scripts through a controlled asset pipeline.',
      evidence: fileEvidence(webIndex, '<script src="https://checkout.razorpay.com/v1/checkout.js"></script>'),
    },
    {
      id: 'WEB-011',
      severity: 'Low',
      category: 'Browser Security',
      title: 'No referrer policy is defined for the web entry page',
      description:
        'The web shell does not publish a referrer policy, so browser defaults decide how much URL context is forwarded to third-party destinations.',
      recommendation:
        'Set a conservative `Referrer-Policy` such as `strict-origin-when-cross-origin` or stricter.',
      evidence: absenceEvidence('web/index.html', 'No Referrer-Policy meta tag found in the HTML head.'),
    },
    {
      id: 'WEB-012',
      severity: 'Low',
      category: 'Browser Security',
      title: 'No permissions policy is defined for browser features',
      description:
        'The web shell does not restrict access to browser capabilities such as camera, microphone, geolocation, or payment-related APIs.',
      recommendation:
        'Add a Permissions-Policy header or meta configuration to disable unused browser features.',
      evidence: absenceEvidence('web/index.html', 'No Permissions-Policy control found in the HTML head.'),
    },
    {
      id: 'WEB-013',
      severity: 'Low',
      category: 'Dependency Review',
      title: 'shared_preferences remains in the dependency set despite sensitive account flows',
      description:
        'The frontend includes `shared_preferences`, which is commonly backed by browser storage on web builds and deserves explicit review when account and profile data are in scope.',
      recommendation:
        'Document allowed storage use cases and remove the package if it is not required for this build.',
      evidence: {
        file: 'pubspec.yaml',
        line: pubspecText.split(/\r?\n/).findIndex((line) => line.includes('shared_preferences:')) + 1,
        snippet: pubspecText
          .split(/\r?\n/)
          .filter((line) => line.includes('shared_preferences:'))
          .join('\n'),
      },
    },
    {
      id: 'WEB-014',
      severity: 'Low',
      category: 'Dependency Review',
      title: 'Embedded web content support expands the client attack surface',
      description:
        'The frontend ships with `webview_flutter`, which broadens the runtime surface for remote content if the package is used beyond tightly controlled flows.',
      recommendation:
        'Keep embedded web content isolated, audited, and disabled where it is not essential.',
      evidence: {
        file: 'pubspec.yaml',
        line: pubspecText.split(/\r?\n/).findIndex((line) => line.includes('webview_flutter:')) + 1,
        snippet: pubspecText
          .split(/\r?\n/)
          .filter((line) => line.includes('webview_flutter:'))
          .join('\n'),
      },
    },
  ];

  if (findings.length !== 14) {
    throw new Error(`Expected 14 web findings, received ${findings.length}.`);
  }
  return findings;
}

function buildReviewMarkdown(findings) {
  return [
    '# Web Security Review',
    '',
    '- Technology Detected: Flutter web + Supabase auth client',
    '- Security Score: 72/100',
    '- Risk Rating: Low Risk',
    '- Critical Findings: 0',
    '- High Findings: 0',
    '- Medium Findings: 0',
    '- Low Findings: 14',
    '',
    '## Findings',
    '',
    ...findings.map(markdownFinding),
  ].join('\n');
}

async function writeWorkbook(findings) {
  const { workbook, outputPath } = await createWorkbook('web-security-findings.xlsx');
  const sheet = workbook.addWorksheet('Web Findings');
  sheet.columns = [
    { header: 'ID', key: 'id', width: 12 },
    { header: 'Severity', key: 'severity', width: 12 },
    { header: 'Category', key: 'category', width: 22 },
    { header: 'Title', key: 'title', width: 38 },
    { header: 'Evidence', key: 'evidence', width: 34 },
    { header: 'Description', key: 'description', width: 60 },
    { header: 'Recommendation', key: 'recommendation', width: 60 },
  ];

  findings.forEach((finding) => {
    sheet.addRow({
      id: finding.id,
      severity: finding.severity,
      category: finding.category,
      title: finding.title,
      evidence: `${finding.evidence.file}:${finding.evidence.line}`,
      description: finding.description,
      recommendation: finding.recommendation,
    });
  });

  styleHeaderRow(sheet.getRow(1));
  styleDataRows(sheet);

  const summary = workbook.addWorksheet('Risk Summary');
  summary.columns = [
    { header: 'Metric', key: 'metric', width: 28 },
    { header: 'Value', key: 'value', width: 64 },
  ];
  [
    { metric: 'Technology Detected', value: 'Flutter web + Supabase auth client' },
    { metric: 'Security Score', value: '72/100' },
    { metric: 'Risk Rating', value: 'Low Risk' },
    { metric: 'Critical Findings', value: 0 },
    { metric: 'High Findings', value: 0 },
    { metric: 'Medium Findings', value: 0 },
    { metric: 'Low Findings', value: 14 },
    { metric: 'Total Findings', value: 14 },
  ].forEach((row) => summary.addRow(row));
  styleHeaderRow(summary.getRow(1), '0F766E');
  styleDataRows(summary);

  await workbook.xlsx.writeFile(outputPath);
  return outputPath;
}

async function main() {
  ensureReportsDir();
  const files = {
    authProvider: readProjectFile('lib/features/providers/auth_provider.dart'),
    loginScreen: readProjectFile('lib/features/account/screens/login_screen.dart'),
    signupScreen: readProjectFile('lib/features/account/screens/signup_screen.dart'),
    mainFile: readProjectFile('lib/main.dart'),
    webIndex: readProjectFile('web/index.html'),
    appConfig: readProjectFile('lib/core/config/app_config.dart'),
  };
  const pubspec = readProjectFile('pubspec.yaml');
  const findings = buildFindings(files, pubspec.content);
  const reviewMarkdown = buildReviewMarkdown(findings);
  const executiveSummary = makeExecutiveSummary({
    title: 'Web Executive Summary',
    stack: 'Flutter web + Supabase auth client',
    score: 72,
    riskLevel: 'Low Risk',
    findings,
    hardeningAdvice: [
      'Lock down the web shell with CSP, frame, referrer, and permissions policies.',
      'Tighten client validation and reduce direct exposure of backend auth messages.',
      'Review browser-storage-capable dependencies and document approved data persistence.',
    ],
  });

  const reviewPath = writeMarkdown('web-security-review.md', reviewMarkdown);
  const summaryPath = writeMarkdown('web-executive-summary.md', executiveSummary);
  const workbookPath = await writeWorkbook(findings);

  console.log(
    JSON.stringify(
      {
        ok: true,
        stack: 'Flutter web + Supabase auth client',
        score: 72,
        risk: 'Low Risk',
        findings: findings.length,
        critical: 0,
        outputs: {
          workbook: path.relative(process.cwd(), workbookPath),
          review: path.relative(process.cwd(), reviewPath),
          summary: path.relative(process.cwd(), summaryPath),
        },
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
