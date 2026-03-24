import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/transaction_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class AssetDashboardPage extends StatefulWidget {
  const AssetDashboardPage({super.key});

  @override
  State<AssetDashboardPage> createState() => _AssetDashboardPageState();
}

class _AssetDashboardPageState extends State<AssetDashboardPage> {
  final TransactionDemoStore _store = TransactionDemoStore.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TransactionDemoState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final fiatRate = state.fiatRate;
        final totalFiat = state.assets.fold<double>(
          0,
          (sum, asset) => sum + asset.normalizedAmount * asset.usdPrice * fiatRate,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('资产看板与法币折算')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '资产总览',
                trailing: Text(
                  state.fiatCurrency,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColorTokens.accent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      totalFiat.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('总资产（${state.fiatCurrency}）'),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'USD', label: Text('USD')),
                        ButtonSegment(value: 'CNY', label: Text('CNY')),
                      ],
                      selected: {state.fiatCurrency},
                      onSelectionChanged: (selection) => _store.setFiatCurrency(selection.first),
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '刷新行情与折算汇率',
                      onPressed: _store.refreshAssetQuote,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前汇率：1 USD = ${state.fiatRates['CNY']!.toStringAsFixed(3)} CNY',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '资产明细',
                child: Column(
                  children: [
                    for (final asset in state.assets) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColorTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    asset.symbol,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Chip(label: Text(_protocolLabel(asset.protocol))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('余额：${asset.amount}'),
                            Text('USD 单价：${asset.usdPrice.toStringAsFixed(4)}'),
                            Text(
                              '法币估值：${(asset.normalizedAmount * asset.usdPrice * fiatRate).toStringAsFixed(2)} ${state.fiatCurrency}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletPrimaryButton(
                label: '进入交易构建仿真签名广播',
                onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionFlow),
              ),
              const SizedBox(height: 12),
              WalletPrimaryButton(
                label: '进入交易历史导出页面',
                onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionHistoryExport),
              ),
            ],
          ),
        );
      },
    );
  }

  String _protocolLabel(AssetProtocol protocol) {
    switch (protocol) {
      case AssetProtocol.native:
        return 'Native';
      case AssetProtocol.cw20:
        return 'CW20';
      case AssetProtocol.ibc:
        return 'IBC';
    }
  }
}
