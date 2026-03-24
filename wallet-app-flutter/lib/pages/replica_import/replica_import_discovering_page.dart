import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_import_widgets.dart';

final class ReplicaImportDiscoveringPage extends StatefulWidget {
  const ReplicaImportDiscoveringPage({super.key});

  @override
  State<ReplicaImportDiscoveringPage> createState() => _ReplicaImportDiscoveringPageState();
}

class _ReplicaImportDiscoveringPageState extends State<ReplicaImportDiscoveringPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, WalletRoutes.replicaImportAccounts);
  }

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
        title: const ReplicaProgressDots(total: 8, currentIndex: 4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColorTokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorTokens.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.backpack_rounded, color: AppColorTokens.danger, size: 40),
                  ),
                ),
                const SizedBox(height: AppSpacingTokens.xl),
                const Text(
                  '正在查找已有资产的账户…',
                  style: TextStyle(
                    fontFamily: AppTypographyTokens.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColorTokens.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacingTokens.lg),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColorTokens.accent),
                    backgroundColor: AppColorTokens.surfaceSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

