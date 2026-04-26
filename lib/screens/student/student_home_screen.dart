// lib/screens/student/student_home_screen.dart
// ─────────────────────────────────────────────
// Student home — choose a building to browse.
// FAB links to My Requests.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/room.dart';
import 'package:kaye/models/reservation_request.dart';
import 'package:kaye/theme/app_theme.dart';
import 'package:kaye/widgets/building_card.dart';
import 'package:kaye/screens/login_screen.dart';
import 'package:kaye/screens/student/room_list_screen.dart';
import 'package:kaye/screens/student/reques_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    AppData.checkAndExpireReservations();
  }

  void _logout(BuildContext context) {
    AppData.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('RoomReady',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // My Requests button with pending badge
          StreamBuilder<List<ReservationRequest>>(
            stream: AppData.myRequestsStream,
            builder: (context, snapshot) {
              final myPending = snapshot.data
                      ?.where((r) => r.status == RequestStatus.pending)
                      .length ??
                  0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.list_alt_outlined),
                    tooltip: 'My Requests',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen()),
                    ),
                  ),
                  if (myPending > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.occupied,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$myPending',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, ${user?.name ?? 'Student'} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a building to view available classrooms.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              // My Requests shortcut card
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const MyRequestsScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                       Icon(Icons.list_alt_outlined,
                          color: AppColors.primary, size: 22),
                       SizedBox(width: 12),
                     Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Reservation Requests',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.primary)),
                            Text('View status of your submitted requests.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                       Icon(Icons.chevron_right,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick stats
              StreamBuilder<List<Room>>(
                stream: AppData.roomsStream,
                builder: (context, snapshot) {
                  final stats =
                      AppData.statsFromRooms(snapshot.data ?? const []);
                  return _buildQuickStats(stats);
                },
              ),

              const SizedBox(height: 24),

              const Text('Buildings',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),

              // Building cards
              StreamBuilder<List<Room>>(
                stream: AppData.roomsStream,
                builder: (context, snapshot) {
                  final rooms = snapshot.data ?? const <Room>[];
                  return Column(
                    children: [
                      for (final building in ['Annex', 'Main', 'Tab'])
                        BuildingCard(
                          building: building,
                          available: rooms
                              .where((r) =>
                                  r.building == building &&
                                  r.status == RoomStatus.available)
                              .length,
                          total:
                              rooms.where((r) => r.building == building).length,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    RoomListScreen(building: building)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _pill('${stats['available']}', 'Free',     AppColors.available),
          _divider(),
          _pill('${stats['occupied']}',  'Busy',     AppColors.occupied),
          _divider(),
          _pill('${stats['reserved']}',  'Reserved', AppColors.reserved),
          _divider(),
          _pill('${stats['total']}',     'Total',    Colors.white),
        ],
      ),
    );
  }

  Widget _pill(String value, String label, Color color) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
      width: 1, height: 30, color: Colors.white.withOpacity(0.2));
}