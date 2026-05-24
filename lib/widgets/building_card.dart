// lib/widgets/building_card.dart
// ─────────────────────────────────────────────
// Tappable card for selecting a building.
// Shows available / total room count.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/theme/app_theme.dart';

class BuildingCard extends StatelessWidget {
  final String building;
  final int available;
  final int total;
  final VoidCallback onTap;

  const BuildingCard({
    super.key,
    required this.building,
    required this.available,
    required this.total,
    required this.onTap,
  });

  String get _abbrev => building[0].toUpperCase();

  Color get _color => AppColors.getBuildingColor(building);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.card(),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _abbrev,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$building Building',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$available',
                          style: TextStyle(
                            color: available > 0
                                ? AppColors.available
                                : AppColors.occupied,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total rooms free',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
