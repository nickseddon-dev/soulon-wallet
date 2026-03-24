import 'package:flutter/material.dart';

import '../api/api_error_mapper.dart';
import '../app/app_router.dart';
import '../state/security_interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class SuggestChainScanReorgPage extends StatefulWidget {
  const SuggestChainScanReorgPage({super.key});

  @override
  State<SuggestChainScanReorgPage> createState() => _SuggestChainScanReorgPageState();
}

class _SuggestChainScanReorgPageState extends State<SuggestChainScanReorgPage> {
  final DappInteropStore _store = DappInteropStore.instance;
  final TextEditingController _uriController =
      TextEditingController(text: 'soulon:soulon1payee6y4l8xj3f5j9d0x3t4?amount=3.6&memo=coffee');
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _store.startAutoRefresh();
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  Future<void> _approveChain() async {
    setState(() => _errorText = null);
    try {
      await _store.approveSuggestChain();
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  Future<void> _rejectChain() async {
    setState(() => _errorText = null);
    try {
      await _store.rejectSuggestChain();
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  void _parseUri() {
    setState(() => _errorText = null);
    try {
      _store.parseBip21(_uriController.text);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  Future<void> _refreshReorg() async {
    setState(() => _errorText = null);
    await _store.refreshReorgStatus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DappInteropState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final chainRequest = state.pendingSuggestChain;
        return Scaffold(
          appBar: AppBar(title: const Text('SuggestChain/扫码/Reorg 提示')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: 'SuggestChain 请求',
                child: chainRequest == null
                    ? const Text('当前没有待处理的加链请求。')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('链名: ${chainRequest.chainName}'),
                          Text('chainId: ${chainRequest.chainId}'),
                          Text('RPC: ${chainRequest.rpc}'),
                          Text('REST: ${chainRequest.rest}'),
                          Text('前缀: ${chainRequest.bech32Prefix}'),
                          Text('原生币: ${chainRequest.denom}'),
                          const SizedBox(height: 12),
                          WalletPrimaryButton(
                            label: '批准加链',
                            loading: state.loading,
                            onPressed: state.loading ? null : _approveChain,
                          ),
                          const SizedBox(height: 8),
                          WalletPrimaryButton(
                            label: '拒绝加链',
                            onPressed: state.loading ? null : _rejectChain,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '扫码支付（BIP-21 URI）',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletTextField(
                      label: '扫码结果',
                      hintText: 'bitcoin:addr?amount=1.2&memo=...',
                      controller: _uriController,
                    ),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(
                      label: '解析扫码结果',
                      onPressed: _parseUri,
                    ),
                    if (state.scanResult != null) ...[
                      const SizedBox(height: 12),
                      Text('协议: ${state.scanResult!.scheme}'),
                      Text('地址: ${state.scanResult!.address}'),
                      Text('金额: ${state.scanResult!.amount ?? '-'}'),
                      Text('Memo: ${state.scanResult!.memo ?? '-'}'),
                      const SizedBox(height: 10),
                      WalletPrimaryButton(
                        label: '打开交易构建页并查看回填',
                        onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionFlow),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: 'Reorg 刷新提示',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TxHash: ${state.reorgNotice.txHash}'),
                    Text('旧高度: ${state.reorgNotice.previousHeight}'),
                    Text('新高度: ${state.reorgNotice.currentHeight}'),
                    Text('状态: ${state.reorgNotice.status}'),
                    Text('检测时间: ${state.reorgNotice.detectedAt.toIso8601String()}'),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '刷新交易状态',
                      loading: state.loading,
                      onPressed: state.loading ? null : _refreshReorg,
                    ),
                  ],
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                ),
              ],
              if (state.errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                ),
              ],
              if (state.noticeText != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.noticeText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.success),
                ),
              ],
              if (state.approvedChains.isNotEmpty) ...[
                const SizedBox(height: 16),
                WalletCard(
                  title: '已批准网络',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final chain in state.approvedChains)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${chain.chainName} (${chain.chainId})'),
                        ),
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
}
