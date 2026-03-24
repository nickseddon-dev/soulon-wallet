import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/app/app_router.dart';
import 'package:wallet_app_flutter/pages/replica_mobile_home_page.dart';
import 'package:wallet_app_flutter/pages/replica_receive_page.dart';
import 'package:wallet_app_flutter/pages/replica_security_confirm_page.dart';
import 'package:wallet_app_flutter/pages/replica_send_page.dart';
import 'package:wallet_app_flutter/theme/tokens/app_motion_tokens.dart';

void main() {
  test('replica 路由使用统一转场配置', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: WalletRoutes.replicaSend),
    );

    expect(route, isA<PageRouteBuilder<void>>());
    final pageRoute = route as PageRouteBuilder<void>;
    expect(pageRoute.transitionDuration, AppMotionTokens.normal);
    expect(pageRoute.reverseTransitionDuration, AppMotionTokens.fast);
  });

  testWidgets('replica 首页支持导航切换并渲染入场列表', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaMobileHomePage()));

    // Home page uses TopTabBar, not AnimatedSwitcher
    expect(find.text('加密货币'), findsOneWidget);
    expect(find.text('Solana'), findsOneWidget);

    await tester.tap(find.text('活动'));
    await tester.pumpAndSettle();
    // Activity tab shows date-grouped activity items
    expect(find.text('已发送'), findsWidgets);

    await tester.tap(find.text('NFTs'));
    await tester.pumpAndSettle();
    expect(find.text('Soulon'), findsWidgets);
  });

  testWidgets('replica 发送页面展示收件人输入', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSendPage()));

    // Current send page is a recipient entry page with address input
    expect(find.text('发送'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    // Enter recipient address
    await tester.enterText(find.byType(TextField).first, 'cosmos1abcdefghijklmnopqrstuvwx20');
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsOneWidget);
  });

  testWidgets('replica 接收页面展示二维码和地址', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaReceivePage()));

    // Receive page shows a QR code and address, no text fields
    expect(find.text('充值'), findsOneWidget);
    expect(find.text('复制地址'), findsOneWidget);
    expect(find.textContaining('QEF7'), findsOneWidget);
  });

  testWidgets('replica 安全确认页面校验失败与成功状态可切换', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSecurityConfirmPage()));

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('验证并确认'));
    await tester.pump();
    await tester.pump(AppMotionTokens.fast);
    expect(find.text('请先完成人脸或指纹确认'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('验证并确认'));
    await tester.pump();
    await tester.pump(AppMotionTokens.fast);
    expect(find.text('安全确认通过，可继续执行敏感操作'), findsOneWidget);
  });
}
