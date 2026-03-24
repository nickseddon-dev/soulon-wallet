import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/app/wallet_app.dart';

void main() {
  testWidgets('wallet app renders onboarding entry', (tester) async {
    await tester.pumpWidget(const WalletApp());
    expect(find.text('Welcome to Soulon'), findsOneWidget);
    expect(find.text('Create a new wallet'), findsOneWidget);
    expect(find.text('Import Wallet'), findsOneWidget);
  });
}
