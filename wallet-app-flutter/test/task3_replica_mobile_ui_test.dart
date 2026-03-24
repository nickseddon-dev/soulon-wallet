import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/app/app_router.dart';
import 'package:wallet_app_flutter/pages/replica_mobile_home_page.dart';
import 'package:wallet_app_flutter/pages/replica_security_confirm_page.dart';
import 'package:wallet_app_flutter/pages/replica_send_page.dart';
import 'package:wallet_app_flutter/theme/tokens/app_motion_tokens.dart';

void main() {
  testWidgets('资产收藏活动视图可切换并保留收藏', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaMobileHomePage()));

    expect(find.text('加密货币'), findsOneWidget);
    expect(find.text('Solana'), findsOneWidget);

    await tester.tap(find.text('活动'));
    await tester.pumpAndSettle();
    expect(find.text('最近活动'), findsOneWidget);

    await tester.tap(find.text('NFTs'));
    await tester.pumpAndSettle();
    expect(find.text('Mad Lads #1844'), findsOneWidget);
  });

  testWidgets('发送页面按三步流程完成提交', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSendPage()));

    await tester.enterText(find.byType(TextField).at(0), 'cosmos1abcdefghijklmnopqrstuvwx20');
    await tester.enterText(find.byType(TextField).at(1), '12.5');
    await tester.tap(find.text('下一步：确认'));
    await tester.pump();
    await tester.tap(find.text('提交发送'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('发送完成'), findsOneWidget);
    expect(find.textContaining('TxHash:'), findsOneWidget);
  });

  testWidgets('安全页面需要 PIN 与生物识别共同通过', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSecurityConfirmPage()));

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('验证并确认'));
    await tester.pump();
    await tester.pump(AppMotionTokens.fast);
    expect(find.text('请先完成人脸或指纹确认'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.tap(find.text('验证并确认'));
    await tester.pump();
    await tester.pump(AppMotionTokens.fast);
    expect(find.text('安全确认通过，可继续执行敏感操作'), findsOneWidget);
  });

  testWidgets('主导航可进入发送并切换底部页签', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: WalletRoutes.replicaMobileHome,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('发送流程'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.sync_alt_rounded));
    await tester.pumpAndSettle();
    expect(find.text('进入兑换流程'), findsOneWidget);
    expect(find.text('创建钱包'), findsOneWidget);

    await tester.tap(find.text('探索'));
    await tester.pumpAndSettle();
    expect(find.text('探索面板'), findsOneWidget);
  });

  testWidgets('可进入导入钱包页并返回首页', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: WalletRoutes.replicaMobileHome,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('Wallet 1'));
    await tester.pumpAndSettle();
    expect(find.text('导入钱包'), findsAtLeastNWidgets(1));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('管理代币显示'), findsOneWidget);
  });

  testWidgets('可进入资产详情页并返回首页', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: WalletRoutes.replicaMobileHome,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('Solana'));
    await tester.pumpAndSettle();
    expect(find.text('Solana 详情'), findsOneWidget);
    expect(find.text('持仓信息'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('加密货币'), findsOneWidget);
  });
}
