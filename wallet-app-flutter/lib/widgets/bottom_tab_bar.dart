import 'package:flutter/material.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/app_icons.dart';

class BottomTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const BottomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, // TAB_HEIGHT from Backpack extension
      decoration: const BoxDecoration(
        color: AppColorTokens.background, // theme.custom.colors.nav
        border: Border(top: BorderSide(color: AppColorTokens.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTab(0, AppIcons.balances(color: _getColor(0))),
          _buildTab(1, AppIcons.collectibles(color: _getColor(1))),
          _buildTab(2, AppIcons.swap(color: _getColor(2))),
          _buildTab(3, AppIcons.apps(color: _getColor(3))),
        ],
      ),
    );
  }

  Color _getColor(int index) {
    return selectedIndex == index ? AppColorTokens.accent : AppColorTokens.textMuted;
  }

  Widget _buildTab(int index, Widget icon) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: Center(child: icon),
      ),
    );
  }
}
