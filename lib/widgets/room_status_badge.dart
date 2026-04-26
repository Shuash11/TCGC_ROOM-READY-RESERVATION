// lib/widgets/room_status_badge.dart
// ─────────────────────────────────────────────
// Small colored badge showing room status.
// Standalone — no dependencies on other widgets.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

class RoomStatusBadge extends StatelessWidget {
  final Room room;
  final bool large;

  const RoomStatusBadge({super.key, required this.room, this.large = false});

  Color get _color {
    switch (room.status) {
      case RoomStatus.available: return AppColors.available;
      case RoomStatus.occupied:  return AppColors.occupied;
      case RoomStatus.reserved:  return AppColors.reserved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 13.0 : 11.0;
    final padding  = large
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            room.typeLabel,
            style: TextStyle(
              color: _color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
