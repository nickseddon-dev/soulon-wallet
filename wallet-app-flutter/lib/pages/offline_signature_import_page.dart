import 'package:flutter/material.dart';

import '../state/notification_multisig_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class OfflineSignatureImportPage extends StatefulWidget {
  const OfflineSignatureImportPage({
    super.key,
    this.initialTaskId,
  });

  final String? initialTaskId;

  @override
  State<OfflineSignatureImportPage> createState() => _OfflineSignatureImportPageState();
}

class _OfflineSignatureImportPageState extends State<OfflineSignatureImportPage> {
  final MultisigWorkbenchStore _store = MultisigWorkbenchStore.instance;
  final TextEditingController _payloadController = TextEditingController(
    text: 'Carol:0xA91CFD27:E23A99CF81A5B0D923AA\nBob:0x19AC20D1:E23A99CF81A5B0D923AA',
  );
  String? _selectedTaskId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final taskId = widget.initialTaskId;
    if (taskId != null) {
      _selectedTaskId = taskId;
    }
  }

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final taskId = _selectedTaskId;
    setState(() => _errorText = null);
    if (taskId == null || taskId.isEmpty) {
      setState(() => _errorText = '请选择需要导入签名的多签任务');
      return;
    }
    try {
      await _store.importOfflineSignatures(
        taskId: taskId,
        payload: _payloadController.text,
      );
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MultisigWorkbenchState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final tasks = state.tasks;
        MultisigTask? selectedTask;
        if (_selectedTaskId != null) {
          for (final item in tasks) {
            if (item.id == _selectedTaskId) {
              selectedTask = item;
              break;
            }
          }
        }
        final progressText = '${(state.importProgress * 100).toStringAsFixed(0)}%';
        return Scaffold(
          appBar: AppBar(title: const Text('离线签名导入与进度')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '导入设置',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedTaskId),
                      initialValue: _selectedTaskId,
                      items: tasks
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.id} · ${item.title}'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _selectedTaskId = value),
                      decoration: const InputDecoration(labelText: '选择多签任务'),
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '离线签名包（每行 signer:signature:txDigest）',
                      hintText: 'Alice:0x1234ABCD:E23A99...',
                      controller: _payloadController,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(
                      label: '导入并校验签名',
                      loading: state.processing,
                      onPressed: state.processing ? null : _import,
                    ),
                    const SizedBox(height: 8),
                    WalletPrimaryButton(
                      label: '清空导入进度',
                      onPressed: state.processing ? null : _store.clearImportProgress,
                    ),
                  ],
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                ),
              ],
              if (state.noticeText != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.noticeText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.success),
                ),
              ],
              const SizedBox(height: 16),
              WalletCard(
                title: '导入进度',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: state.importProgress.clamp(0, 1)),
                    const SizedBox(height: 8),
                    Text('当前进度: $progressText'),
                    if (state.importLogs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final log in state.importLogs) Text('- $log'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              WalletCard(
                title: '任务签名结果',
                child: selectedTask == null
                    ? const Text('请选择任务后查看导入结果。')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('任务: ${selectedTask.id} ${selectedTask.title}'),
                          Text('M-of-N: ${selectedTask.collectedSigners}/${selectedTask.threshold}'),
                          Text('全量签名人: ${selectedTask.allSigners.join(', ')}'),
                          Text('待签: ${selectedTask.pendingSigners.isEmpty ? '-' : selectedTask.pendingSigners.join(', ')}'),
                          if (selectedTask.onChainTxHash != null) Text('链上 TxHash: ${selectedTask.onChainTxHash}'),
                          const SizedBox(height: 8),
                          if (selectedTask.lastImportEntries.isEmpty)
                            const Text('暂无导入记录。')
                          else
                            for (final entry in selectedTask.lastImportEntries) ...[
                              Text(
                                '${entry.accepted ? '通过' : '拒绝'} · ${entry.signer} · digest=${entry.signatureDigest}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: entry.accepted ? AppColorTokens.success : AppColorTokens.warning,
                                    ),
                              ),
                              Text(entry.message),
                              const SizedBox(height: 6),
                            ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
