import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/room.dart';
import 'package:kaye/models/reservation_request.dart';
import 'package:kaye/theme/app_theme.dart';
import 'package:kaye/widgets/stat_card.dart';
import 'package:kaye/screens/login_screen.dart';
import 'package:kaye/screens/admin/add_room_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _roomFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    AppData.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          StreamBuilder<List<ReservationRequest>>(
            stream: AppData.requestsStream,
            builder: (context, snapshot) {
              final pendingCount = snapshot.data
                      ?.where((r) => r.status == RequestStatus.pending)
                      .length ??
                  0;
              return Stack(
                children: [
                  TextButton(
                    onPressed: _logout,
                    child: const Text('Log out',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.occupied,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Requests'),
            Tab(text: 'Rooms'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            filter: _roomFilter,
            onFilterChange: (v) => setState(() => _roomFilter = v),
          ),
          const _RequestsTab(),
          const _RoomsTab(),
          const _StatsTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onFilterChange;
  const _OverviewTab({required this.filter, required this.onFilterChange});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: AppData.roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!;
        final rooms = switch (filter) {
          'available' => all.where((r) => r.status == RoomStatus.available).toList(),
          'occupied' => all.where((r) => r.status == RoomStatus.occupied).toList(),
          'reserved' => all.where((r) => r.status == RoomStatus.reserved).toList(),
          _ => all,
        };

        final stats = AppData.statsFromRooms(rooms);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      StatCard(
                        label: 'Total Rooms',
                        value: stats['total']!,
                        color: AppColors.primary,
                        icon: Icons.meeting_room_outlined,
                      ),
                      const SizedBox(height: 10),
                      StatCard(
                        label: 'Occupied',
                        value: stats['occupied']!,
                        color: AppColors.occupied,
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      StatCard(
                        label: 'Available',
                        value: stats['available']!,
                        color: AppColors.available,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 10),
                      StatCard(
                        label: 'Reserved',
                        value: stats['reserved']!,
                        color: AppColors.reserved,
                        icon: Icons.bookmark_border,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('all', 'All'),
                  _chip('available', 'Available'),
                  _chip('occupied', 'Occupied'),
                  _chip('reserved', 'Reserved'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...rooms.map((r) => _RoomRow(room: r)),
          ],
        );
      },
    );
  }

  Widget _chip(String value, String label) {
    final active = filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onFilterChange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReservationRequest>>(
      stream: AppData.requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pending = snapshot.data!
            .where((r) => r.status == RequestStatus.pending)
            .toList();

        if (pending.isEmpty) {
          return const Center(
            child: Text('No pending requests.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RequestAdminCard(request: pending[i]),
        );
      },
    );
  }
}

class _RequestAdminCard extends StatefulWidget {
  final ReservationRequest request;
  const _RequestAdminCard({required this.request});

  @override
  State<_RequestAdminCard> createState() => _RequestAdminCardState();
}

class _RequestAdminCardState extends State<_RequestAdminCard> {
  bool _busy = false;

  String get _endsAtLabel {
    final end = widget.request.reservedDate.add(Duration(minutes: widget.request.durationMinutes));
    final h = end.hour;
    final m = end.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get _reservedDateLabel {
    final date = widget.request.reservedDate;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 400),
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Room', '${widget.request.building} · ${widget.request.roomName}'),
            const SizedBox(height: 8),
            _infoRow('Date', _reservedDateLabel),
            const SizedBox(height: 8),
            _infoRow('Student', '${widget.request.studentName} (${widget.request.studentId})'),
            const SizedBox(height: 8),
            _infoRow('Duration', '${widget.request.durationMinutes} minutes'),
            _infoRow('Until', _endsAtLabel),
            const SizedBox(height: 8),
            _infoRow('Purpose', widget.request.purpose),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.occupied.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.occupied.withValues(alpha:0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.occupied),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once approved, it cannot be undone. The room will be reserved for the student.',
                      style: TextStyle(fontSize: 12, color: AppColors.occupied, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await AppData.approveRequest(widget.request.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 400),
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Room', '${widget.request.building} · ${widget.request.roomName}'),
            const SizedBox(height: 8),
            _infoRow('Date', _reservedDateLabel),
            const SizedBox(height: 8),
            _infoRow('Student', '${widget.request.studentName} (${widget.request.studentId})'),
            const SizedBox(height: 8),
            _infoRow('Duration', '${widget.request.durationMinutes} minutes'),
            _infoRow('Until', _endsAtLabel),
            const SizedBox(height: 8),
            _infoRow('Purpose', widget.request.purpose),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.occupied.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.occupied.withValues(alpha:0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.occupied),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once rejected, it cannot be undone.',
                      style: TextStyle(fontSize: 12, color: AppColors.occupied, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.occupied,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await AppData.rejectRequest(widget.request.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${r.building} · ${r.roomName}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${r.studentName} (${r.studentId})',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(r.purpose,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _approve,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Approve'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: AppData.roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Room',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddRoomScreen()),
            ),
          ),
          body: rooms.isEmpty
              ? const Center(
                  child: Text('No rooms yet.',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ManageRoomRow(room: rooms[i]),
                ),
        );
      },
    );
  }
}

class _ManageRoomRow extends StatelessWidget {
  final Room room;
  const _ManageRoomRow({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('${room.building} • ${room.capacity} seats',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.occupied),
            onPressed: () => _confirmDelete(context),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.occupied),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AppData.deleteRoom(room.id);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: AppData.roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data!;
        final buildings = ['Annex', 'Main', 'Tab'];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final b in buildings) ...[
              _BuildingStatsCard(
                building: b,
                stats: AppData.statsFromRooms(
                    rooms.where((r) => r.building == b).toList()),
              ),
              const SizedBox(height: 12),
            ]
          ],
        );
      },
    );
  }
}

class _BuildingStatsCard extends StatelessWidget {
  final String building;
  final Map<String, int> stats;
  const _BuildingStatsCard({required this.building, required this.stats});

  Color get _color {
    return switch (building) {
      'Annex' => const Color(0xFF6366F1),
      'Main' => const Color(0xFF0EA5E9),
      'Tab' => const Color(0xFF10B981),
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = stats['total']!;
    final available = stats['available']!;
    final pct = total > 0 ? available / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$building Building',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('$total rooms',
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceDim,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  final Room room;
  const _RoomRow({required this.room});

  @override
  Widget build(BuildContext context) {
    final isReserved = room.status == RoomStatus.occupied || room.status == RoomStatus.reserved;

    return GestureDetector(
      onTap: isReserved ? () => _showReservationDetails(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('${room.building} • ${room.capacity} seats',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  if (isReserved && room.reservedBy != null)
                    Text('Reserved by: ${room.reservedBy}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.occupied)),
                ],
              ),
            ),
            Text(room.typeLabel,
                style: const TextStyle(color: AppColors.textSecondary)),
            if (isReserved)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  void _showReservationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(room.building,
                          style: const TextStyle(
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _detailRow(Icons.person, 'Reserved By', room.reservedBy ?? 'Unknown'),
            const SizedBox(height: 12),
            _detailRow(Icons.description, 'Purpose', room.reservationPurpose ?? 'Not specified'),
            const SizedBox(height: 12),
            _detailRow(Icons.access_time, 'Until', room.occupiedUntil ?? 'Not specified'),
            const SizedBox(height: 12),
            _detailRow(Icons.info_outline, 'Status', room.statusLabel),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}