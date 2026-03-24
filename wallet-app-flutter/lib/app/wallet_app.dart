import 'package:flutter/material.dart';

import 'app_router.dart';
import '../theme/app_theme.dart';

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soulon Wallet',
      theme: AppTheme.dark(),
      initialRoute: WalletRoutes.ovdAuthLogin,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
