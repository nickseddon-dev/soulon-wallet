import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/tokens/app_color_tokens.dart';

final class ReplicaWalletBottomNav extends StatelessWidget {
  const ReplicaWalletBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColorTokens.background,
        border: Border(top: BorderSide(color: AppColorTokens.border)),
      ),
      child: Row(
        children: [
          _Item(
            index: 0,
            selectedIndex: selectedIndex,
            label: '资产总览',
            icon: AppIcons.balances(color: _color(0)),
            onTap: onSelected,
          ),
          _Item(
            index: 1,
            selectedIndex: selectedIndex,
            label: '兑换',
            icon: AppIcons.swap(color: _color(1)),
            onTap: onSelected,
          ),
          _Item(
            index: 2,
            selectedIndex: selectedIndex,
            label: '探索',
            icon: AppIcons.apps(color: _color(2)),
            onTap: onSelected,
          ),
        ],
      ),
    );
  }

  Color _color(int index) {
    return selectedIndex == index ? AppColorTokens.accent : AppColorTokens.textMuted;
  }
}

final class _Item extends StatelessWidget {
  const _Item({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final Widget icon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColorTokens.accent : AppColorTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

