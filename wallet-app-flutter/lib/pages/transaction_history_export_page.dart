import 'package:flutter/material.dart';

import '../state/transaction_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/dialogs/wallet_alert_dialog.dart';

class TransactionHistoryExportPage extends StatefulWidget {
  const TransactionHistoryExportPage({super.key});

  @override
  State<TransactionHistoryExportPage> createState() => _TransactionHistoryExportPageState();
}

class _TransactionHistoryExportPageState extends State<TransactionHistoryExportPage> {
  final TransactionDemoStore _store = TransactionDemoStore.instance;
  String? _errorText;

  Future<void> _export(ExportFormat format) async {
    setState(() => _errorText = null);
    try {
      final result = _store.exportHistory(format);
      await WalletAlertDialog.show(
        context,
        title: '导出成功',
        message:
            '格式：${_formatText(result.format)}\n文件：${result.fileName}\n记录数：${result.recordCount}\n大小：${result.bytes} bytes',
      );
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TransactionDemoState>(
      valueListenable: _store,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('交易历史导出')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '交易历史',
                trailing: Text(
                  '${state.history.length} 条',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColorTokens.accent),
                ),
                child: Column(
                  children: [
                    for (final item in state.history) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColorTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.type,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Chip(label: Text(item.status)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('金额：${item.amount}'),
                            Text('目标：${item.toAddress}'),
                            Text('TxHash：${item.txHash.substring(0, 20)}...'),
                            Text('时间：${item.timestamp.toIso8601String()}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '导出交易历史',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletPrimaryButton(label: '导出 CSV', onPressed: () => _export(ExportFormat.csv)),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(label: '导出 PDF', onPressed: () => _export(ExportFormat.pdf)),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(label: '导出 JSON', onPressed: () => _export(ExportFormat.json)),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                  ],
                ),
              ),
              if (state.exportResult != null) ...[
                const SizedBox(height: 16),
                WalletCard(
                  title: '导出结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('格式：${_formatText(state.exportResult!.format)}'),
                      Text('文件名：${state.exportResult!.fileName}'),
                      Text('记录数：${state.exportResult!.recordCount}'),
                      Text('文件大小：${state.exportResult!.bytes} bytes'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatText(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.json:
        return 'JSON';
    }
  }
}
