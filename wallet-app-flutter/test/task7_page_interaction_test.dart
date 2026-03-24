import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/pages/ibc_transfer_tracking_page.dart';
import 'package:wallet_app_flutter/pages/staking_flow_page.dart';

void main() {
  testWidgets('staking flow page can execute and render chain result', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StakingFlowPage()));

    await tester.tap(find.text('执行质押流程'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('流程进度'), findsOneWidget);
    expect(find.text('参数校验'), findsOneWidget);
  });

  testWidgets('ibc page can execute transfer and complete tracking', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IbcTransferTrackingPage()));

    await tester.tap(find.text('提交 ICS-20 转账'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('契约端点: /v1/chain/txs'), findsOneWidget);
  });
}
