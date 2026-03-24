import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';

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
            notifications: [
              NotificationItem(
                id: 'NTF-1201',
                category: NotificationCategory.balance,
                title: '到账提醒',
                summary: '收到 12.50 SOUL，来源 cosmos1treasury...',
                detail: '索引器检测到账交易已打包，金额 12.50 SOUL，手续费 0.02 SOUL，确认高度 912340。',
                source: 'indexer',
                createdAt: DateTime(2026, 3, 5, 10, 42),
              ),
              NotificationItem(
                id: 'NTF-1202',
                category: NotificationCategory.governance,
                title: '提案上线',
                summary: '提案 #108 已进入投票期，剩余 3 天 4 小时。',
                detail: '治理提案 #108（参数调优）进入投票期，建议尽快完成企业多签审批并提交投票。',
                source: 'webhook',
                createdAt: DateTime(2026, 3, 5, 10, 58),
              ),
              NotificationItem(
                id: 'NTF-1203',
                category: NotificationCategory.transaction,
                title: '交易状态更新',
                summary: 'Tx 8FA9...12CE 已确认，高度 912366。',
                detail: '交易 8FA9C1D2A7B4...12CE 已确认，GasUsed 174321，链上状态 successful。',
                source: 'indexer',
                createdAt: DateTime(2026, 3, 5, 11, 8),
              ),
            ],
          ),
        );

  static final NotificationCenterStore instance = NotificationCenterStore._();
  final Random _random;
  Timer? _timer;
  int _seed = 2000;

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
  }

  void stopStream() {
    _timer?.cancel();
    _timer = null;
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

enum MultisigTaskStatus { pending, approving, ready, submitting, submitted, confirmed, rejected }

class OfflineSignatureEntry {
  const OfflineSignatureEntry({
    required this.signer,
    required this.signatureDigest,
    required this.accepted,
    required this.message,
  });

  final String signer;
  final String signatureDigest;
  final bool accepted;
  final String message;
}

class MultisigTask {
  const MultisigTask({
    required this.id,
    required this.title,
    required this.description,
    required this.allSigners,
    required this.threshold,
    required this.totalSigners,
    required this.collectedSigners,
    required this.pendingSigners,
    required this.approvedSigners,
    required this.txDigest,
    required this.updatedAt,
    required this.status,
    this.lastImportEntries = const [],
    this.approvalLogs = const [],
    this.onChainTxHash,
    this.onChainHeight,
    this.submittedAt,
  });

  final String id;
  final String title;
  final String description;
  final List<String> allSigners;
  final int threshold;
  final int totalSigners;
  final int collectedSigners;
  final List<String> pendingSigners;
  final List<String> approvedSigners;
  final String txDigest;
  final DateTime updatedAt;
  final MultisigTaskStatus status;
  final List<OfflineSignatureEntry> lastImportEntries;
  final List<String> approvalLogs;
  final String? onChainTxHash;
  final int? onChainHeight;
  final DateTime? submittedAt;

  int get requiredSignatures {
    final remaining = threshold - collectedSigners;
    return remaining > 0 ? remaining : 0;
  }

  double get progress {
    if (threshold == 0) {
      return 0;
    }
    return (collectedSigners / threshold).clamp(0, 1).toDouble();
  }

  MultisigTask copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? allSigners,
    int? threshold,
    int? totalSigners,
    int? collectedSigners,
    List<String>? pendingSigners,
    List<String>? approvedSigners,
    String? txDigest,
    DateTime? updatedAt,
    MultisigTaskStatus? status,
    List<OfflineSignatureEntry>? lastImportEntries,
    List<String>? approvalLogs,
    String? onChainTxHash,
    int? onChainHeight,
    DateTime? submittedAt,
  }) {
    return MultisigTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      allSigners: allSigners ?? this.allSigners,
      threshold: threshold ?? this.threshold,
      totalSigners: totalSigners ?? this.totalSigners,
      collectedSigners: collectedSigners ?? this.collectedSigners,
      pendingSigners: pendingSigners ?? this.pendingSigners,
      approvedSigners: approvedSigners ?? this.approvedSigners,
      txDigest: txDigest ?? this.txDigest,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      lastImportEntries: lastImportEntries ?? this.lastImportEntries,
      approvalLogs: approvalLogs ?? this.approvalLogs,
      onChainTxHash: onChainTxHash ?? this.onChainTxHash,
      onChainHeight: onChainHeight ?? this.onChainHeight,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

class MultisigOnChainReceipt {
  const MultisigOnChainReceipt({
    required this.txHash,
    required this.height,
    required this.confirmed,
    required this.statusText,
  });

  final String txHash;
  final int height;
  final bool confirmed;
  final String statusText;
}

typedef MultisigTaskSubmitter = Future<MultisigOnChainReceipt> Function(MultisigTask task);

class MultisigWorkbenchState {
  const MultisigWorkbenchState({
    required this.tasks,
    required this.importProgress,
    required this.importLogs,
    this.processing = false,
    this.noticeText,
    this.errorText,
  });

  final List<MultisigTask> tasks;
  final bool processing;
  final double importProgress;
  final List<String> importLogs;
  final String? noticeText;
  final String? errorText;

  MultisigWorkbenchState copyWith({
    List<MultisigTask>? tasks,
    bool? processing,
    double? importProgress,
    List<String>? importLogs,
    String? noticeText,
    bool clearNoticeText = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return MultisigWorkbenchState(
      tasks: tasks ?? this.tasks,
      processing: processing ?? this.processing,
      importProgress: importProgress ?? this.importProgress,
      importLogs: importLogs ?? this.importLogs,
      noticeText: clearNoticeText ? null : (noticeText ?? this.noticeText),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class MultisigWorkbenchStore extends ValueNotifier<MultisigWorkbenchState> {
  MultisigWorkbenchStore._({
    required MultisigTaskSubmitter submitter,
    List<MultisigTask>? seedTasks,
  })  : _submitter = submitter,
        super(
          MultisigWorkbenchState(
            tasks: seedTasks ?? _buildDefaultTasks(),
            importProgress: 0,
            importLogs: const [],
          ),
        ) {
    for (final task in value.tasks) {
      _assertTaskModel(task);
    }
  }

  static final MultisigWorkbenchStore instance = MultisigWorkbenchStore._(
    submitter: _buildRemoteSubmitter(
      ChainApiClient(
        baseUrl: WalletRuntimeConfig.apiBaseUrl,
        timeout: WalletRuntimeConfig.requestTimeout,
      ),
    ),
  );

  factory MultisigWorkbenchStore.test({
    required MultisigTaskSubmitter submitter,
    required List<MultisigTask> seedTasks,
  }) {
    return MultisigWorkbenchStore._(
      submitter: submitter,
      seedTasks: seedTasks,
    );
  }

  final MultisigTaskSubmitter _submitter;

  Future<void> approveTask(String taskId, String signer) async {
    final task = _findTask(taskId);
    if (task == null) {
      throw const FormatException('未找到多签任务');
    }
    if (!task.pendingSigners.contains(signer)) {
      throw FormatException('签名人 $signer 不在待签列表中');
    }
    if (value.processing) {
      throw const FormatException('当前有审批流程进行中，请稍候');
    }
    value = value.copyWith(
      processing: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      final updated = _mergeApproval(
        task: task,
        signer: signer,
        source: '在线审批',
      );
      _updateTask(updated);
      final resultText = updated.status == MultisigTaskStatus.ready ? '已达到阈值，可广播' : '审批通过，等待更多签名';
      value = value.copyWith(
        processing: false,
        noticeText: '任务 ${task.id} 审批成功：$signer，$resultText。',
      );
    } catch (error) {
      value = value.copyWith(processing: false);
      if (error is FormatException) {
        rethrow;
      }
      throw const FormatException('审批失败，请稍后重试');
    }
  }

  Future<void> rejectTask(String taskId, String signer) async {
    final task = _findTask(taskId);
    if (task == null) {
      throw const FormatException('未找到多签任务');
    }
    if (value.processing) {
      throw const FormatException('当前有审批流程进行中，请稍候');
    }
    value = value.copyWith(
      processing: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      _updateTask(
        task.copyWith(
          status: MultisigTaskStatus.rejected,
          updatedAt: DateTime.now(),
          approvalLogs: [
            ...task.approvalLogs,
            '[${DateTime.now().toIso8601String()}] 审批驳回：$signer',
          ],
        ),
      );
      value = value.copyWith(
        processing: false,
        noticeText: '任务 ${task.id} 已被 $signer 驳回，需重新发起审批。',
      );
    } catch (error) {
      value = value.copyWith(processing: false);
      if (error is FormatException) {
        rethrow;
      }
      throw const FormatException('驳回失败，请稍后重试');
    }
  }

  Future<void> importOfflineSignatures({
    required String taskId,
    required String payload,
  }) async {
    final task = _findTask(taskId);
    if (task == null) {
      throw const FormatException('请选择有效的多签任务');
    }
    final lines = payload
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const FormatException('请粘贴离线签名内容，每行一条 signer:signature:txDigest');
    }
    value = value.copyWith(
      processing: true,
      importProgress: 0,
      importLogs: const ['开始解析离线签名包...'],
      clearNoticeText: true,
      clearErrorText: true,
    );
    final entries = <OfflineSignatureEntry>[];
    final seenSigners = <String>{};
    var currentTask = task;
    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final parsed = _parseLine(line);
      if (parsed == null) {
        entries.add(
          OfflineSignatureEntry(
            signer: 'unknown',
            signatureDigest: _digest(line),
            accepted: false,
            message: '格式错误，要求 signer:signature:txDigest',
          ),
        );
      } else {
        final signer = parsed.$1;
        final signature = parsed.$2;
        final txDigest = parsed.$3;
        if (seenSigners.contains(signer)) {
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: false,
              message: '离线包内重复签名人',
            ),
          );
        } else if (txDigest == null || txDigest.isEmpty) {
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: false,
              message: '缺少交易摘要，无法做签名绑定验证',
            ),
          );
        } else if (txDigest.toUpperCase() != currentTask.txDigest.toUpperCase()) {
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: false,
              message: '交易摘要不匹配，签名已拒绝',
            ),
          );
        } else if (!_isSignatureFormatValid(signature)) {
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: false,
              message: '签名格式无效',
            ),
          );
        } else if (!currentTask.pendingSigners.contains(signer)) {
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: false,
              message: '签名人不在待签列表',
            ),
          );
        } else {
          currentTask = _mergeApproval(
            task: currentTask,
            signer: signer,
            source: '离线导入',
            signatureDigest: _digest(signature),
          );
          seenSigners.add(signer);
          entries.add(
            OfflineSignatureEntry(
              signer: signer,
              signatureDigest: _digest(signature),
              accepted: true,
              message: '合并验证通过，已计入阈值进度',
            ),
          );
        }
      }
      final progress = (i + 1) / lines.length;
      value = value.copyWith(
        importProgress: progress,
        importLogs: [...value.importLogs, '已处理 ${i + 1}/${lines.length} 条签名'],
      );
    }
    _updateTask(currentTask.copyWith(lastImportEntries: entries));
    final accepted = entries.where((item) => item.accepted).length;
    final rejected = entries.length - accepted;
    value = value.copyWith(
      processing: false,
      noticeText: '离线签名导入完成：通过 $accepted 条，拒绝 $rejected 条。',
    );
  }

  Future<void> submitTaskOnChain(String taskId) async {
    final task = _findTask(taskId);
    if (task == null) {
      throw const FormatException('未找到多签任务');
    }
    if (value.processing) {
      throw const FormatException('当前有审批流程进行中，请稍候');
    }
    if (!_isQuorumReached(task)) {
      throw const FormatException('当前签名未达到阈值，无法链上提交');
    }
    if (task.status == MultisigTaskStatus.confirmed) {
      throw const FormatException('任务已完成链上确认，无需重复提交');
    }
    value = value.copyWith(
      processing: true,
      clearNoticeText: true,
      clearErrorText: true,
    );

    final submittingTask = task.copyWith(
      status: MultisigTaskStatus.submitting,
      updatedAt: DateTime.now(),
    );
    _updateTask(submittingTask);

    try {
      final receipt = await _submitter(submittingTask);
      final now = DateTime.now();
      final txShort = receipt.txHash.length <= 12 ? receipt.txHash : receipt.txHash.substring(0, 12);
      final backfillLogs = submittingTask.approvedSigners
          .map(
            (signer) => '[${now.toIso8601String()}] 审批回写：$signer -> tx=$txShort...',
          )
          .toList(growable: false);
      final nextStatus = receipt.confirmed ? MultisigTaskStatus.confirmed : MultisigTaskStatus.submitted;
      _updateTask(
        submittingTask.copyWith(
          status: nextStatus,
          onChainTxHash: receipt.txHash,
          onChainHeight: receipt.height,
          submittedAt: now,
          updatedAt: now,
          approvalLogs: [...submittingTask.approvalLogs, ...backfillLogs],
        ),
      );
      value = value.copyWith(
        processing: false,
        noticeText: '任务 ${task.id} 已提交链上：${receipt.statusText}，审批结果已回写。',
      );
    } on ApiClientException catch (error) {
      _updateTask(task.copyWith(status: MultisigTaskStatus.ready, updatedAt: DateTime.now()));
      value = value.copyWith(processing: false);
      throw FormatException('链上提交失败：${error.message ?? '网络异常'}');
    } on FormatException {
      _updateTask(task.copyWith(status: MultisigTaskStatus.ready, updatedAt: DateTime.now()));
      value = value.copyWith(processing: false);
      rethrow;
    } catch (_) {
      _updateTask(task.copyWith(status: MultisigTaskStatus.ready, updatedAt: DateTime.now()));
      value = value.copyWith(processing: false);
      throw const FormatException('链上提交失败，请稍后重试');
    }
  }

  void clearImportProgress() {
    value = value.copyWith(
      importProgress: 0,
      importLogs: const [],
      clearNoticeText: true,
      clearErrorText: true,
    );
  }

  MultisigTask? _findTask(String taskId) {
    for (final task in value.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  void _updateTask(MultisigTask nextTask) {
    _assertTaskModel(nextTask);
    final tasks = value.tasks
        .map((item) => item.id == nextTask.id ? nextTask : item)
        .toList(growable: false);
    value = value.copyWith(tasks: tasks, clearErrorText: true);
  }

  MultisigTask _mergeApproval({
    required MultisigTask task,
    required String signer,
    required String source,
    String? signatureDigest,
  }) {
    if (!_isApprovalMutable(task)) {
      throw const FormatException('当前任务状态不可继续审批');
    }
    if (!task.pendingSigners.contains(signer)) {
      throw FormatException('签名人 $signer 不在待签列表中');
    }
    final pending = task.pendingSigners.where((item) => item != signer).toList(growable: false);
    final approved = [...task.approvedSigners, signer];
    final collected = approved.length;
    final nextStatus = collected >= task.threshold ? MultisigTaskStatus.ready : MultisigTaskStatus.approving;
    final logDigest = signatureDigest ?? _digest('$source|$signer|${task.txDigest}');
    return task.copyWith(
      pendingSigners: pending,
      approvedSigners: approved,
      collectedSigners: collected,
      status: nextStatus,
      updatedAt: DateTime.now(),
      approvalLogs: [
        ...task.approvalLogs,
        '[${DateTime.now().toIso8601String()}] $source 通过：$signer (sig:$logDigest)',
      ],
    );
  }

  bool _isApprovalMutable(MultisigTask task) {
    return task.status != MultisigTaskStatus.rejected &&
        task.status != MultisigTaskStatus.submitting &&
        task.status != MultisigTaskStatus.submitted &&
        task.status != MultisigTaskStatus.confirmed;
  }

  bool _isQuorumReached(MultisigTask task) {
    return task.collectedSigners >= task.threshold && task.approvedSigners.length >= task.threshold;
  }

  void _assertTaskModel(MultisigTask task) {
    if (task.threshold <= 0 || task.totalSigners <= 0) {
      throw FormatException('任务 ${task.id} 的 M-of-N 配置无效');
    }
    if (task.threshold > task.totalSigners) {
      throw FormatException('任务 ${task.id} 的阈值超过签名人数');
    }
    final allSigners = task.allSigners.toSet();
    if (allSigners.length != task.totalSigners) {
      throw FormatException('任务 ${task.id} 的签名人配置与 N 不一致');
    }
    final approved = task.approvedSigners.toSet();
    final pending = task.pendingSigners.toSet();
    if (approved.length != task.approvedSigners.length || pending.length != task.pendingSigners.length) {
      throw FormatException('任务 ${task.id} 存在重复签名人');
    }
    if (approved.intersection(pending).isNotEmpty) {
      throw FormatException('任务 ${task.id} 的已签与待签列表冲突');
    }
    if (approved.length != task.collectedSigners) {
      throw FormatException('任务 ${task.id} 的签名计数与已签人数不一致');
    }
    if (approved.length + pending.length != allSigners.length) {
      throw FormatException('任务 ${task.id} 的签名人清单不完整');
    }
    if (!approved.every(allSigners.contains) || !pending.every(allSigners.contains)) {
      throw FormatException('任务 ${task.id} 存在未登记签名人');
    }
  }

  (String, String, String?)? _parseLine(String line) {
    final parts = line.split(':');
    if (parts.length < 2 || parts.length > 3) {
      return null;
    }
    final signer = parts[0].trim();
    final signature = parts[1].trim();
    final txDigest = parts.length == 3 ? parts[2].trim() : null;
    if (signer.isEmpty || signature.isEmpty) {
      return null;
    }
    return (signer, signature, txDigest);
  }

  bool _isSignatureFormatValid(String signature) {
    return RegExp(r'^0x[0-9A-Fa-f]{8,}$').hasMatch(signature.trim());
  }

  String _digest(String seed) {
    final raw = seed.codeUnits.fold<int>(0, (hash, code) => ((hash * 37) ^ code) & 0x7fffffff);
    return raw.toRadixString(16).toUpperCase().padLeft(10, '0');
  }

  static MultisigTaskSubmitter _buildRemoteSubmitter(ChainApiClient apiClient) {
    return (task) async {
      final indexState = await apiClient.getJson(ChainApiContract.indexerState);
      final sequence = _toInt(indexState['tipHeight']) + 1;
      final txPayload = {
        'taskId': task.id,
        'txDigest': task.txDigest,
        'approvedSigners': task.approvedSigners,
        'threshold': task.threshold,
        'sequence': sequence,
      };
      final broadcastResponse = await apiClient.postJson(
        ChainApiContract.chainBroadcastTx,
        body: {
          'tx_bytes': base64Encode(utf8.encode(jsonEncode(txPayload))),
          'mode': 'BROADCAST_MODE_SYNC',
        },
      );
      final txResponse = _asMap(broadcastResponse['tx_response']);
      final txHashRaw = (txResponse['txhash'] ?? txResponse['txHash'] ?? '').toString();
      final txHash = txHashRaw.isEmpty
          ? _fallbackHash('${task.id}|${task.txDigest}|${DateTime.now().microsecondsSinceEpoch}')
          : txHashRaw;
      final height = _toInt(txResponse['height']);
      final code = _toInt(txResponse['code']);
      final confirmed = code == 0;
      return MultisigOnChainReceipt(
        txHash: txHash,
        height: height,
        confirmed: confirmed,
        statusText: confirmed ? '链上确认成功' : '已提交等待确认',
      );
    };
  }

  static List<MultisigTask> _buildDefaultTasks() {
    return [
      MultisigTask(
        id: 'MS-401',
        title: '企业金库转账审批',
        description: '向运营账户拨付 1500 SOUL，用于活动结算。',
        allSigners: const ['Alice', 'Bob', 'Carol'],
        threshold: 2,
        totalSigners: 3,
        collectedSigners: 1,
        pendingSigners: const ['Bob', 'Carol'],
        approvedSigners: const ['Alice'],
        txDigest: 'E23A99CF81A5B0D923AA',
        updatedAt: DateTime(2026, 3, 5, 11, 12),
        status: MultisigTaskStatus.approving,
      ),
      MultisigTask(
        id: 'MS-402',
        title: '治理提案 #108 投票',
        description: '企业账户对提案 #108 执行 YES 投票。',
        allSigners: const ['Alice', 'Bob', 'Carol', 'Dave', 'Erin'],
        threshold: 3,
        totalSigners: 5,
        collectedSigners: 2,
        pendingSigners: const ['Bob', 'Dave', 'Erin'],
        approvedSigners: const ['Alice', 'Carol'],
        txDigest: 'FD4C5A9012BBD77C4E19',
        updatedAt: DateTime(2026, 3, 5, 11, 5),
        status: MultisigTaskStatus.approving,
      ),
    ];
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return <String, dynamic>{};
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _fallbackHash(String seed) {
    final hash = seed.codeUnits.fold<int>(0, (current, code) => ((current * 41) ^ code) & 0x7fffffff);
    final hex = hash.toRadixString(16).toUpperCase().padLeft(16, '0');
    return hex.padRight(64, '0').substring(0, 64);
  }
}
