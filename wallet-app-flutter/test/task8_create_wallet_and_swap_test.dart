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

  testWidgets('创建钱包页渲染填写步骤与状态卡片', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateWalletPage()));
    await tester.pump();

    // Step 0 shows fill form
    expect(find.text('创建钱包流程'), findsOneWidget);
    expect(find.text('钱包名称'), findsOneWidget);
    expect(find.text('助记词长度'), findsOneWidget);

    // Scroll down to see status card
    await tester.scrollUntilVisible(
      find.text('请先填写钱包信息'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('请先填写钱包信息'), findsOneWidget);
  });

  testWidgets('兑换页渲染卖买面板与代币选择', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SwapExchangePage()));
    await tester.pumpAndSettle();

    // Swap page shows mode tabs ("兑换" appears in tab + bottom nav)
    expect(find.text('兑换'), findsWidgets);
    expect(find.text('跨链'), findsOneWidget);
    expect(find.text('卖'), findsOneWidget);
    expect(find.text('买'), findsOneWidget);

    // Scroll to see hot tokens section
    await tester.scrollUntilVisible(
      find.text('热门代币'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('热门代币'), findsOneWidget);
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
