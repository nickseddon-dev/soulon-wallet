import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_import_store.dart';
import 'replica_import_widgets.dart';

final class ReplicaImportMnemonicPage extends StatefulWidget {
  const ReplicaImportMnemonicPage({super.key});

  @override
  State<ReplicaImportMnemonicPage> createState() => _ReplicaImportMnemonicPageState();
}

class _ReplicaImportMnemonicPageState extends State<ReplicaImportMnemonicPage> {
  final List<TextEditingController> _controllers = List.generate(24, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int _wordCount(ReplicaImportStore store) => store.use24Words ? 24 : 12;

  bool _canImport(ReplicaImportStore store) {
    final count = _wordCount(store);
    for (var i = 0; i < count; i++) {
      if (_controllers[i].text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _paste(ReplicaImportStore store) async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) return;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList(growable: false);
    if (words.length != 12 && words.length != 24) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('助记词数量需为 12 或 24')));
      return;
    }
    store.setUse24Words(words.length == 24);
    for (var i = 0; i < 24; i++) {
      _controllers[i].text = i < words.length ? words[i] : '';
    }
    setState(() {});
  }

  void _import() {
    Navigator.pushNamed(context, WalletRoutes.replicaImportDiscovering);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReplicaImportProvider.of(context);
    final count = _wordCount(store);

    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ReplicaProgressDots(total: 8, currentIndex: 3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacingTokens.sm),
              const Text(
                '密钥恢复短语',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColorTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.sm),
              Text(
                '输入 或粘贴您的助记词',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          store.setUse24Words(!store.use24Words);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorTokens.surface,
                          foregroundColor: AppColorTokens.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                          elevation: 0,
                        ),
                        child: Text(store.use24Words ? '使用12个助记词' : '使用24个助记词', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _paste(store),
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('从剪贴板粘贴', style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorTokens.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              Expanded(
                child: _MnemonicGrid(
                  count: count,
                  controllers: _controllers,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canImport(store) ? _import : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.surfaceSubtle,
                    foregroundColor: AppColorTokens.textPrimary,
                    disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                    disabledForegroundColor: AppColorTokens.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('导入', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.sm),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MnemonicGrid extends StatelessWidget {
  const _MnemonicGrid({
    required this.count,
    required this.controllers,
    required this.onChanged,
  });

  final int count;
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = 3;
        final itemWidth = (constraints.maxWidth - (columns - 1) * AppSpacingTokens.md) / columns;
        return SingleChildScrollView(
          child: Wrap(
            spacing: AppSpacingTokens.md,
            runSpacing: AppSpacingTokens.md,
            children: List.generate(count, (index) {
              return SizedBox(
                width: itemWidth,
                child: _WordBox(
                  index: index + 1,
                  controller: controllers[index],
                  onChanged: onChanged,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

final class _WordBox extends StatelessWidget {
  const _WordBox({
    required this.index,
    required this.controller,
    required this.onChanged,
  });

  final int index;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Text('$index', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

