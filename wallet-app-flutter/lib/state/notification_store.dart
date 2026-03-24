import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/mock_data.dart';

enum NotificationCategory { balance, governance, transaction }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.detail,
    required this.source,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String summary;
  final String detail;
  final String source;
  final DateTime createdAt;
  final bool read;

  NotificationItem copyWith({
    String? id,
    NotificationCategory? category,
    String? title,
    String? summary,
    String? detail,
    String? source,
    DateTime? createdAt,
    bool? read,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      detail: detail ?? this.detail,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }
}

class NotificationCenterState {
  const NotificationCenterState({
    required this.notifications,
    this.streaming = false,
    this.errorText,
  });

  final List<NotificationItem> notifications;
  final bool streaming;
  final String? errorText;

  NotificationCenterState copyWith({
    List<NotificationItem>? notifications,
    bool? streaming,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      streaming: streaming ?? this.streaming,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class NotificationCenterStore extends ValueNotifier<NotificationCenterState> {
  NotificationCenterStore._()
      : _random = Random.secure(),
        super(
          NotificationCenterState(
            notifications: MockData.seedNotifications,
          ),
        );

  static final NotificationCenterStore instance = NotificationCenterStore._();
  final Random _random;
  Timer? _timer;
  Timer? _autoStopTimer;
  int _seed = 2000;

  static const _maxStreamDuration = Duration(minutes: 10);

  void startStream() {
    if (_timer != null) {
      return;
    }
    value = value.copyWith(streaming: true, clearErrorText: true);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final item = _buildRealtimeNotification();
      value = value.copyWith(
        notifications: [item, ...value.notifications],
        clearErrorText: true,
      );
    });
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(_maxStreamDuration, stopStream);
  }

  void stopStream() {
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    value = value.copyWith(streaming: false);
  }

  void markRead(String id) {
    final next = value.notifications
        .map((item) => item.id == id ? item.copyWith(read: true) : item)
        .toList(growable: false);
    value = value.copyWith(notifications: next, clearErrorText: true);
  }

  NotificationItem? findById(String id) {
    for (final item in value.notifications) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  void pushMockNow() {
    final item = _buildRealtimeNotification();
    value = value.copyWith(
      notifications: [item, ...value.notifications],
      clearErrorText: true,
    );
  }

  NotificationItem _buildRealtimeNotification() {
    _seed += 1;
    final pick = _random.nextInt(3);
    if (pick == 0) {
      final amount = (8 + _random.nextInt(30)) + _random.nextDouble();
      return NotificationItem(
        id: 'NTF-$_seed',
        category: NotificationCategory.balance,
        title: '余额变动',
        summary: '地址到账 ${amount.toStringAsFixed(2)} SOUL，已进入可用余额。',
        detail: '推送流收到余额变更事件，资金来源地址 cosmos1corp..., 请核验资金用途与账务归集规则。',
        source: 'indexer',
        createdAt: DateTime.now(),
      );
    }
    if (pick == 1) {
      final proposal = 110 + _random.nextInt(15);
      return NotificationItem(
        id: 'NTF-$_seed',
        category: NotificationCategory.governance,
        title: '治理进度提醒',
        summary: '提案 #$proposal 状态变化，待企业账号完成多签投票。',
        detail: 'Webhook 检测到提案 #$proposal 进入关键窗口，建议在 12 小时内完成 M-of-N 审批。',
        source: 'webhook',
        createdAt: DateTime.now(),
      );
    }
    final height = 912500 + _random.nextInt(120);
    return NotificationItem(
      id: 'NTF-$_seed',
      category: NotificationCategory.transaction,
      title: '交易打包确认',
      summary: '交易 9C2E...A81B 确认，高度 $height。',
      detail: '链上交易 9C2E4D...A81B 已确认，回执状态成功，建议进入详情页查看完整执行上下文。',
      source: 'indexer',
      createdAt: DateTime.now(),
    );
  }
}
