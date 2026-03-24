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
    // Activity tab shows date-grouped items with multiple "已发送" entries
    expect(find.text('已发送'), findsWidgets);

    await tester.tap(find.text('NFTs'));
    await tester.pumpAndSettle();
    // NFT tab shows NFT cards, not "Mad Lads #1844"
    expect(find.text('Soulon'), findsOneWidget);
  });

  testWidgets('发送页面展示收件人输入', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSendPage()));

    // Current send page is a recipient-entry page with one TextField and a "下一步" button
    expect(find.text('发送'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'cosmos1abcdefghijklmnopqrstuvwx20');
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsOneWidget);
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

  testWidgets('主导航可进入发送选择代币页', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: WalletRoutes.replicaMobileHome,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    // Tap "发送" action button on home page
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    // Send route now shows token select page
    expect(find.text('选择代币'), findsOneWidget);
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
