import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class OvdLauncherPage extends StatelessWidget {
  const OvdLauncherPage({
    super.key,
    required this.onClose,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSwap,
    required this.onOpenTavern,
    required this.onOpenVault,
    required this.onOpenBazaar,
    required this.onOpenLab,
  });

  final VoidCallback onClose;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSwap;
  final VoidCallback onOpenTavern;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenBazaar;
  final VoidCallback onOpenLab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      body: SafeArea(
        child: OvdLauncherView(
          onClose: onClose,
          onDeposit: onDeposit,
          onWithdraw: onWithdraw,
          onSwap: onSwap,
          onOpenTavern: onOpenTavern,
          onOpenVault: onOpenVault,
          onOpenBazaar: onOpenBazaar,
          onOpenLab: onOpenLab,
        ),
      ),
    );
  }
}

final class OvdLauncherView extends StatefulWidget {
  const OvdLauncherView({
    super.key,
    required this.onClose,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSwap,
    required this.onOpenTavern,
    required this.onOpenVault,
    required this.onOpenBazaar,
    required this.onOpenLab,
  });

  final VoidCallback onClose;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSwap;
  final VoidCallback onOpenTavern;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenBazaar;
  final VoidCallback onOpenLab;

  @override
  State<OvdLauncherView> createState() => _OvdLauncherViewState();
}

class _OvdLauncherViewState extends State<OvdLauncherView> with SingleTickerProviderStateMixin {
  late final AnimationController _sidebarController;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  bool get _sidebarOpen => _sidebarController.value > 0;

  Future<void> _toggleSidebar() async {
    if (_sidebarController.isAnimating) return;
    if (_sidebarOpen) {
      await _sidebarController.reverse();
    } else {
      await _sidebarController.forward();
    }
  }

  Future<void> _closeSidebar() async {
    if (_sidebarController.isAnimating) return;
    await _sidebarController.reverse();
  }

  Future<void> _openWalletHome() async {
    await _closeSidebar();
    if (!mounted) return;
    Navigator.pushNamed(context, WalletRoutes.replicaMobileHome);
  }

  Future<void> _startWalletOnboarding() async {
    await _closeSidebar();
    if (!mounted) return;
    Navigator.pushNamed(context, WalletRoutes.replicaOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DepthBackground(),
        Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _HamburgerButton(onTap: _toggleSidebar),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 10),
              const _StatusStream(),
              const SizedBox(height: 18),
              const _BalanceHeader(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _TopAction(label: '充值', onTap: widget.onDeposit)),
                  const SizedBox(width: 10),
                  Expanded(child: _TopAction(label: '提现', onTap: widget.onWithdraw)),
                  const SizedBox(width: 10),
                  Expanded(child: _TopAction(label: '兑换', onTap: widget.onSwap)),
                ],
              ),
              const SizedBox(height: 18),
              const Expanded(child: _HeroHorizon()),
              const SizedBox(height: 14),
              _BottomTiles(
                onOpenTavern: widget.onOpenTavern,
                onOpenVault: widget.onOpenVault,
                onOpenBazaar: widget.onOpenBazaar,
                onOpenLab: widget.onOpenLab,
              ),
            ],
          ),
        ),
        _LauncherSidebarOverlay(
          animation: _sidebarController,
          onClose: _closeSidebar,
          onAddAccount: _startWalletOnboarding,
          onOpenWalletHome: _openWalletHome,
        ),
      ],
    );
  }
}

final class _LauncherSidebarOverlay extends StatelessWidget {
  const _LauncherSidebarOverlay({
    required this.animation,
    required this.onClose,
    required this.onAddAccount,
    required this.onOpenWalletHome,
  });

  final AnimationController animation;
  final VoidCallback onClose;
  final VoidCallback onAddAccount;
  final VoidCallback onOpenWalletHome;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutQuart.transform(animation.value);
        if (t <= 0) return const SizedBox.shrink();
        final size = MediaQuery.of(context).size;
        final panelWidth = min(size.width * 0.86, 380.0);
        final left = lerpDouble(-panelWidth, 0, t) ?? 0;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45 * t),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: panelWidth,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColorTokens.surface.withValues(alpha: 0.72),
                      border: Border.all(color: AppColorTokens.border),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      child: _LauncherSidebar(
                        onClose: onClose,
                        onAddAccount: onAddAccount,
                        onOpenWalletHome: onOpenWalletHome,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _LauncherSidebar extends StatelessWidget {
  const _LauncherSidebar({
    required this.onClose,
    required this.onAddAccount,
    required this.onOpenWalletHome,
  });

  final VoidCallback onClose;
  final VoidCallback onAddAccount;
  final VoidCallback onOpenWalletHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColorTokens.textPrimary),
              ),
              const Spacer(),
              const _SidebarIcon(icon: Icons.remove_red_eye_outlined),
              const SizedBox(width: 12),
              const _SidebarIcon(icon: Icons.tune_rounded),
              const SizedBox(width: 12),
              const _SidebarIcon(icon: Icons.settings_outlined),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '总余额',
            style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            r'$0.81',
            style: AppTypographyTokens.titleLarge.copyWith(fontSize: 44, height: 1.0, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Text('交易所', style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _SegmentedTabs(left: '交易账户', right: '机器人', selectedLeft: true),
          const SizedBox(height: 12),
          const _AccountCard(
            title: '主账户',
            subtitle: r'$0.81',
            badge: '主',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('钱包', style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              InkWell(
                onTap: onAddAccount,
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(Icons.add, color: AppColorTokens.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColorTokens.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: const Center(
                  child: Text('A1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account 1', style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(r'$0.00', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
                  ],
                ),
              ),
              _ChainPill(
                label: 'Solana',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.38,
              children: [
                _WalletCard(
                  title: 'Seed Vault 1',
                  subtitle: r'$0.00 | 8hyq...Zbjx',
                  leading: Icons.inventory_2_outlined,
                  onTap: onOpenWalletHome,
                ),
                _WalletCard(
                  title: 'Wallet 1',
                  subtitle: r'$0.00 | 0x2Bc...29d',
                  leading: Icons.account_balance_wallet_outlined,
                  onTap: onOpenWalletHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Icon(icon, color: AppColorTokens.textSecondary, size: 18),
    );
  }
}

final class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.left,
    required this.right,
    required this.selectedLeft,
  });

  final String left;
  final String right;
  final bool selectedLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentChip(label: left, selected: selectedLeft),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentChip(label: right, selected: !selectedLeft),
          ),
        ],
      ),
    );
  }
}

final class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColorTokens.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColorTokens.border : Colors.transparent),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypographyTokens.body.copyWith(
            fontWeight: FontWeight.w900,
            color: selected ? AppColorTokens.textPrimary : AppColorTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

final class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColorTokens.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColorTokens.border),
            ),
            child: Center(child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: AppColorTokens.textMuted),
        ],
      ),
    );
  }
}

final class _ChainPill extends StatelessWidget {
  const _ChainPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColorTokens.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
              child: const Icon(Icons.bolt, size: 12, color: AppColorTokens.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColorTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

final class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
                  child: Icon(leading, color: AppColorTokens.textPrimary, size: 18),
                ),
                const Spacer(),
                const Icon(Icons.more_vert, color: AppColorTokens.textMuted),
              ],
            ),
            const Spacer(),
            Text(title, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

final class _HamburgerButton extends StatelessWidget {
  const _HamburgerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HamburgerLine(),
              SizedBox(height: 5),
              _HamburgerLine(),
              SizedBox(height: 5),
              _HamburgerLine(),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HamburgerLine extends StatelessWidget {
  const _HamburgerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      decoration: BoxDecoration(
        color: AppColorTokens.textPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

final class _TopAction extends StatelessWidget {
  const _TopAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorTokens.surface,
          foregroundColor: AppColorTokens.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

final class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '总余额',
                style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                r'$0.81',
                style: AppTypographyTokens.titleLarge.copyWith(fontSize: 44, height: 1.0, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(r'$0.81', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary)),
                  const SizedBox(width: 14),
                  Text('0%', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: const [
            _HeaderIcon(icon: Icons.remove_red_eye_outlined),
            SizedBox(width: 12),
            _HeaderIcon(icon: Icons.tune_rounded),
            SizedBox(width: 12),
            _HeaderIcon(icon: Icons.settings_outlined),
          ],
        ),
      ],
    );
  }
}

final class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Icon(icon, color: AppColorTokens.textSecondary, size: 18),
    );
  }
}

final class _StatusStream extends StatefulWidget {
  const _StatusStream();

  @override
  State<_StatusStream> createState() => _StatusStreamState();
}

class _StatusStreamState extends State<_StatusStream> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late final String _stream;

  @override
  void initState() {
    super.initState();
    final items = [
      '[Overdrive Chian] whale tx: 124,093 OVD → 0x9b…2f',
      '[Drop] Seeker Spaceship · Epic · +1',
      '[Overdrive Chian] swap: 1,240 OVD → USDC',
      '[Drop] Vault seed minted · #0831',
      '[Overdrive Chian] bridge: 0.12 SOL → OVD',
    ];
    _stream = items.join('   •   ');
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _t = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: AppColorTokens.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final width = MediaQuery.of(context).size.width;
            final dx = lerpDouble(width, -width * 2, _t.value) ?? 0;
            return Stack(
              children: [
                Positioned(
                  left: dx,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      _stream,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColorTokens.accent,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _HeroHorizon extends StatefulWidget {
  const _HeroHorizon();

  @override
  State<_HeroHorizon> createState() => _HeroHorizonState();
}

class _HeroHorizonState extends State<_HeroHorizon> {
  late final PageController _controller;
  final List<_GameCardData> _items = const [
    _GameCardData(title: 'Seeker', subtitle: 'Spaceship', status: 'Online'),
    _GameCardData(title: 'Tavern Run', subtitle: 'Quests', status: 'New'),
    _GameCardData(title: 'Bazaar Wars', subtitle: 'Market', status: 'Beta'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.74);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final page = _controller.hasClients ? (_controller.page ?? _controller.initialPage.toDouble()) : 0.0;
            final delta = (page - index).clamp(-1.0, 1.0);
            final scale = 1.0 - (delta.abs() * 0.12);
            final tilt = delta * 0.18;
            final y = (delta.abs() * 14);
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..translate(0.0, y)
              ..rotateY(tilt)
              ..scale(scale, scale);
            return Transform(
              transform: m,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: _GameCard(data: _items[index]),
          ),
        );
      },
    );
  }
}

final class _GameCardData {
  const _GameCardData({required this.title, required this.subtitle, required this.status});

  final String title;
  final String subtitle;
  final String status;
}

final class _GameCard extends StatelessWidget {
  const _GameCard({required this.data});

  final _GameCardData data;

  @override
  Widget build(BuildContext context) {
    return Tilt(
      tiltConfig: const TiltConfig(
        enableGestureSensors: true,
        enableSensorRevert: true,
        angle: 6,
        sensorMoveDuration: Duration(milliseconds: 150),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColorTokens.border),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.8),
                    radius: 1.2,
                    colors: [
                      AppColorTokens.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColorTokens.surfaceSubtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColorTokens.border),
                          ),
                          child: const Icon(Icons.gamepad_outlined, color: AppColorTokens.textPrimary),
                        ),
                        const Spacer(),
                        _Pill(text: data.status),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      data.title,
                      style: AppTypographyTokens.titleMedium.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.subtitle,
                      style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Text(
        text,
        style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

final class _BottomTiles extends StatelessWidget {
  const _BottomTiles({
    required this.onOpenTavern,
    required this.onOpenVault,
    required this.onOpenBazaar,
    required this.onOpenLab,
  });

  final VoidCallback onOpenTavern;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenBazaar;
  final VoidCallback onOpenLab;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColorTokens.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColorTokens.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Tile(label: 'Tavern', icon: Icons.local_bar_outlined, onTap: onOpenTavern)),
                  const SizedBox(width: 10),
                  Expanded(child: _Tile(label: 'Vault', icon: Icons.lock_outline_rounded, onTap: onOpenVault)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _Tile(label: 'Bazaar', icon: Icons.storefront_outlined, onTap: onOpenBazaar)),
                  const SizedBox(width: 10),
                  Expanded(child: _Tile(label: 'Lab', icon: Icons.science_outlined, onTap: onOpenLab)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Tile extends StatefulWidget {
  const _Tile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColorTokens.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColorTokens.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColorTokens.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Icon(widget.icon, color: AppColorTokens.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DepthBackground extends StatelessWidget {
  const _DepthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _AmbientGradient(),
        _StarField(),
        _AmbientLights(),
      ],
    );
  }
}

final class _AmbientGradient extends StatelessWidget {
  const _AmbientGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF04070E),
            Color(0xFF050A12),
            Color(0xFF03050B),
          ],
        ),
      ),
    );
  }
}

final class _AmbientLights extends StatelessWidget {
  const _AmbientLights();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -140,
          left: -120,
          child: _Glow(color: AppColorTokens.accent.withValues(alpha: 0.16), size: 360),
        ),
        Positioned(
          bottom: -180,
          right: -140,
          child: _Glow(color: AppColorTokens.danger.withValues(alpha: 0.10), size: 420),
        ),
      ],
    );
  }
}

final class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

final class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> {
  late final List<_Star> _stars;
  final Random _r = Random(7);

  @override
  void initState() {
    super.initState();
    _stars = List.generate(70, (_) {
      return _Star(
        dx: _r.nextDouble(),
        dy: _r.nextDouble(),
        radius: 0.7 + _r.nextDouble() * 1.6,
        alpha: 0.12 + _r.nextDouble() * 0.22,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(_stars),
      size: Size.infinite,
    );
  }
}

final class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.alpha,
  });

  final double dx;
  final double dy;
  final double radius;
  final double alpha;
}

final class _StarPainter extends CustomPainter {
  const _StarPainter(this.stars);

  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in stars) {
      paint.color = Colors.white.withValues(alpha: s.alpha);
      canvas.drawCircle(Offset(size.width * s.dx, size.height * s.dy), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}
