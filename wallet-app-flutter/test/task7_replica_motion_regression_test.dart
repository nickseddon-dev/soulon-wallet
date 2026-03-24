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

    expect(find.byType(AnimatedSwitcher), findsWidgets);
    expect(find.text('Solana'), findsOneWidget);

    await tester.tap(find.text('活动'));
    await tester.pumpAndSettle();
    expect(find.text('最近活动'), findsOneWidget);

    await tester.tap(find.text('NFTs'));
    await tester.pumpAndSettle();
    expect(find.text('Mad Lads #1844'), findsOneWidget);
  });

  testWidgets('replica 发送页面表单状态切换可回归', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaSendPage()));

    await tester.tap(find.text('下一步：确认'));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效地址'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'cosmos1abcdefghijklmnopqrstuvwx20');
    await tester.enterText(find.byType(TextField).at(1), '8.8');
    await tester.tap(find.text('下一步：确认'));
    await tester.pumpAndSettle();
    expect(find.text('提交发送'), findsOneWidget);
  });

  testWidgets('replica 接收页面可展示带动效的请求结果', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReplicaReceivePage()));

    await tester.enterText(find.byType(TextField).at(0), '3.5');
    await tester.enterText(find.byType(TextField).at(1), 'coffee');
    await tester.tap(find.text('生成收款请求'));
    await tester.pumpAndSettle();

    expect(find.textContaining('soulon://receive/'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsWidgets);
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
