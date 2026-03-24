import 'package:flutter/material.dart';

import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class OvdPlaceholderPage extends StatelessWidget {
  const OvdPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
        ),
      ),
    );
  }
}

