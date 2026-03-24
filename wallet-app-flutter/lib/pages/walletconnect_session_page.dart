import 'package:flutter/material.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_contract.dart';
import '../state/security_interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class WalletConnectSessionPage extends StatefulWidget {
  const WalletConnectSessionPage({super.key});

  @override
  State<WalletConnectSessionPage> createState() => _WalletConnectSessionPageState();
}

class _WalletConnectSessionPageState extends State<WalletConnectSessionPage> {
  final WalletConnectStore _store = WalletConnectStore.instance;
  String? _errorText;

  Future<void> _approve() async {
    setState(() => _errorText = null);
    try {
      await _store.approvePending();
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  Future<void> _reject() async {
    setState(() => _errorText = null);
    try {
      await _store.rejectPending();
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WalletConnectState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final pending = state.pendingRequest;
        return Scaffold(
          appBar: AppBar(title: const Text('WalletConnect 授权与会话')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '待处理授权请求',
                child: pending == null
                    ? const Text('当前没有新的 WalletConnect 请求。')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('挑战端点: ${ChainApiContract.authSignatureChallenge}'),
                          const Text('确认端点: ${ChainApiContract.authSignatureConfirm}'),
                          const SizedBox(height: 8),
                          Text('DApp: ${pending.dappName}'),
                          Text('Topic: ${pending.topic}'),
                          Text('Chain: ${pending.chainId}'),
                          Text('URI: ${pending.uri}'),
                          const SizedBox(height: 8),
                          const Text('权限范围:'),
                          for (final permission in pending.permissions) Text('- $permission'),
                          const SizedBox(height: 8),
                          Text(
                            pending.riskHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.warning),
                          ),
                          const SizedBox(height: 12),
                          WalletPrimaryButton(
                            label: '批准连接',
                            loading: state.loading,
                            onPressed: state.loading ? null : _approve,
                          ),
                          const SizedBox(height: 8),
                          WalletPrimaryButton(
                            label: '拒绝连接',
                            onPressed: state.loading ? null : _reject,
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
              if (state.errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorText!,
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
              if (state.lastAuthorizeReceipt != null) ...[
                const SizedBox(height: 16),
                WalletCard(
                  title: '本次真实会话签名',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('requestId: ${state.lastAuthorizeReceipt!.requestId}'),
                      Text('signatureDigest: ${state.lastAuthorizeReceipt!.signatureDigest}'),
                      Text('challenge: ${state.lastAuthorizeReceipt!.challengePath}'),
                      Text('confirm: ${state.lastAuthorizeReceipt!.confirmPath}'),
                      Text('authorizedAt: ${state.lastAuthorizeReceipt!.authorizedAt.toIso8601String()}'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              WalletCard(
                title: '已建立会话',
                child: state.sessions.isEmpty
                    ? const Text('暂无活跃会话。')
                    : Column(
                        children: [
                          for (final session in state.sessions) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(session.dappName, style: Theme.of(context).textTheme.titleSmall),
                                      Text('SessionId: ${session.sessionId}'),
                                      Text('Topic: ${session.topic}'),
                                      Text('链: ${session.chainId}'),
                                      Text('连接时间: ${session.connectedAt.toIso8601String()}'),
                                      Text('最近活跃: ${session.lastActiveAt.toIso8601String()}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: '刷新活跃',
                                  onPressed: () => _store.markActive(session.topic),
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                                IconButton(
                                  tooltip: '断开会话',
                                  onPressed: () => _store.disconnect(session.topic),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
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
