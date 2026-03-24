import 'package:flutter/material.dart';

import '../api/api_error_mapper.dart';
import '../state/interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class StakingFlowPage extends StatefulWidget {
  const StakingFlowPage({super.key});

  @override
  State<StakingFlowPage> createState() => _StakingFlowPageState();
}

class _StakingFlowPageState extends State<StakingFlowPage> {
  final StakeDemoStore _store = StakeDemoStore.instance;
  final TextEditingController _amountController = TextEditingController(text: '25.00');
  StakeActionType _action = StakeActionType.delegate;
  String? _validator;
  String? _destinationValidator;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (_store.validators.isNotEmpty) {
      _validator = _store.validators.first;
      _destinationValidator = _store.validators.length > 1 ? _store.validators[1] : _store.validators.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    try {
      await _store.runStakeFlow(
        action: _action,
        validator: _validator ?? '',
        destinationValidator: _action == StakeActionType.redelegate ? _destinationValidator : null,
        amountText: _action == StakeActionType.claim ? '' : _amountController.text,
      );
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StakeFlowState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final validators = _store.validators;
        final currentValidator = validators.contains(_validator) ? _validator : (validators.isNotEmpty ? validators.first : null);
        final currentDestination = validators.contains(_destinationValidator)
            ? _destinationValidator
            : (validators.length > 1 ? validators[1] : (validators.isNotEmpty ? validators.first : null));
        return Scaffold(
          appBar: AppBar(title: const Text('质押操作全流程')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '操作参数',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<StakeActionType>(
                      key: ValueKey(_action),
                      initialValue: _action,
                      items: const [
                        DropdownMenuItem(value: StakeActionType.delegate, child: Text('Delegate')),
                        DropdownMenuItem(value: StakeActionType.undelegate, child: Text('Undelegate')),
                        DropdownMenuItem(value: StakeActionType.redelegate, child: Text('Redelegate')),
                        DropdownMenuItem(value: StakeActionType.claim, child: Text('Claim Rewards')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _action = value);
                      },
                      decoration: const InputDecoration(labelText: '操作类型'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: ValueKey(currentValidator),
                      initialValue: currentValidator,
                      isExpanded: true,
                      items: [
                        for (final item in validators)
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _validator = value),
                      decoration: const InputDecoration(labelText: '验证人'),
                    ),
                    if (_action == StakeActionType.redelegate) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey(currentDestination),
                        initialValue: currentDestination,
                        isExpanded: true,
                        items: [
                          for (final item in validators)
                            DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _destinationValidator = value),
                        decoration: const InputDecoration(labelText: '目标验证人'),
                      ),
                    ],
                    if (_action != StakeActionType.claim) ...[
                      const SizedBox(height: 10),
                      WalletTextField(
                        label: '金额（SOUL）',
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                        controller: _amountController,
                      ),
                    ],
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '执行质押流程',
                      loading: state.loading,
                      onPressed: state.loading ? null : _submit,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                    if (_errorText == null && state.errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '流程进度',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _stageChip('参数校验', true),
                    _stageChip('Gas 仿真', state.simulatedGas != null),
                    _stageChip('签名摘要', state.txDigest != null),
                    _stageChip('广播确认', state.result != null),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.simulatedGas != null)
                WalletCard(
                  title: '仿真结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('gasUsed: ${state.simulatedGas}'),
                      Text('建议手续费: ${state.feeSuggestion}'),
                    ],
                  ),
                ),
              if (state.simulatedGas != null) const SizedBox(height: 12),
              if (state.txDigest != null)
                WalletCard(
                  title: '签名摘要',
                  child: Text(state.txDigest!),
                ),
              if (state.txDigest != null) const SizedBox(height: 12),
              if (state.result != null)
                WalletCard(
                  title: '链上结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('操作: ${_actionLabel(state.result!.action)}'),
                      Text('验证人: ${state.result!.validator}'),
                      if (state.result!.destinationValidator != null)
                        Text('目标验证人: ${state.result!.destinationValidator}'),
                      Text('金额: ${state.result!.amount.toStringAsFixed(2)} SOUL'),
                      Text('状态: ${state.result!.status}'),
                      Text('高度: ${state.result!.height}'),
                      Text('TxHash: ${state.result!.txHash}'),
                      Text('契约端点: ${state.result!.contractPath}'),
                    ],
                  ),
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
        size: 18,
        color: done ? AppColorTokens.success : AppColorTokens.warning,
      ),
    );
  }

  String _actionLabel(StakeActionType action) {
    switch (action) {
      case StakeActionType.delegate:
        return 'Delegate';
      case StakeActionType.undelegate:
        return 'Undelegate';
      case StakeActionType.redelegate:
        return 'Redelegate';
      case StakeActionType.claim:
        return 'Claim';
    }
  }
}
