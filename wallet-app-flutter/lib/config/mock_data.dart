import '../state/notification_store.dart';
import '../state/multisig_store.dart';

final class MockData {
  const MockData._();

  static const List<String> fallbackValidators = [
    'valoper1kkmfl5f2hxn6wswazx5hfmgl9dwycjlwm3h8xx',
    'valoper1cr2v2j8tq7sy8y9m2mqlj8udx6wajk8a5r0c2y',
    'valoper1t6u95fqj9d6nnfx6j8j8tqmdt95w2f4ul6pttd',
  ];

  static List<NotificationItem> get seedNotifications => [
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
  ];

  static List<MultisigTask> get seedMultisigTasks => [
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

  static const walletConnectPendingDappName = 'YieldHub Web DApp';
  static const walletConnectPendingTopic = 'wc:yield-hub-session-2026';
  static const walletConnectPendingChainId = 'soulon-1';
  static const walletConnectPendingUri = 'wc:a1b2c3d4@2?relay-protocol=irn&symKey=abc123';
  static const walletConnectPendingPermissions = [
    'cosmos_signDirect',
    'cosmos_signAmino',
    'cosmos_getAccounts',
  ];
  static const walletConnectPendingRiskHint = '该 DApp 请求完整签名权限，请确认来源可信后再批准。';

  static const suggestChainName = 'Overdrive Chain';
  static const suggestChainId = 'overdrive-1';
  static const suggestChainRpc = 'https://rpc.overdrive.zone';
  static const suggestChainRest = 'https://api.overdrive.zone';
  static const suggestChainBech32 = 'odrv';
  static const suggestChainDenom = 'uodrv';
}
