// lib/screens/student/my_requests_screen.dart
// ─────────────────────────────────────────────
// Student sees all their reservation requests
// and the current status: pending / approved / rejected
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/reservation_request.dart';
import 'package:kaye/theme/app_theme.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _selectedTab = 0;

  List<ReservationRequest> _filterRequests(List<ReservationRequest> requests) {
    switch (_selectedTab) {
      case 0:
        return requests.where((r) => r.status == RequestStatus.pending).toList();
      case 1:
        return requests.where((r) => r.status == RequestStatus.approved).toList();
      case 2:
        return requests.where((r) => r.status == RequestStatus.rejected).toList();
      default:
        return requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: StreamBuilder<List<ReservationRequest>>(
              stream: AppData.myRequestsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final myRequests = snapshot.data!..sort(
                  (a, b) => b.submittedAt.compareTo(a.submittedAt),
                );

                final filteredRequests = _filterRequests(myRequests);

                return filteredRequests.isEmpty
                    ? _buildEmpty(_selectedTab)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RequestCard(
                          request: filteredRequests[i],
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Pending', AppColors.reserved),
          _buildTab(1, 'Approved', AppColors.available),
          _buildTab(2, 'Rejected', AppColors.occupied),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, Color color) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha:0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(int tab) {
    final messages = {
      0: ('No pending requests.', 'Your requests waiting for approval will appear here.'),
      1: ('No approved requests.', 'Your approved room reservations will appear here.'),
      2: ('No rejected requests.', 'Your rejected requests will appear here.'),
    };
    final (title, subtitle) = messages[tab]!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Single request card ───────────────────────

class _RequestCard extends StatelessWidget {
  final ReservationRequest request;
  const _RequestCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case RequestStatus.pending:  return AppColors.reserved;
      case RequestStatus.approved: return AppColors.available;
      case RequestStatus.rejected: return AppColors.occupied;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case RequestStatus.pending:  return Icons.hourglass_top_rounded;
      case RequestStatus.approved: return Icons.check_circle_outline;
      case RequestStatus.rejected: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child:   Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored top bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room + status badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Room info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.building} · ${request.roomName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${_formatReservedDate(request.reservedDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Request ID: ${request.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _statusColor.withValues(alpha:0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon,
                              size: 14, color: _statusColor),
                          const SizedBox(width: 5),
                          Text(
                            request.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Details
                // Purpose type badge
                _buildPurposeTypeBadge(request.purposeType),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                _detailRow(Icons.notes_outlined, request.purpose),
                const SizedBox(height: 6),
                _detailRow(Icons.schedule,
                    '${request.durationMinutes} min  •  Until ${request.endsAtLabel}'),
                const SizedBox(height: 6),
                _detailRow(Icons.calendar_today_outlined,
                    _formatDate(request.submittedAt)),

                // Class schedule details
                if (request.isClassSchedule &&
                    (request.subject != null ||
                        request.section != null ||
                        request.classTime != null)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha:0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.subject != null)
                          _classDetailRow('Subject',    request.subject!),
                        if (request.section != null)
                          _classDetailRow('Section',    request.section!),
                        if (request.classTime != null)
                          _classDetailRow('Class Time', request.classTime!),
                      ],
                    ),
                  ),
                ],

                // Approved message
                if (request.status == RequestStatus.approved) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.available.withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.available),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your request was approved! The room is now reserved for you.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.available,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejected message
                if (request.status == RequestStatus.rejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.occupied.withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.occupied),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your request was rejected. Try requesting a different room.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.occupied,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
    
  
  }

  Widget _buildPurposeTypeBadge(PurposeType type) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case PurposeType.classSchedule:
        color = AppColors.primary;
        icon  = Icons.school_outlined;
        label = 'CLASS SCHEDULE';
        break;
      case PurposeType.groupStudy:
        color = const Color(0xFF10B981);
        icon  = Icons.groups_outlined;
        label = 'GROUP STUDY';
        break;
      case PurposeType.meeting:
        color = const Color(0xFF6366F1);
        icon  = Icons.handshake_outlined;
        label = 'MEETING';
        break;
      case PurposeType.other:
        color = AppColors.textMuted;
        icon  = Icons.more_horiz;
        label = 'OTHER';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _classDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final h      = dt.hour;
    final m      = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour   = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return 'Submitted ${dt.month}/${dt.day}/${dt.year} at $hour:$m $period';
  }

  String _formatReservedDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}