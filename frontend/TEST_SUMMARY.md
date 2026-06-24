# 📊 E2E Test Execution Summary

> [!NOTE]
> This summary is auto-generated from the latest Excel test report.

## 🛠️ Execution Metadata

| Parameter | Value |
|---|---|
| **Application** | Ace Technologies |
| **Base URL** | []() |
| **Start Time** | 2026-06-16T17:56:19.654Z |
| **Generated At** | 2026-06-16T18:19:06.855Z |
| **Browser** |  |
| **Headless Mode** |  |

## 📈 Summary Statistics

| Metric | Count | Percentage |
|---|---|---|
| **Total Planned Cases** | 48 | 100% |
| **Tests Executed** | 48 | 100% |
| **Passed ✅** | 38 | **79%** of executed |
| **Failed ❌** | 10 | 21% of executed |
| **Not Run ⏳** | 0 | 0% |

---

## 📂 Module / Area Breakdown

| Module / Area | Total | Passed | Failed | Pass Rate |
|---|---|---|---|---|
| **Screen Rendering** | 6 | 6 | 0 | ✅ **100%** |
| **Navigation** | 5 | 5 | 0 | ✅ **100%** |
| **Branding** | 1 | 1 | 0 | ✅ **100%** |
| **About Info** | 9 | 4 | 5 | ❌ **44%** |
| **Guest Interface** | 1 | 1 | 0 | ✅ **100%** |
| **Authentication** | 3 | 2 | 1 | ❌ **67%** |
| **Cart empty state** | 1 | 0 | 1 | ❌ **0%** |
| **Touch Targets** | 1 | 1 | 0 | ✅ **100%** |
| **Navigation UI** | 1 | 1 | 0 | ✅ **100%** |
| **Gestures** | 1 | 1 | 0 | ✅ **100%** |
| **Accessibility UI** | 1 | 1 | 0 | ✅ **100%** |
| **Screen Layout** | 3 | 3 | 0 | ✅ **100%** |
| **Screen Stability** | 2 | 2 | 0 | ✅ **100%** |
| **Browse Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Search Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Auth Journey** | 2 | 1 | 1 | ❌ **50%** |
| **Cart Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Product Discovery** | 1 | 1 | 0 | ✅ **100%** |
| **Checkout Journey** | 1 | 0 | 1 | ❌ **0%** |
| **Wishlist Journey** | 1 | 0 | 1 | ❌ **0%** |
| **Service Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Orders Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Product Detail Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Admin Journey** | 1 | 1 | 0 | ✅ **100%** |
| **Settings Journey** | 1 | 1 | 0 | ✅ **100%** |

---

## 🚨 Failed Test Cases (10)

| ID | Module | Route | Scenario / Error | Evidence |
|---|---|---|---|---|
| `AFN-014` | About Info | `/about` | **Scenario:** About Us screen displays details: "Our Philosophy"<br>**Error:** `Expected any of: [Our Philosophy] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-014-failure-1781632805521.png) |
| `AFN-018` | About Info | `/about` | **Scenario:** About Us screen displays details: "HP Compaq"<br>**Error:** `Expected any of: [HP Compaq] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-018-failure-1781632904823.png) |
| `AFN-019` | About Info | `/about` | **Scenario:** About Us screen displays details: "Samsung"<br>**Error:** `Expected any of: [Samsung] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-019-failure-1781632933251.png) |
| `AFN-020` | About Info | `/about` | **Scenario:** About Us screen displays details: "Dahua"<br>**Error:** `Expected any of: [Dahua] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-020-failure-1781632959632.png) |
| `AFN-021` | About Info | `/about` | **Scenario:** About Us screen displays details: "Hikvision"<br>**Error:** `Expected any of: [Hikvision] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-021-failure-1781632985954.png) |
| `AFN-023` | Authentication | `/account` | **Scenario:** Login: submit without inputs triggers validation error<br>**Error:** `Expected any of: [Enter email and password] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-023-failure-1781633016484.png) |
| `AFN-026` | Cart empty state | `/cart` | **Scenario:** Cart screen guest shows empty shopping cart<br>**Error:** `Expected any of: [Shopping Cart \| Your cart is empty] to be visible on the screen.` | [Screenshot](reports/evidence/AFN-026-failure-1781633088219.png) |
| `AE2E-003` | Auth Journey | `/account` | **Scenario:** E2E: User visits account, sees login form, attempts login, sees validation<br>**Error:** `Expected any of: [Enter email and password] to be visible on the screen.` | [Screenshot](reports/evidence/AE2E-003-failure-1781633431748.png) |
| `AE2E-007` | Checkout Journey | `/checkout` | **Scenario:** E2E: Guest user accesses checkout address and payment details<br>**Error:** `Expected any of: [Address \| Select Address] to be visible on the screen.` | [Screenshot](reports/evidence/AE2E-007-failure-1781633599782.png) |
| `AE2E-008` | Wishlist Journey | `/wishlist` | **Scenario:** E2E: User views wishlist and compare page<br>**Error:** `Expected any of: [Compare Products \| Compare] to be visible on the screen.` | [Screenshot](reports/evidence/AE2E-008-failure-1781633678701.png) |

---
*Summary generated on: 2026-06-16T18:19:07.421Z*
