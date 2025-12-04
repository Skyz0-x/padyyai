# Software Test Documentation - PaddyAI Application

## Document Information
- **Project Name**: PaddyAI - Paddy Farming Assistant
- **Document Version**: 1.0
- **Date**: December 4, 2025
- **Prepared By**: Development Team

---

## Table of Contents
1. [Introduction](#introduction)
2. [Test Objectives](#test-objectives)
3. [Test Scope](#test-scope)
4. [Test Environment](#test-environment)
5. [Test Cases Overview](#test-cases-overview)
6. [Test Execution](#test-execution)
7. [Test Results](#test-results)
8. [Appendix](#appendix)

---

## 1. Introduction

### 1.1 Purpose
This document describes the testing approach, test cases, and results for the PaddyAI mobile application. The purpose is to ensure all critical functionalities work as expected and meet the specified requirements.

### 1.2 Project Overview
PaddyAI is a comprehensive farming assistant application designed to help farmers with:
- Disease detection using AI/ML
- Weather monitoring and alerts
- Farming calendar and reminders
- Marketplace for agricultural supplies
- Order management
- Expert chatbot assistance

---

## 2. Test Objectives

The main objectives of testing are:
1. Verify all core functionalities work correctly
2. Ensure data validation and business logic accuracy
3. Validate UI components render and behave as expected
4. Test integration between different modules
5. Ensure application stability and performance
6. Validate error handling and edge cases

---

## 3. Test Scope

### 3.1 In Scope
- ✅ Unit tests for utility functions
- ✅ Widget tests for UI components
- ✅ Business logic validation tests
- ✅ Service layer tests
- ✅ Data validation tests
- ✅ Navigation flow tests

### 3.2 Out of Scope
- ❌ Performance/Load testing
- ❌ Security penetration testing
- ❌ Third-party API testing (Supabase, Weather API)
- ❌ Device-specific compatibility testing
- ❌ Network failure scenarios

---

## 4. Test Environment

### 4.1 Software Environment
- **Framework**: Flutter 3.32.5
- **Dart SDK**: 3.8.1
- **Testing Framework**: flutter_test
- **OS**: Windows, Android, iOS

### 4.2 Test Tools
- Flutter Test Runner
- VS Code / Android Studio
- Git for version control

---

## 5. Test Cases Overview

### 5.1 Test Files Structure
```
test/
├── app_test.dart                          # Main app widget tests
├── services/
│   └── weather_service_test.dart         # Weather service unit tests
├── utils/
│   └── validation_test.dart              # Validation & utility tests
├── widgets/
│   └── widget_test.dart                  # UI component tests
└── logic/
    └── business_logic_test.dart          # Business logic tests
```

### 5.2 Test Categories

#### A. Application Structure Tests (app_test.dart)
**Purpose**: Verify main application structure and rendering

| Test ID | Test Case | Expected Result |
|---------|-----------|-----------------|
| APP-001 | App renders MaterialApp widget | MaterialApp widget found |
| APP-002 | App has expected widget structure | Scaffold and AppBar present |
| APP-003 | App contains expected text elements | "PaddyAI" text displayed |

**Total Test Cases**: 3

---

#### B. Weather Service Tests (services/weather_service_test.dart)
**Purpose**: Validate weather service functionality

| Test ID | Test Case | Expected Result |
|---------|-----------|-----------------|
| WS-001 | Weather description for clear sky (code 0) | Returns "Clear sky" |
| WS-002 | Weather description for partly cloudy (1-3) | Returns "Partly cloudy" |
| WS-003 | Weather description for fog (45,48) | Returns "Foggy" |
| WS-004 | Weather description for rain (61-65) | Returns "Rain" |
| WS-005 | Weather icon for clear sky | Returns ☀️ |
| WS-006 | Weather icon for rain | Returns 🌧️ |
| WS-007 | Weather icon for snow | Returns ❄️ |
| WS-008 | Heat alert for temperature > 35°C | Alert type='heat', severity='high' |
| WS-009 | Rain alert for precipitation > 10mm | Alert type='rain' present |
| WS-010 | Wind alert for speed > 30 km/h | Alert type='wind' present |
| WS-011 | Drought alert for humidity < 30% | Alert type='drought' present |
| WS-012 | No alerts for normal conditions | Empty alerts list |
| WS-013 | Cache clear functionality | Cache cleared successfully |

**Total Test Cases**: 13

---

#### C. Validation & Utility Tests (utils/validation_test.dart)
**Purpose**: Test input validation and utility functions

| Test ID | Test Case | Expected Result |
|---------|-----------|-----------------|
| VAL-001 | Valid email format validation | Regex matches valid emails |
| VAL-002 | Invalid email format rejection | Regex rejects invalid emails |
| VAL-003 | Email trimming and lowercasing | Normalized email string |
| VAL-004 | Valid Malaysian phone number | Regex matches valid formats |
| VAL-005 | Invalid phone number rejection | Regex rejects invalid formats |
| VAL-006 | String capitalization | First letter uppercase |
| VAL-007 | String truncation | Truncates with ellipsis |
| VAL-008 | HTML/SQL injection sanitization | Special chars escaped |
| VAL-009 | Date formatting | Correct ISO format |
| VAL-010 | Date comparison | Before/after/same moment |
| VAL-011 | Number parsing validation | Valid/invalid number parsing |
| VAL-012 | Price formatting | "RM XX.XX" format |
| VAL-013 | List filtering | Correct filtered results |
| VAL-014 | Map operations | Key existence, value access |
| VAL-015 | Boolean logic operations | AND, OR, NOT work correctly |

**Total Test Cases**: 15

---

#### D. Widget Component Tests (widgets/widget_test.dart)
**Purpose**: Validate UI component behavior

| Test ID | Test Case | Expected Result |
|---------|-----------|-----------------|
| WDG-001 | ElevatedButton renders with text | Button displays text |
| WDG-002 | Button onPressed callback | Callback triggered on tap |
| WDG-003 | Disabled button behavior | onPressed not called when null |
| WDG-004 | TextField accepts input | Text controller updated |
| WDG-005 | TextField shows hint text | Hint text visible |
| WDG-006 | Password TextField obscures text | obscureText=true |
| WDG-007 | Card widget renders child | Card with content visible |
| WDG-008 | Card has elevation | Elevation property set |
| WDG-009 | ListView displays items | All list items rendered |
| WDG-010 | ListView scrolling | Scroll reveals hidden items |
| WDG-011 | Checkbox state toggle | Checked state changes |
| WDG-012 | Switch toggle behavior | Switch value changes |
| WDG-013 | DropdownButton shows options | Dropdown items visible |
| WDG-014 | Icon renders correctly | Icon with correct properties |
| WDG-015 | Scaffold structure | AppBar and Body present |
| WDG-016 | SnackBar display | SnackBar message shown |
| WDG-017 | Navigation push | New route pushed |
| WDG-018 | Back button navigation | Route popped correctly |

**Total Test Cases**: 18

---

#### E. Business Logic Tests (logic/business_logic_test.dart)
**Purpose**: Validate business calculations and logic

| Test ID | Test Case | Expected Result |
|---------|-----------|-----------------|
| BIZ-001 | Price calculation with quantity | Correct total price |
| BIZ-002 | Cart subtotal calculation | Sum of all items |
| BIZ-003 | Tax amount calculation | Correct tax amount (6%) |
| BIZ-004 | Final total with tax & shipping | Accurate grand total |
| BIZ-005 | Percentage discount calculation | Correct discount amount |
| BIZ-006 | Price after discount | Discounted price accurate |
| BIZ-007 | Bulk discount tiers | Correct tier-based discount |
| BIZ-008 | Stock availability check | In stock / out of stock |
| BIZ-009 | Restock threshold check | Needs restock alert |
| BIZ-010 | Stock update after purchase | Reduced stock count |
| BIZ-011 | Order status progression | Next status correct |
| BIZ-012 | Order cancellation validation | Can/cannot cancel |
| BIZ-013 | Delivery date estimation | Correct future date |
| BIZ-014 | Growth days calculation | Days between dates |
| BIZ-015 | Fertilization schedule dates | Correct schedule dates |
| BIZ-016 | Fertilization due check | Is/isn't due |
| BIZ-017 | Paddy growth stage | Correct stage by days |
| BIZ-018 | Harvest date estimation | Average of min-max days |
| BIZ-019 | Average rating calculation | Correct average |
| BIZ-020 | Rating distribution count | Correct counts per rating |
| BIZ-021 | Product filtering by category | Filtered list correct |
| BIZ-022 | Product search by name | Search results accurate |
| BIZ-023 | Product sorting by price | Sorted order correct |

**Total Test Cases**: 23

---

## 6. Test Execution

### 6.1 How to Run Tests

#### Run All Tests
```bash
flutter test
```

#### Run Specific Test File
```bash
flutter test test/app_test.dart
flutter test test/services/weather_service_test.dart
flutter test test/utils/validation_test.dart
flutter test test/widgets/widget_test.dart
flutter test test/logic/business_logic_test.dart
```

#### Run Tests with Coverage
```bash
flutter test --coverage
```

#### Run Tests with Verbose Output
```bash
flutter test --verbose
```

### 6.2 Test Execution Schedule
- **Unit Tests**: Run on every code commit
- **Widget Tests**: Run before each pull request
- **Full Test Suite**: Run before production deployment

---

## 7. Test Results

### 7.1 Summary

| Test Category | Total Tests | Passed | Failed | Pass Rate |
|--------------|-------------|---------|---------|-----------|
| App Structure | 3 | 3 | 0 | 100% |
| Weather Service | 13 | TBD | TBD | TBD |
| Validation & Utils | 15 | TBD | TBD | TBD |
| Widget Components | 18 | TBD | TBD | TBD |
| Business Logic | 23 | TBD | TBD | TBD |
| **TOTAL** | **72** | **TBD** | **TBD** | **TBD** |

### 7.2 Test Coverage
- **Target Coverage**: 80%
- **Current Coverage**: TBD (run with --coverage flag)

### 7.3 Known Issues
*To be documented after test execution*

### 7.4 Defects Found
*To be documented after test execution*

---

## 8. Appendix

### 8.1 Test Data

#### Sample User Data
```dart
{
  'email': 'farmer@test.com',
  'password': 'Test123!',
  'full_name': 'Test Farmer',
  'phone': '0123456789',
  'role': 'farmer'
}
```

#### Sample Weather Data
```dart
{
  'current': {
    'temperature_2m': 30.0,
    'relative_humidity_2m': 70,
    'precipitation': 0,
    'wind_speed_10m': 15,
    'weather_code': 0
  }
}
```

#### Sample Cart Item
```dart
{
  'product_id': '123',
  'name': 'NPK Fertilizer',
  'price': 50.00,
  'quantity': 2,
  'category': 'fertilizer'
}
```

### 8.2 Test Metrics

#### Code Quality Metrics
- **Cyclomatic Complexity**: Target < 10
- **Code Coverage**: Target > 80%
- **Maintainability Index**: Target > 70

#### Performance Metrics
- **Widget Build Time**: < 100ms
- **Test Execution Time**: < 5 minutes for full suite

### 8.3 References
- Flutter Testing Documentation: https://docs.flutter.dev/testing
- Dart Testing Best Practices: https://dart.dev/guides/testing
- PaddyAI Project Repository: [GitHub Link]

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-04 | Dev Team | Initial test documentation |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Test Lead | ___________ | ___________ | _____ |
| Developer | ___________ | ___________ | _____ |
| Project Manager | ___________ | ___________ | _____ |

---

**END OF DOCUMENT**
