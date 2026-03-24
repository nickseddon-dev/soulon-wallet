import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/transaction_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class TransactionFlowPage extends StatefulWidget {
  const TransactionFlowPage({super.key});

  @override
  State<TransactionFlowPage> createState() => _TransactionFlowPageState();
}

class _TransactionFlowPageState extends State<TransactionFlowPage> {
  final TransactionDemoStore _store = TransactionDemoStore.instance;
  final TransferFormDraftBridge _draftBridge = TransferFormDraftBridge.instance;
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '1.00');
  final TextEditingController _memoController = TextEditingController(text: 'wallet-ui-demo');
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _draftBridge.addListener(_applyDraftFromBridge);
    _applyDraftFromBridge();
  }

  @override
  void dispose() {
    _draftBridge.removeListener(_applyDraftFromBridge);
    _recipientController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _runFlow() async {
    setState(() => _errorText = null);
    try {
      await _store.runTransferFlow(
        recipientAddress: _recipientController.text,
        amountText: _amountController.text,
        memo: _memoController.text,
      );
      if (mounted) {
        setState(() => _errorText = null);
      }
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
          appBar: AppBar(title: const Text('交易构建仿真签名广播')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '交易输入',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletTextField(
                      label: '收款地址',
                      hintText: 'cosmos1...',
                      controller: _recipientController,
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '金额（SOUL）',
                      hintText: '1.00',
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: 'Memo',
                      hintText: '可选备注',
                      controller: _memoController,
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '执行构建→仿真→签名→广播',
                      loading: state.loading,
                      onPressed: state.loading ? null : _runFlow,
                    ),
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
              const SizedBox(height: 16),
              WalletCard(
                title: '流程状态',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _stageChip('构建', state.buildResult != null),
                    _stageChip('仿真', state.simulationResult != null),
                    _stageChip('签名', state.signResult != null),
                    _stageChip('广播', state.broadcastResult != null),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.buildResult != null) ...[
                WalletCard(
                  title: '构建结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('accountNumber: ${state.buildResult!.accountNumber}'),
                      Text('sequence: ${state.buildResult!.sequence}'),
                      Text('memo: ${state.buildResult!.memo.isEmpty ? '-' : state.buildResult!.memo}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (state.simulationResult != null) ...[
                WalletCard(
                  title: '仿真结果与费率建议',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('gasUsed: ${state.simulationResult!.gasUsed}'),
                      const SizedBox(height: 8),
                      for (final fee in state.simulationResult!.feeSuggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${fee.label}档：${fee.gasPrice}，预估手续费 ${fee.estimatedFee}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (state.signResult != null) ...[
                WalletCard(
                  title: '签名结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('签名地址: ${state.signResult!.signerAddress}'),
                      Text('签名摘要: ${state.signResult!.signatureDigest}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (state.broadcastResult != null)
                WalletCard(
                  title: '广播确认结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('状态: ${state.broadcastResult!.status}'),
                      Text('区块高度: ${state.broadcastResult!.height}'),
                      Text('TxHash: ${state.broadcastResult!.txHash}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              WalletPrimaryButton(
                label: '前往交易历史导出',
                onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionHistoryExport),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stageChip(String label, bool done) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        done ? Icons.check_circle_rounded : Icons.schedule_rounded,
        color: done ? AppColorTokens.success : AppColorTokens.warning,
        size: 18,
      ),
    );
  }

  void _applyDraftFromBridge() {
    final draft = _draftBridge.value;
    if (draft == null) {
      return;
    }
    _recipientController.text = draft.recipientAddress;
    _amountController.text = draft.amountText;
    _memoController.text = draft.memo;
    if (mounted) {
      setState(() => _errorText = '${draft.source} 已回填交易表单');
    }
  }
}
