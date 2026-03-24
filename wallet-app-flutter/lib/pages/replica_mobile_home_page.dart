import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_router.dart';
import '../theme/app_icons.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';
import '../pages/replica_onboarding/replica_onboarding_widgets.dart';
import 'ovd_launcher_page.dart';
import 'ovd_placeholder_page.dart';
import '../widgets/replica_wallet_bottom_nav.dart';
import '../widgets/top_tab_bar.dart';

enum HomeTab { crypto, defi, nfts, activity }

class ReplicaMobileHomePage extends StatefulWidget {
  const ReplicaMobileHomePage({super.key});

  @override
  State<ReplicaMobileHomePage> createState() => _ReplicaMobileHomePageState();
}

class _ReplicaMobileHomePageState extends State<ReplicaMobileHomePage> with SingleTickerProviderStateMixin {
  HomeTab _activeTab = HomeTab.crypto;
  final GlobalKey _portalKey = GlobalKey();
  late final AnimationController _portalController;
  Rect? _portalStartRect;
  bool _launcherOpen = false;

  @override
  void initState() {
    super.initState();
    _portalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _portalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _portalController,
          builder: (context, child) {
            final t = Curves.easeOutQuart.transform(_portalController.value);
            final size = MediaQuery.of(context).size;
            final dx = lerpDouble(0, -size.width * 0.16, t) ?? 0;
            final dy = lerpDouble(0, -size.height * 0.14, t) ?? 0;
            final scale = lerpDouble(1.0, 0.92, t) ?? 1.0;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: Opacity(opacity: 1 - (t * 0.55), child: child),
              ),
            );
          },
          child: _buildWalletScaffold(),
        ),
        if (_launcherOpen) _buildPortalOverlay(context),
      ],
    );
  }

  Widget _buildWalletScaffold() {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: ReplicaWalletBottomNav(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, WalletRoutes.swapExchange);
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, WalletRoutes.replicaExplore);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColorTokens.background,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettings),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColorTokens.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('A1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
      title: _WalletSelector(
        walletName: 'Wallet 1',
        onCopy: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied (mock)')));
        },
      ),
      actions: [
        IconButton(
          key: _portalKey,
          onPressed: _openLauncher,
          icon: const Icon(Icons.grid_view_rounded, color: AppColorTokens.textPrimary),
        ),
        const SizedBox(width: 4),
      ],
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TopTabBar(
            selectedIndex: _activeTab.index,
            tabs: const ['加密货币', 'DeFi', 'NFTs', '活动'],
            onTabSelected: (index) => setState(() => _activeTab = HomeTab.values[index]),
          ),
        ),
      ),
    );
  }

  void _openLauncher() {
    final ctx = _portalKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final topLeft = box.localToGlobal(Offset.zero);
    _portalStartRect = topLeft & box.size;
    setState(() => _launcherOpen = true);
    unawaited(SystemSound.play(SystemSoundType.click));
    _portalController.forward(from: 0);
  }

  Future<void> _closeLauncher() async {
    await _portalController.reverse();
    if (!mounted) return;
    setState(() => _launcherOpen = false);
  }

  Widget _buildPortalOverlay(BuildContext context) {
    final start = _portalStartRect;
    if (start == null) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    final center = start.center;
    final baseRadius = start.shortestSide / 2;
    final maxRadius = _maxDistanceToCorners(center, size);

    return AnimatedBuilder(
      animation: _portalController,
      builder: (context, _) {
        final t = Curves.easeOutQuart.transform(_portalController.value);
        final revealRadius = lerpDouble(baseRadius, maxRadius, t) ?? maxRadius;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PortalRipplePainter(
                  center: center,
                  t: t,
                  baseRadius: baseRadius,
                  maxRadius: maxRadius,
                ),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _CircleRevealClipper(center: center, radius: revealRadius),
                child: Material(
                  color: AppColorTokens.background,
                  child: OvdLauncherView(
                    onClose: _closeLauncher,
                    onDeposit: () => Navigator.pushNamed(context, WalletRoutes.replicaReceive),
                    onWithdraw: () => Navigator.pushNamed(context, WalletRoutes.replicaSend),
                    onSwap: () => Navigator.pushNamed(context, WalletRoutes.swapExchange),
                    onOpenTavern: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Tavern')),
                    ),
                    onOpenVault: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Vault')),
                    ),
                    onOpenBazaar: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Bazaar')),
                    ),
                    onOpenLab: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Lab')),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: start.left,
              top: start.top,
              child: Transform.scale(
                scale: lerpDouble(1.0, 0.9, t) ?? 1.0,
                child: Opacity(opacity: 1 - t, child: const _PortalFourSquares()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_activeTab) {
      case HomeTab.crypto:
        return _buildTokensList();
      case HomeTab.defi:
        return _buildPlaceholder('DeFi');
      case HomeTab.nfts:
        return _buildNfts();
      case HomeTab.activity:
        return _buildActivityList();
    }
  }

  Widget _buildTokensList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                r'$0.00',
                style: AppTypographyTokens.titleLarge.copyWith(fontSize: 44, height: 1.05),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(r'$0.00', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary)),
                  const SizedBox(width: 18),
                  Text('0%', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary)),
                  const SizedBox(width: 10),
                  const Icon(Icons.refresh, size: 18, color: AppColorTokens.textMuted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SquareAction(icon: Icons.account_balance_outlined, label: '法币', onTap: () {}),
            _SquareAction(icon: Icons.arrow_downward, label: '接收', onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaReceive)),
            _SquareAction(icon: Icons.arrow_upward, label: '发送', onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSend)),
            _SquareAction(icon: Icons.swap_horiz, label: '兑换', onTap: () => Navigator.pushReplacementNamed(context, WalletRoutes.swapExchange)),
          ],
        ),
        const SizedBox(height: 16),
        _WarningCard(
          title: '保护您的钱包安全',
          body: '备份您的恢复助记词，以防止无法访问您的资金。',
          onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsShowRecoveryPhraseWarning),
        ),
        const SizedBox(height: 10),
        const Center(child: ReplicaOnboardingDots(total: 3, currentIndex: 0)),
        const SizedBox(height: 12),
        _TokenRow(
          title: 'Solana',
          subtitle: '0 SOL',
          value: r'$0.00',
          onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaAssetDetail),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferences),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.visibility_off_outlined, size: 18, color: AppColorTokens.textSecondary),
              SizedBox(width: 8),
              Text(
                '管理代币显示',
                style: TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        '$title Coming Soon',
        style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
      ),
    );
  }

  Widget _buildNfts() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacingTokens.xl),
      child: Column(
        children: [
          _SearchField(
            hint: '搜索 NFT',
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.86,
              children: const [
                _NftCard(title: 'Soulon', subtitle: '3'),
                _NftCard(title: 'Soulon v1.2.1', subtitle: '3'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final groups = <_ActivityGroup>[
      _ActivityGroup(
        title: '2026年3月4日',
        items: const [
          _ActivityItem(
            type: _ActivityType.sent,
            primary: '已发送',
            secondary: '至: 4fCU...t9Yg',
            amount: '-0.206665 SOL',
          ),
        ],
      ),
      _ActivityGroup(
        title: '2026年3月1日',
        items: const [
          _ActivityItem(
            type: _ActivityType.received,
            primary: '收到',
            secondary: '来自: 9GXX...EqNG',
            amount: '+0.0₈1 SOL',
          ),
          _ActivityItem(
            type: _ActivityType.nft,
            primary: 'Soulon v1.2.1',
            secondary: '铸造于 Metaplex',
            amount: '-0.02016 SOL',
          ),
          _ActivityItem(
            type: _ActivityType.sent,
            primary: '已发送',
            secondary: '至: Hepi...Kk4i',
            amount: '-0.02 SOL',
          ),
          _ActivityItem(
            type: _ActivityType.nft,
            primary: 'Soulon v1.2.1',
            secondary: '铸造于 Metaplex',
            amount: '-0.02016 SOL',
          ),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.xl, vertical: 8),
      children: [
        for (final group in groups) ...[
          const SizedBox(height: 10),
          Text(group.title, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final item in group.items) ...[
            _ActivityRow(item: item),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

final class _PortalFourSquares extends StatelessWidget {
  const _PortalFourSquares();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: const Icon(Icons.grid_view_rounded, color: AppColorTokens.textPrimary, size: 20),
    );
  }
}

double _maxDistanceToCorners(Offset center, Size size) {
  double d(Offset p) => math.sqrt(math.pow(p.dx - center.dx, 2) + math.pow(p.dy - center.dy, 2));
  final a = d(Offset.zero);
  final b = d(Offset(size.width, 0));
  final c = d(Offset(0, size.height));
  final e = d(Offset(size.width, size.height));
  return math.max(math.max(a, b), math.max(c, e));
}

final class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

final class _PortalRipplePainter extends CustomPainter {
  _PortalRipplePainter({
    required this.center,
    required this.t,
    required this.baseRadius,
    required this.maxRadius,
  });

  final Offset center;
  final double t;
  final double baseRadius;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final main = lerpDouble(baseRadius, maxRadius, t) ?? maxRadius;
    final fade = (1 - t).clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColorTokens.accent.withValues(alpha: 0.18 * fade),
          AppColorTokens.accent.withValues(alpha: 0.06 * fade),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: main * 1.05));
    canvas.drawCircle(center, main * 1.05, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 3; i++) {
      final k = (t + (i * 0.18)) % 1.0;
      final r = lerpDouble(baseRadius, maxRadius, k) ?? maxRadius;
      final alpha = (1 - k).clamp(0.0, 1.0) * 0.20;
      ringPaint.color = AppColorTokens.accent.withValues(alpha: alpha);
      canvas.drawCircle(center, r, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PortalRipplePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.center != center;
  }
}

final class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColorTokens.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _NftCard extends StatelessWidget {
  const _NftCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColorTokens.surfaceSubtle,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Center(
                child: Icon(Icons.hub_outlined, size: 58, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActivityType { sent, received, nft }

final class _ActivityItem {
  const _ActivityItem({
    required this.type,
    required this.primary,
    required this.secondary,
    required this.amount,
  });

  final _ActivityType type;
  final String primary;
  final String secondary;
  final String amount;
}

final class _ActivityGroup {
  const _ActivityGroup({required this.title, required this.items});

  final String title;
  final List<_ActivityItem> items;
}

final class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final isPositive = item.amount.startsWith('+');
    final amountColor = isPositive ? AppColorTokens.success : AppColorTokens.textPrimary;

    IconData icon;
    Color iconBg = AppColorTokens.surfaceSubtle;
    Widget inner;
    if (item.type == _ActivityType.nft) {
      inner = const Icon(Icons.hub_outlined, color: AppColorTokens.textPrimary);
      icon = Icons.hub_outlined;
    } else if (item.type == _ActivityType.received) {
      icon = Icons.arrow_downward;
      inner = const Icon(Icons.arrow_downward, color: AppColorTokens.success);
    } else {
      icon = Icons.arrow_upward;
      inner = const Icon(Icons.arrow_upward, color: AppColorTokens.danger);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColorTokens.border),
            ),
            child: Center(child: inner),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.primary, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.secondary, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.amount,
            style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }
}

final class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColorTokens.border, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColorTokens.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Center(child: AppIcons.backpackLogo(color: AppColorTokens.textPrimary, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypographyTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(r'$0.00', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _WalletSelector extends StatelessWidget {
  const _WalletSelector({required this.walletName, required this.onCopy});

  final String walletName;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(Icons.bolt, size: 12, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Text(walletName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColorTokens.textSecondary),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColorTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

final class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColorTokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Icon(icon, color: AppColorTokens.accent),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

final class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(body, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColorTokens.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColorTokens.warning),
            ),
          ],
        ),
      ),
    );
  }
}
