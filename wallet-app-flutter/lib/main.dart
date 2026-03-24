import 'package:flutter/material.dart';

import 'app/wallet_app.dart';
import 'di/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const WalletApp());
}
