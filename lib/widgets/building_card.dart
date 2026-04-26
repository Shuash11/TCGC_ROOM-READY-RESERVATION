// lib/widgets/building_card.dart
// ─────────────────────────────────────────────
// Tappable card for selecting a building.
// Shows available / total room count.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  // One letter abbreviation
  String get _abbrev => building[0].toUpperCase();

  // Color per building
  Color get _color {
    switch (building) {
      case 'Annex': return const Color(0xFF6366F1);
      case 'Main':  return const Color(0xFF0EA5E9);
      case 'Tab':   return const Color(0xFF10B981);
      default:      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha :0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Letter avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _color.withValues(alpha :0.12),
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

            // Building name + sub-label
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

            // Chevron
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
