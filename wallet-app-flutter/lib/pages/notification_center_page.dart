import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../api/chain_api_contract.dart';
import '../state/notification_multisig_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final NotificationCenterStore _store = NotificationCenterStore.instance;

  @override
  void initState() {
    super.initState();
    _store.startStream();
  }

  @override
  void dispose() {
    _store.stopStream();
    super.dispose();
  }

  String _categoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.balance:
        return '到账';
      case NotificationCategory.governance:
        return '治理';
      case NotificationCategory.transaction:
        return '交易';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NotificationCenterState>(
      valueListenable: _store,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('实时通知中心')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '通知流状态',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.streaming ? '状态: 推送中（SSE / Webhook）' : '状态: 已暂停'),
                    Text('总消息数: ${state.notifications.length}'),
                    const Text('SSE 端点: ${ChainApiContract.notificationsStream}'),
                    const Text('Webhook 端点: ${ChainApiContract.notificationsWebhook}'),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(
                      label: '模拟接收一条消息',
                      onPressed: _store.pushMockNow,
                    ),
                    const SizedBox(height: 8),
                    WalletPrimaryButton(
                      label: state.streaming ? '暂停实时流' : '恢复实时流',
                      onPressed: state.streaming ? _store.stopStream : _store.startStream,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '消息列表',
                child: state.notifications.isEmpty
                    ? const Text('暂无通知消息。')
                    : Column(
                        children: [
                          for (final item in state.notifications) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Expanded(child: Text(item.title)),
                                  Chip(
                                    label: Text(_categoryLabel(item.category)),
                                    avatar: Icon(
                                      item.read ? Icons.mark_email_read_rounded : Icons.notifications_active_rounded,
                                      size: 18,
                                      color: item.read ? AppColorTokens.success : AppColorTokens.warning,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item.summary),
                                  const SizedBox(height: 4),
                                  Text(
                                    '来源: ${item.source}  时间: ${item.createdAt.toIso8601String()}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip: '查看详情',
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: () {
                                  _store.markRead(item.id);
                                  Navigator.pushNamed(
                                    context,
                                    WalletRoutes.notificationDetail,
                                    arguments: item.id,
                                  );
                                },
                              ),
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
