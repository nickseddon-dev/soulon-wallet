import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_app_flutter/app/wallet_app.dart';

void main() {
  testWidgets('WalletApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WalletApp());
    await tester.pumpAndSettle();
    expect(find.text('登录'), findsWidgets);
  });
}
