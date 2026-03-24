import 'package:flutter/material.dart';

import '../../theme/tokens/app_color_tokens.dart';
import 'replica_settings_widgets.dart';

final class ReplicaAboutPage extends StatelessWidget {
  const ReplicaAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'About',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReplicaSettingsPlaceholderCard(
              title: 'Soulon Wallet',
              description: 'Version 0.1.0+1 (Mock)\nBuild: dev\nChannel: replica',
            ),
            SizedBox(height: 24),
            ReplicaSettingsPlaceholderCard(
              title: 'Links',
              description: 'Docs / Support / Privacy Policy / Terms（占位）',
            ),
            SizedBox(height: 24),
            Text(
              '© 2026 Soulon',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColorTokens.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

