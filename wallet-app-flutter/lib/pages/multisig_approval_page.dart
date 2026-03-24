import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/notification_multisig_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class MultisigApprovalPage extends StatefulWidget {
  const MultisigApprovalPage({super.key});

  @override
  State<MultisigApprovalPage> createState() => _MultisigApprovalPageState();
}

class _MultisigApprovalPageState extends State<MultisigApprovalPage> {
  final MultisigWorkbenchStore _store = MultisigWorkbenchStore.instance;
  String? _errorText;

  String _statusLabel(MultisigTaskStatus status) {
    switch (status) {
      case MultisigTaskStatus.pending:
        return '待审批';
      case MultisigTaskStatus.approving:
        return '审批中';
      case MultisigTaskStatus.ready:
        return '可提交';
      case MultisigTaskStatus.submitting:
        return '提交中';
      case MultisigTaskStatus.submitted:
        return '已提交待确认';
      case MultisigTaskStatus.confirmed:
        return '已链上确认';
      case MultisigTaskStatus.rejected:
        return '已驳回';
    }
  }

  Color _statusColor(MultisigTaskStatus status) {
    switch (status) {
      case MultisigTaskStatus.pending:
        return AppColorTokens.warning;
      case MultisigTaskStatus.approving:
        return AppColorTokens.primary;
      case MultisigTaskStatus.ready:
        return AppColorTokens.success;
      case MultisigTaskStatus.submitting:
        return AppColorTokens.primary;
      case MultisigTaskStatus.submitted:
        return AppColorTokens.warning;
      case MultisigTaskStatus.confirmed:
        return AppColorTokens.success;
      case MultisigTaskStatus.rejected:
        return AppColorTokens.danger;
    }
  }

  Future<void> _approve(String taskId, String signer) async {
    setState(() => _errorText = null);
    try {
      await _store.approveTask(taskId, signer);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  Future<void> _reject(String taskId, String signer) async {
    setState(() => _errorText = null);
    try {
      await _store.rejectTask(taskId, signer);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  Future<void> _submitOnChain(String taskId) async {
    setState(() => _errorText = null);
    try {
      await _store.submitTaskOnChain(taskId);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MultisigWorkbenchState>(
      valueListenable: _store,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('多签任务审批工作台')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '审批概览',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('任务数: ${state.tasks.length}'),
                    Text('处理中: ${state.processing ? '是' : '否'}'),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(
                      label: '前往离线签名导入',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        WalletRoutes.offlineSignatureImport,
                      ),
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
              for (final task in state.tasks) ...[
                WalletCard(
                  title: '${task.title} (${task.id})',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      const SizedBox(height: 8),
                      Text('交易摘要: ${task.txDigest}'),
                      Text('更新时间: ${task.updatedAt.toIso8601String()}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: task.progress.clamp(0, 1)),
                      const SizedBox(height: 6),
                      Text('M-of-N: ${task.collectedSigners}/${task.threshold}（总签名人 ${task.totalSigners}）'),
                      Text('剩余签名: ${task.requiredSignatures}'),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_statusLabel(task.status)),
                        avatar: Icon(Icons.flag_rounded, color: _statusColor(task.status), size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('已签: ${task.approvedSigners.isEmpty ? '-' : task.approvedSigners.join(', ')}'),
                      Text('待签: ${task.pendingSigners.isEmpty ? '-' : task.pendingSigners.join(', ')}'),
                      if (task.onChainTxHash != null) Text('链上 TxHash: ${task.onChainTxHash}'),
                      if (task.onChainHeight != null) Text('链上高度: ${task.onChainHeight}'),
                      if (task.submittedAt != null) Text('提交时间: ${task.submittedAt!.toIso8601String()}'),
                      if (task.pendingSigners.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final signer in task.pendingSigners)
                              SizedBox(
                                width: 180,
                                child: WalletPrimaryButton(
                                  label: '批准: $signer',
                                  loading: state.processing,
                                  onPressed: state.processing ? null : () => _approve(task.id, signer),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 200,
                          child: WalletPrimaryButton(
                            label: '驳回任务',
                            onPressed: state.processing
                                ? null
                                : () => _reject(task.id, task.pendingSigners.first),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      WalletPrimaryButton(
                        label: '导入该任务离线签名',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          WalletRoutes.offlineSignatureImport,
                          arguments: task.id,
                        ),
                      ),
                      if (task.status == MultisigTaskStatus.ready || task.status == MultisigTaskStatus.submitted) ...[
                        const SizedBox(height: 8),
                        WalletPrimaryButton(
                          label: '提交链上并回写审批',
                          loading: state.processing || task.status == MultisigTaskStatus.submitting,
                          onPressed: state.processing ? null : () => _submitOnChain(task.id),
                        ),
                      ],
                      if (task.approvalLogs.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('审批回写日志'),
                        const SizedBox(height: 6),
                        for (final log in task.approvalLogs.take(4)) Text('- $log'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}
