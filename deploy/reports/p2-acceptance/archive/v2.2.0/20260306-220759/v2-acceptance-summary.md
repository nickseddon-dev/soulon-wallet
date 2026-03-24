# V2 Acceptance Summary

- generatedAt: 2026-03-06T22:08:45.8565000+08:00
- templateVersion: v2
- milestone: Wallet-Production-Architecture
- version: v2.2.0
- overallStatus: fail
- totalModules: 3
- failedModules: 1
- totalGates: 7
- failedGates: 1
- archivePath: D:\soulon_wallet\deploy\reports\p2-acceptance\archive\v2.2.0\20260306-220759

## Module Status

| module | status | passedGates | failedGates |
|---|---|---:|---:|
| soulon-backend | pass | 2 | 0 |
| wallet-app-flutter | fail | 1 | 1 |
| soulon-wallet | pass | 3 | 0 |

## Gate Details

| module | gate | status | exitCode | durationMs |
|---|---|---|---:|---:|
| soulon-backend | go_test | pass | 0 | 2098 |
| soulon-backend | perf_baseline_rollback | pass | 0 | 1085 |
| wallet-app-flutter | flutter_analyze | fail | 1 | 16157 |
| wallet-app-flutter | flutter_test | pass | 0 | 7111 |
| soulon-wallet | check | pass | 0 | 3097 |
| soulon-wallet | test_unit | pass | 0 | 5096 |
| soulon-wallet | e2e_regression | pass | 0 | 11127 |

## Failure Details

### wallet-app-flutter / flutter_analyze
- command: flutter analyze
- exitCode: 1
- stdoutLog: D:\soulon_wallet\deploy\reports\p2-acceptance\archive\v2.2.0\20260306-220759\logs\wallet-app-flutter-flutter_analyze-stdout.log
- stderrLog: D:\soulon_wallet\deploy\reports\p2-acceptance\archive\v2.2.0\20260306-220759\logs\wallet-app-flutter-flutter_analyze-stderr.log
- stdoutTail:
```
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\governance_vote_page.dart:129:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\ibc_transfer_tracking_page.dart:78:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\ibc_transfer_tracking_page.dart:98:23 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\pages\identity_backup_verify_page.dart:167:15 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\pages\identity_backup_verify_page.dart:169:24 - prefer_const_constructors
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\pages\identity_backup_verify_page.dart:201:22 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\pages\motion_showcase_page.dart:34:66 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\pages\notification_center_page.dart:60:21 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\pages\notification_center_page.dart:61:21 - prefer_const_constructors
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\offline_signature_import_page.dart:88:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\pin_biometric_confirm_page.dart:74:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\pin_biometric_confirm_page.dart:110:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\staking_flow_page.dart:75:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\staking_flow_page.dart:92:23 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\pages\staking_flow_page.dart:111:25 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\pages\walletconnect_session_page.dart:57:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\pages\walletconnect_session_page.dart:58:27 - prefer_const_constructors
warning - The value of the field '_random' isn't used - lib\state\security_interop_demo_store.dart:386:16 - unused_field
   info - Use 'const' for final variables initialized to a constant value - lib\state\transaction_demo_store.dart:758:9 - prefer_const_declarations

```
- stderrTail:
```
19 issues found. (ran in 12.5s)
```

