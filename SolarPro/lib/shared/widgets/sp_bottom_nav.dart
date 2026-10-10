import 'package:flutter/material.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class SpNavItem {
  final IconData icon;
  final String label;
  const SpNavItem({required this.icon, required this.label});
}

class SpBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<SpNavItem>? items;

  const SpBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.items,
  });

  static const _defaultItems = [
    SpNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
    SpNavItem(icon: Icons.people_rounded, label: 'Leads'),
    SpNavItem(icon: Icons.person_rounded, label: 'Customers'),
    SpNavItem(icon: Icons.inventory_2_rounded, label: 'Inventory'),
    SpNavItem(icon: Icons.menu_rounded, label: 'More'),
  ];


  @override
  Widget build(BuildContext context) {
    final navItems = items ?? _defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy800,
        border: const Border(top: BorderSide(color: AppColors.navy600, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: navItems.asMap().entries.map((e) {
              final isSelected = selectedIndex == e.key;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(e.key),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold500.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          e.value.icon,
                          size: 22,
                          color: isSelected ? AppColors.gold500 : AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.gold400 : AppColors.grey600,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        child: Text(e.value.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

