// lib/screens/student/room_list_screen.dart
// ─────────────────────────────────────────────
// Lists all rooms in a selected building.
// Uses ListView (not GridView) so cards never
// overflow regardless of content length.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/room.dart';
import 'package:kaye/theme/app_theme.dart';
import 'package:kaye/widgets/room_card.dart';
import 'package:kaye/screens/student/room_detail_screen.dart';

class RoomListScreen extends StatefulWidget {
  final String building;
  const RoomListScreen({super.key, required this.building});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.building} Building',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildLegendAndFilter(),
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  // ── Legend + Filter combined ──────────────

  Widget _buildLegendAndFilter() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _legendDot(AppColors.available, 'Available'),
              const SizedBox(width: 16),
              _legendDot(AppColors.occupied,  'Occupied'),
              const SizedBox(width: 16),
              _legendDot(AppColors.reserved,  'Reserved'),
            ],
          ),
          const SizedBox(height: 10),

          // Filter chips — scrollable so they never wrap/overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all',       'All'),
                _filterChip('available', 'Available'),
                _filterChip('occupied',  'Occupied'),
                _filterChip('reserved',  'Reserved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isActive = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Room List ─────────────────────────────
  // ListView instead of GridView — cards grow
  // with their content, zero overflow risk.

  Widget _buildRoomList() {
    return StreamBuilder<List<Room>>(
      stream: AppData.roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!
            .where((r) => r.building == widget.building)
            .toList();

        final rooms = switch (_filter) {
          'available' => all.where((r) => r.status == RoomStatus.available).toList(),
          'occupied' => all.where((r) => r.status == RoomStatus.occupied).toList(),
          'reserved' => all.where((r) => r.status == RoomStatus.reserved).toList(),
          _ => all,
        };

        if (rooms.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'No rooms match this filter.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => RoomCard(
            room: rooms[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RoomDetailScreen(room: rooms[i])),
            ),
          ),
        );
      },
    );
  }
}