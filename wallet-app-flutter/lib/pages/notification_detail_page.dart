import 'package:flutter/material.dart';

import '../state/notification_multisig_demo_store.dart';
import '../widgets/cards/wallet_card.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({
    super.key,
    required this.notificationId,
  });

  final String notificationId;

  @override
  Widget build(BuildContext context) {
    final store = NotificationCenterStore.instance;
    final item = store.findById(notificationId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('通知详情')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: WalletCard(
            title: '消息不存在',
            child: Text('未找到对应通知，请返回通知中心重试。'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('通知详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WalletCard(
            title: item.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('通知ID: ${item.id}'),
                const SizedBox(height: 8),
                Text('来源: ${item.source}'),
                Text('时间: ${item.createdAt.toIso8601String()}'),
                Text('已读: ${item.read ? '是' : '否'}'),
                const SizedBox(height: 12),
                Text(item.summary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WalletCard(
            title: '消息正文',
            child: Text(item.detail),
          ),
        ],
      ),
    );
  }
}
