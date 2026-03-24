import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/app/app_router.dart';
import 'package:wallet_app_flutter/pages/foundation_home_page.dart';
import 'package:wallet_app_flutter/pages/create_wallet_page.dart';
import 'package:wallet_app_flutter/pages/swap_exchange_page.dart';

void main() {
  test('task8 路由已接入创建钱包与兑换页面', () {
    final createRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: WalletRoutes.createWallet),
    );
    final swapRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: WalletRoutes.swapExchange),
    );

    expect(createRoute, isA<PageRouteBuilder<void>>());
    expect(swapRoute, isA<PageRouteBuilder<void>>());
  });

  testWidgets('创建钱包页覆盖空态、错误态、成功态', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateWalletPage()));

    expect(find.text('待创建'), findsOneWidget);
    expect(find.textContaining('请先填写钱包信息'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('创建失败'), findsOneWidget);
    expect(find.text('钱包名称不能为空'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '主钱包');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认创建'));
    await tester.pumpAndSettle();
    expect(find.text('创建成功'), findsOneWidget);
    expect(find.textContaining('已创建'), findsOneWidget);
  });

  testWidgets('兑换页覆盖空态、错误态、成功态', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SwapExchangePage()));

    expect(find.text('待兑换'), findsWidgets);
    expect(find.textContaining('待兑换'), findsWidgets);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('兑换失败'), findsOneWidget);
    expect(find.text('请输入有效的兑换数量'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '2.5');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认兑换'));
    await tester.pumpAndSettle();
    expect(find.text('兑换提交成功'), findsOneWidget);
    expect(find.textContaining('→'), findsWidgets);
    expect(find.textContaining('订单号：SWAP-'), findsWidgets);
  });

  testWidgets('首页包含创建钱包与兑换入口按钮', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FoundationHomePage()));
    await tester.scrollUntilVisible(
      find.text('创建钱包（P0）'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('创建钱包（P0）'), findsOneWidget);
    expect(find.text('兑换（P0）'), findsOneWidget);
  });
}
