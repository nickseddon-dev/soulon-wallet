import 'package:flutter/material.dart';

import 'router_config.dart';
import '../theme/app_theme.dart';

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Soulon Wallet',
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
