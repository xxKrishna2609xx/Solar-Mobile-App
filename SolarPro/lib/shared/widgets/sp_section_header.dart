import 'package:flutter/material.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class SpSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SpSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gold400,
              ),
            ),
          ),
      ],
    );
  }
}
