# Ace Technologies – Selenium Test Suite

Comprehensive automated testing framework for the **Ace Technologies** Flutter web application.

## 📁 Folder Structure

```
selenium_tests/
├── runner.js                  # Main test orchestrator
├── package.json               # Node.js dependencies
├── .env.example               # Environment variable template
├── config/
│   └── test-config.js         # Central configuration (URLs, timeouts, viewports)
├── utils/
│   ├── driver-helpers.js      # Shared Selenium utilities & helpers
│   └── report-generator.js    # Excel (.xlsx) report generator
└── suites/
    ├── 01-functional.js       # 1. Functional Testing
    ├── 02-ui-ux.js            # 2. UI/UX Testing
    ├── 03-compatibility.js    # 3. Compatibility Testing
    ├── 04-performance.js      # 4. Performance Testing
    ├── 05-security.js         # 5. Security Testing
    ├── 06-api.js              # 6. API Testing
    ├── 07-database.js         # 7. Database Testing
    ├── 08-accessibility.js    # 8. Accessibility Testing
    ├── 09-mobile.js           # 9. Mobile-Specific Testing
    ├── 10-regression.js       # 10. Regression Testing
    └── 11-e2e.js              # 11. End-to-End (E2E) Testing
```

Reports are saved to: `../reports/` (relative to `selenium_tests/`)

## ⚙️ Prerequisites

| Requirement | Version |
|---|---|
| Node.js | ≥ 18.0 |
| Google Chrome | Latest |
| ChromeDriver | Must match Chrome version |
| Flutter Web Build | `flutter build web` (for local testing) |

### Install ChromeDriver

```powershell
# Option 1: Using npm (auto-matches Chrome)
npm install -g chromedriver

# Option 2: Manual download from
# https://chromedriver.chromium.org/downloads
```

## 🚀 Quick Start

### 1. Install dependencies

```powershell
cd selenium_tests
npm install
```

### 2. Configure environment

```powershell
copy .env.example .env
# Edit .env with your values
```

### 3. Build the Flutter web app

```powershell
cd ..
flutter build web
cd selenium_tests
```

### 4. Run all tests

```powershell
npm test
# or
node runner.js
```

## 📋 Running Specific Suites

```powershell
# Run all suites
node runner.js

# Individual suites
npm run test:functional      # Functional Testing
npm run test:ui              # UI/UX Testing
npm run test:compatibility   # Compatibility Testing
npm run test:performance     # Performance Testing
npm run test:security        # Security Testing
npm run test:api             # API Testing
npm run test:database        # Database Testing
npm run test:accessibility   # Accessibility Testing
npm run test:mobile          # Mobile-Specific Testing
npm run test:regression      # Regression Testing
npm run test:e2e             # End-to-End Testing

# Run with visible browser (not headless)
npm run test:headed
```

## 🌐 Testing Against a Live URL

```powershell
# Set E2E_BASE_URL to your deployed app URL
$env:E2E_BASE_URL = "https://your-app.vercel.app/"
node runner.js
```

## 📊 Test Report

The Excel report is saved to `../reports/` as:
```
Ace_Technologies_TestReport_<timestamp>.xlsx
```

### Report Sheets

| Sheet | Description |
|---|---|
| **Dashboard** | Executive summary with pass/fail counts |
| **All Test Results** | Full test results with all columns |
| **Functional Testing** | Functional suite results |
| **UI/UX Testing** | UI/UX suite results |
| **Compatibility Testing** | Cross-browser/viewport results |
| **Performance Testing** | Performance metrics |
| **Security Testing** | Security check results |
| **API Testing** | API endpoint test results |
| **Database Testing** | DB integration results |
| **Accessibility Testing** | WCAG compliance results |
| **Mobile-Specific Testing** | Mobile layout results |
| **Regression Testing** | Regression test results |
| **End-to-End (E2E) Testing** | Full user journey results |
| **Coverage Matrix** | All cases with NOT RUN status |
| **Failures** | Detailed failure breakdown with evidence paths |
| **Performance Summary** | Performance-specific metrics |

Evidence screenshots on failure: `../reports/evidence/`

## 🔧 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `E2E_BASE_URL` | `http://127.0.0.1:4173/` | App base URL |
| `HEADLESS` | `true` | Run Chrome headlessly |
| `E2E_TIMEOUT_MS` | `15000` | Assertion timeout (ms) |
| `SUPABASE_URL` | _(empty)_ | Supabase project URL |
| `SUPABASE_ANON_KEY` | _(empty)_ | Supabase anon key |
| `TEST_EMAIL` | `test@acetechnologies.com` | Test user email |
| `TEST_PASSWORD` | `Test@123456` | Test user password |
| `ADMIN_EMAIL` | `admin@acetechnologies.com` | Admin test email |

## 🧪 Test Suites Overview

### 1. Functional Testing (~70 tests)
- Page rendering for all 23 routes
- Navigation flows
- Form validation (login, signup)
- URL parameter handling
- Browser refresh stability

### 2. UI/UX Testing (~35 tests)
- Loading spinner lifecycle
- Viewport meta tags
- Canvas/Flutter rendering detection
- Navigation UI at different sizes
- Horizontal overflow detection

### 3. Compatibility Testing (~80 tests)
- 13 different viewport sizes × 5 routes
- Portrait/Landscape orientation switching
- PWA manifest and service worker
- Mixed content checks

### 4. Performance Testing (~20 tests)
- Page load time thresholds
- TTFB measurements
- Memory usage
- Resource count
- Transfer size

### 5. Security Testing (~25 tests)
- XSS prevention (5 payloads)
- Open redirect prevention
- Auth-protected route checks
- Sensitive data exposure
- SQL injection resistance
- Path traversal handling

### 6. API Testing (~15 tests)
- Static server health
- Supabase REST endpoints
- Auth validation
- Row Level Security (RLS)
- Third-party API reachability

### 7. Database Testing (~15 tests)
- UI data reflection
- localStorage security
- Schema validation
- Pagination support

### 8. Accessibility Testing (~20 tests)
- ARIA roles & semantics
- Keyboard navigation
- Focus visibility
- Color contrast
- Flutter semantics tree

### 9. Mobile-Specific Testing (~50 tests)
- 5 mobile viewports × 6 routes
- Touch target sizes
- Bottom navigation
- Landscape orientation
- Mobile form usability

### 10. Regression Testing (~50 tests)
- All critical routes
- Navigation chain
- Performance baseline
- JS error monitoring

### 11. End-to-End Testing (~20 tests)
- 20 complete user journeys
- Browse → Products → Account flow
- Cart and checkout flow
- Service booking flow
- Admin flow
- SPA routing validation

## 🚨 Troubleshooting

### ChromeDriver version mismatch
```powershell
# Check Chrome version
(Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo.FileVersion

# Install matching chromedriver
npm install chromedriver@<major-version>
```

### No build/web directory
```powershell
flutter build web
```

### Tests timing out
```powershell
$env:E2E_TIMEOUT_MS = "20000"
node runner.js
```

### Running on CI/CD
```yaml
# GitHub Actions example
- run: |
    cd selenium_tests
    npm install
    E2E_BASE_URL=https://your-app.vercel.app/ node runner.js
```
