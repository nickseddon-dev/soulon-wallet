import 'package:flutter/material.dart';

import '../api/api_error_mapper.dart';
import '../state/interop_demo_store.dart';
import '../state/security_interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class IbcTransferTrackingPage extends StatefulWidget {
  const IbcTransferTrackingPage({super.key});

  @override
  State<IbcTransferTrackingPage> createState() => _IbcTransferTrackingPageState();
}

class _IbcTransferTrackingPageState extends State<IbcTransferTrackingPage> {
  final IbcDemoStore _store = IbcDemoStore.instance;
  final DappInteropStore _reorgStore = DappInteropStore.instance;
  final TextEditingController _receiverController =
      TextEditingController(text: 'osmo1pl8t4jm9hsz9p6vrx4g2s0y7glk9n5ck9syv2w');
  final TextEditingController _amountController = TextEditingController(text: '8.00');
  String? _chainId;
  String? _channelId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final first = _store.value.channels.first;
    _chainId = first.chainId;
    _channelId = first.channelId;
    _reorgStore.startAutoRefresh();
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    try {
      await _store.transfer(
        chainId: _chainId ?? '',
        channelId: _channelId ?? '',
        receiverAddress: _receiverController.text,
        amountText: _amountController.text,
      );
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IbcTransferState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final channels = state.channels.where((item) => item.chainId == _chainId).toList(growable: false);
        if (channels.isNotEmpty && !channels.any((item) => item.channelId == _channelId)) {
          _channelId = channels.first.channelId;
        }
        return Scaffold(
          appBar: AppBar(title: const Text('IBC 传输与状态追踪')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '传输参数',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_chainId),
                      initialValue: _chainId,
                      items: state.channels
                          .map((channel) => channel.chainId)
                          .toSet()
                          .map((chainId) => DropdownMenuItem(value: chainId, child: Text(chainId)))
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        final firstChannel = state.channels.where((item) => item.chainId == value).first;
                        setState(() {
                          _chainId = value;
                          _channelId = firstChannel.channelId;
                        });
                      },
                      decoration: const InputDecoration(labelText: '目标链'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: ValueKey('${_chainId}_$_channelId'),
                      initialValue: _channelId,
                      items: channels
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.channelId,
                              child: Text('${item.channelId} (${item.portId})'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _channelId = value),
                      decoration: const InputDecoration(labelText: 'Channel'),
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '接收地址',
                      hintText: 'osmo1...',
                      controller: _receiverController,
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '金额（SOUL）',
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      controller: _amountController,
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '提交 ICS-20 转账',
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '包状态追踪',
                child: state.result == null
                    ? Text(
                        '尚未提交 IBC 包，提交后将展示 Submitted → Relayed → AckReceived → Completed。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.textSecondary),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('目标链: ${state.result!.chainId}'),
                          Text('Channel: ${state.result!.channelId}'),
                          Text('接收地址: ${state.result!.receiver}'),
                          Text('金额: ${state.result!.amount.toStringAsFixed(2)} SOUL'),
                          Text('Packet Sequence: ${state.result!.sequence}'),
                          Text('TxHash: ${state.result!.txHash}'),
                          Text('契约端点: ${state.result!.contractPath}'),
                          const SizedBox(height: 10),
                          for (final step in state.result!.steps)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    _stepDone(step, state.result!.currentStep)
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: _stepDone(step, state.result!.currentStep)
                                        ? AppColorTokens.success
                                        : AppColorTokens.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_stepLabel(step)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<DappInteropState>(
                valueListenable: _reorgStore,
                builder: (context, reorgState, _) {
                  return WalletCard(
                    title: 'Reorg 自动刷新',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TxHash: ${reorgState.reorgNotice.txHash}'),
                        Text('高度: ${reorgState.reorgNotice.previousHeight} → ${reorgState.reorgNotice.currentHeight}'),
                        Text('状态: ${reorgState.reorgNotice.status}'),
                        if (reorgState.noticeText != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            reorgState.noticeText!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.success),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _stepDone(IbcPacketStep step, IbcPacketStep current) {
    const order = {
      IbcPacketStep.submitted: 0,
      IbcPacketStep.relayed: 1,
      IbcPacketStep.ackReceived: 2,
      IbcPacketStep.completed: 3,
    };
    return (order[step] ?? 0) <= (order[current] ?? 0);
  }

  String _stepLabel(IbcPacketStep step) {
    switch (step) {
      case IbcPacketStep.submitted:
        return 'Submitted';
      case IbcPacketStep.relayed:
        return 'Relayed';
      case IbcPacketStep.ackReceived:
        return 'Ack Received';
      case IbcPacketStep.completed:
        return 'Completed';
    }
  }
}
