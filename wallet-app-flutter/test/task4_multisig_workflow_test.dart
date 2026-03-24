import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/state/notification_multisig_demo_store.dart';

void main() {
  test('M-of-N 在线审批可推进到阈值', () async {
    final store = MultisigWorkbenchStore.test(
      submitter: (_) async => const MultisigOnChainReceipt(
        txHash: 'ABCDEF00112233445566778899',
        height: 910001,
        confirmed: true,
        statusText: '链上确认成功',
      ),
      seedTasks: [
        MultisigTask(
          id: 'MS-T401',
          title: '企业预算审批',
          description: '预算转账 500 SOUL',
          allSigners: const ['Alice', 'Bob', 'Carol'],
          threshold: 2,
          totalSigners: 3,
          collectedSigners: 1,
          pendingSigners: const ['Bob', 'Carol'],
          approvedSigners: const ['Alice'],
          txDigest: 'D1E2F3A4B5C6D7E8F901',
          updatedAt: DateTime(2026, 3, 6, 10, 0),
          status: MultisigTaskStatus.approving,
        ),
      ],
    );
    addTearDown(store.dispose);

    await store.approveTask('MS-T401', 'Bob');

    final task = store.value.tasks.first;
    expect(task.collectedSigners, 2);
    expect(task.status, MultisigTaskStatus.ready);
    expect(task.requiredSignatures, 0);
    expect(task.pendingSigners, contains('Carol'));
  });

  test('离线签名导入会做合并验证并过滤异常签名', () async {
    final store = MultisigWorkbenchStore.test(
      submitter: (_) async => const MultisigOnChainReceipt(
        txHash: 'ABCDEF00112233445566778899',
        height: 910001,
        confirmed: true,
        statusText: '链上确认成功',
      ),
      seedTasks: [
        MultisigTask(
          id: 'MS-T402',
          title: '治理投票审批',
          description: '提案 #109 投票',
          allSigners: const ['Alice', 'Bob', 'Carol', 'Dave'],
          threshold: 3,
          totalSigners: 4,
          collectedSigners: 1,
          pendingSigners: const ['Bob', 'Carol', 'Dave'],
          approvedSigners: const ['Alice'],
          txDigest: 'AA11BB22CC33DD44EE55',
          updatedAt: DateTime(2026, 3, 6, 10, 1),
          status: MultisigTaskStatus.approving,
        ),
      ],
    );
    addTearDown(store.dispose);

    await store.importOfflineSignatures(
      taskId: 'MS-T402',
      payload: '''
Bob:0x12AB34CD56EF:AA11BB22CC33DD44EE55
Bob:0x99887766AA11:AA11BB22CC33DD44EE55
Carol:0xFFEE11223344:BADBADBADBADBADBAD
Mallory:0x11AA22BB33CC:AA11BB22CC33DD44EE55
''',
    );

    final task = store.value.tasks.first;
    expect(task.approvedSigners, containsAll(['Alice', 'Bob']));
    expect(task.pendingSigners, isNot(contains('Bob')));
    expect(task.collectedSigners, 2);
    expect(task.lastImportEntries.length, 4);
    expect(task.lastImportEntries.where((entry) => entry.accepted).length, 1);
    expect(task.lastImportEntries.where((entry) => !entry.accepted).length, 3);
  });

  test('阈值达成后可链上提交并回写审批结果', () async {
    final store = MultisigWorkbenchStore.test(
      submitter: (_) async => const MultisigOnChainReceipt(
        txHash: 'TXHASH99887766554433221100AABBCCDDEEFF00112233445566778899AABBCC',
        height: 920888,
        confirmed: true,
        statusText: '链上确认成功',
      ),
      seedTasks: [
        MultisigTask(
          id: 'MS-T403',
          title: '运营付款审批',
          description: '供应商结算 1200 SOUL',
          allSigners: const ['Alice', 'Bob', 'Carol'],
          threshold: 2,
          totalSigners: 3,
          collectedSigners: 2,
          pendingSigners: const ['Carol'],
          approvedSigners: const ['Alice', 'Bob'],
          txDigest: 'C0FFEE1234567890ABCD',
          updatedAt: DateTime(2026, 3, 6, 10, 2),
          status: MultisigTaskStatus.ready,
        ),
      ],
    );
    addTearDown(store.dispose);

    await store.submitTaskOnChain('MS-T403');

    final task = store.value.tasks.first;
    expect(task.status, MultisigTaskStatus.confirmed);
    expect(task.onChainTxHash, isNotNull);
    expect(task.onChainHeight, 920888);
    expect(task.approvalLogs.where((log) => log.contains('审批回写')).length, 2);
  });
}
