import 'package:flutter/material.dart';

import '../theme/tokens/app_color_tokens.dart';

class ReplicaAssetDetailArgs {
  const ReplicaAssetDetailArgs({
    required this.symbol,
    required this.network,
    required this.balance,
    required this.fiatValue,
  });

  final String symbol;
  final String network;
  final String balance;
  final String fiatValue;
}

class ReplicaAssetDetailPage extends StatelessWidget {
  const ReplicaAssetDetailPage({
    super.key,
    required this.args,
  });

  final ReplicaAssetDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      appBar: AppBar(
        title: Text('${args.symbol} 详情'),
        backgroundColor: const Color(0xFF070B12),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A101A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1D2430)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF40E6FF), Color(0xFF7C4DFF)],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        args.symbol,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(args.network, style: TextStyle(color: AppColorTokens.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(args.fiatValue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(args.balance, style: TextStyle(color: AppColorTokens.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            title: '持仓信息',
            rows: [
              ('可用余额', args.balance),
              ('法币估值', args.fiatValue),
              ('24h 变化', '0.00%'),
              ('网络', args.network),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            title: '最近活动',
            rows: const [
              ('接收', '来自 wallet-2 · 刚刚'),
              ('发送', '0.00 · 12 分钟前'),
              ('授权', 'DApp Session · 1 小时前'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton(label: '接收', primary: false)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton(label: '发送', primary: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<(String, String)> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          for (final row in rows) ...[
            Row(
              children: [
                Text(row.$1, style: TextStyle(color: AppColorTokens.textSecondary)),
                const Spacer(),
                Text(row.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            if (row != rows.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool primary,
  }) {
    if (primary) {
      return SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D7BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorTokens.textSecondary,
          side: const BorderSide(color: Color(0xFF2A3548)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }
}
