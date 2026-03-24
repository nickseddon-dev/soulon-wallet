import 'package:flutter/material.dart';

import '../buttons/wallet_primary_button.dart';

final class WalletAlertDialog {
  const WalletAlertDialog._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String actionText = '知道了',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            SizedBox(
              width: 120,
              child: WalletPrimaryButton(
                label: actionText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}
