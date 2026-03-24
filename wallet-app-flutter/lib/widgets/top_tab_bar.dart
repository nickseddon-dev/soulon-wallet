import 'package:flutter/material.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

class TopTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  const TopTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColorTokens.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColorTokens.surfaceSubtle : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isSelected ? AppColorTokens.borderLight : Colors.transparent),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: AppTypographyTokens.body.copyWith(
                    color: isSelected ? AppColorTokens.textPrimary : AppColorTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
