// lib/screens/student/room_detail_screen.dart
// ─────────────────────────────────────────────
// Room info + "Request to Reserve" form.
// Student picks a purpose type — if Class Schedule,
// extra fields appear: subject, section, class time.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/room.dart';
import 'package:kaye/models/reservation_request.dart';
import 'package:kaye/theme/app_theme.dart';
import 'package:kaye/screens/student/reques_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _subjectController   = TextEditingController();
  final _sectionController   = TextEditingController();
  final _classTimeController = TextEditingController();
  final _purposeController   = TextEditingController();

  PurposeType _purposeType   = PurposeType.groupStudy;
  int         _durationMinutes = 30;
  DateTime    _reservedDate = DateTime.now();  // NEW - default to today
  bool        _isSubmitting  = false;
  bool        _requestSent   = false;
  ReservationRequest? _existingReservation;
  bool _checkingReservation = true;

  @override
  void initState() {
    super.initState();
    _checkExistingReservation();
  }

  Future<void> _checkExistingReservation() async {
    final existing = await AppData.checkExistingReservationForDate(widget.room.id, _reservedDate);
    if (mounted) {
      setState(() {
        _existingReservation = existing;
        _checkingReservation = false;
      });
    }
  }

  String get _reservedDateLabel {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_reservedDate.month - 1]} ${_reservedDate.day}, ${_reservedDate.year}';
  }

  String get _existingReservationDateLabel {
    if (_existingReservation == null) return '';
    final date = _existingReservation!.reservedDate;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get _existingStatusLabel {
    if (_existingReservation == null) return '';
    switch (_existingReservation!.status) {
      case RequestStatus.pending: return 'pending';
      case RequestStatus.approved: return 'approved';
      case RequestStatus.rejected: return 'rejected';
    }
  }

  // ── Status color ──────────────────────────

  Color get _statusColor {
    switch (widget.room.status) {
      case RoomStatus.available: return AppColors.available;
      case RoomStatus.occupied:  return AppColors.occupied;
      case RoomStatus.reserved:  return AppColors.reserved;
    }
  }

  // ── Submit ────────────────────────────────

  String get _endsAtLabel {
    final end = DateTime.now().add(Duration(minutes: _durationMinutes));
    final h = end.hour;
    final m = end.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final purpose = _purposeType == PurposeType.classSchedule
        ? _subjectController.text.trim()
        : _purposeController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 400),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.end,
            title: const Text('Confirm Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confRow('Room', '${widget.room.building} · ${widget.room.name}'),
            const SizedBox(height: 8),
            _confRow('Date', _reservedDateLabel),
            const SizedBox(height: 8),
            _confRow('Duration', '$_durationMinutes minutes'),
            _confRow('Until', _endsAtLabel),
            const SizedBox(height: 8),
            _confRow('Purpose Type', _purposeTypeLabel),
            _confRow('Purpose', purpose),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.occupied.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.occupied.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.occupied),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once submitted, you cannot edit or delete your request.',
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
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
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
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final user = AppData.currentUser;
    if (user == null) {
      setState(() {
        _isSubmitting = false;
        _requestSent = false;
      });
      return;
    }

    ReservationRequest? req;
    try {
      req = await AppData.submitRequest(
        roomId: widget.room.id,
        roomName: widget.room.name,
        building: widget.room.building,
        studentId: user.id,
        studentName: user.name,
        purpose: purpose,
        durationMinutes: _durationMinutes,
        reservedDate: _reservedDate,  // NEW
        purposeType: _purposeType,
        subject: _purposeType == PurposeType.classSchedule
            ? _subjectController.text.trim()
            : null,
        section: _purposeType == PurposeType.classSchedule
            ? _sectionController.text.trim()
            : null,
        classTime: _purposeType == PurposeType.classSchedule
            ? _classTimeController.text.trim()
            : null,
      );
    } catch (_) {
      req = null;
    }

    setState(() {
      _isSubmitting = false;
      _requestSent = req != null;
    });
  }

  Widget _confRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  String get _purposeTypeLabel {
    switch (_purposeType) {
      case PurposeType.classSchedule: return 'Class Schedule';
      case PurposeType.groupStudy: return 'Group Study';
      case PurposeType.meeting: return 'Meeting';
      case PurposeType.other: return 'Other';
    }
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.room.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
            icon: const Icon(Icons.list_alt_outlined, size: 18),
            label: const Text('My Requests', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHero(),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 24),
              if (_checkingReservation)
                const Center(child: CircularProgressIndicator())
              else if (_requestSent)
                _buildSuccessCard()
              else if (widget.room.status == RoomStatus.available)
                _buildRequestForm()
              else if (widget.room.status == RoomStatus.occupied || widget.room.status == RoomStatus.reserved)
                _buildUnavailableMessage(),
              if (_existingReservation != null) ...[
                const SizedBox(height: 16),
                _buildDuplicateWarning(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Status hero ───────────────────────────

  Widget _buildStatusHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            widget.room.status == RoomStatus.available
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: _statusColor,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            widget.room.statusLabel,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _statusColor),
          ),
          if (widget.room.occupiedUntil != null) ...[
            const SizedBox(height: 4),
            Text('Until ${widget.room.occupiedUntil}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  // ── Info card ─────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow('Building',  widget.room.building),
          _infoRow('Room',      widget.room.name),
          _infoRow('Capacity',  '${widget.room.capacity} students'),
          _infoRow('Status',    widget.room.statusLabel),
          if (widget.room.status == RoomStatus.reserved) ...[
            if (widget.room.reservedDate != null)
              _infoRow('Reserved for', _formatReservedDate(widget.room.reservedDate!)),
            if (widget.room.occupiedUntil != null)
              _infoRow('Until', widget.room.occupiedUntil!),
            if (widget.room.reservedBy != null)
              _infoRow('Reserved by', widget.room.reservedBy!),
            if (widget.room.reservationPurpose != null)
              _infoRow('Purpose', widget.room.reservationPurpose!),
          ],
          if (widget.room.reservedBy != null && widget.room.status != RoomStatus.reserved)
            _infoRow('Reserved by', widget.room.reservedBy!),
          if (widget.room.reservationPurpose != null && widget.room.status != RoomStatus.reserved)
            _infoRow('Purpose', widget.room.reservationPurpose!),
        ],
      ),
    );
  }

  String _formatReservedDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ── Request form ──────────────────────────

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bookmark_add_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request to Reserve',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('Admin will approve or reject your request.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Purpose Type Selector ──────────
          const Text('Purpose Type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _buildPurposeTypeSelector(),

          const SizedBox(height: 16),

          // ── Class Schedule Fields ──────────
          if (_purposeType == PurposeType.classSchedule) ...[
            _buildClassScheduleBanner(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Data Structures',
                prefixIcon: Icon(Icons.book_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter the subject' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sectionController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Section',
                hintText: 'e.g. BSCS 2-A',
                prefixIcon: Icon(Icons.group_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your section' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _classTimeController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Class Time',
                hintText: 'e.g. 8:00 AM - 9:30 AM',
                prefixIcon: Icon(Icons.access_time_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter the class time' : null,
            ),
            const SizedBox(height: 14),
          ],

          // ── Other Purpose Field ────────────
          if (_purposeType != PurposeType.classSchedule) ...[
            TextFormField(
              controller: _purposeController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Purpose',
                hintText: _purposeHint,
                prefixIcon: const Icon(Icons.notes_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a purpose' : null,
            ),
            const SizedBox(height: 14),
          ],

          // ── Date Picker ───────────────────────
          const Text('Reservation Date',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reservedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _reservedDate = picked;
                  _checkingReservation = true;
                });
                _checkExistingReservation();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    _reservedDateLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Duration Picker ─────────────────
          const Text('Duration',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60].map((mins) {
              final active = _durationMinutes == mins;
              return GestureDetector(
                onTap: () => setState(() => _durationMinutes = mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.border),
                  ),
                  child: Text(
                    '$mins min',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSubmitting || _existingReservation != null ? null : _submitRequest,
            style: _existingReservation != null
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textMuted.withOpacity(0.2),
                    foregroundColor: AppColors.textMuted,
                  )
                : null,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : _existingReservation != null
                    ? const Text('Request Submitted')
                    : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  // ── Duplicate warning banner ───────────────

  Widget _buildDuplicateWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.reserved.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.reserved.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.reserved),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You already have a $_existingStatusLabel reservation for this room on $_existingReservationDateLabel. You cannot reserve again for the same date.',
              style: const TextStyle(fontSize: 12, color: AppColors.reserved, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Purpose type selector ─────────────────

  Widget _buildPurposeTypeSelector() {
    final types = [
      (PurposeType.classSchedule, 'Class Schedule', Icons.school_outlined),
      (PurposeType.groupStudy,    'Group Study',    Icons.groups_outlined),
      (PurposeType.meeting,       'Meeting',        Icons.handshake_outlined),
      (PurposeType.other,         'Other',          Icons.more_horiz),
    ];

    return Column(
      children: [
        Row(
          children: types.map((t) {
            final type    = t.$1;
            final label   = t.$2;
            final icon    = t.$3;
            final active  = _purposeType == type;
            final isClass = type == PurposeType.classSchedule;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: type != PurposeType.other ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _purposeType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? (isClass
                              ? AppColors.primary
                              : AppColors.primary)
                          : AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            size: 20,
                            color: active
                                ? Colors.white
                                : AppColors.textMuted),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Class schedule banner ─────────────────

  Widget _buildClassScheduleBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
           Icon(Icons.info_outline, color: AppColors.primary, size: 18),
           SizedBox(width: 10),
           Expanded(
            child: Text(
              'Fill in your class details. Admin will verify this against your COR before approving.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String get _purposeHint {
    switch (_purposeType) {
      case PurposeType.groupStudy: return 'e.g. Finals Review, Problem Set';
      case PurposeType.meeting:    return 'e.g. Club Meeting, Org Planning';
      default:                     return 'Describe your purpose';
    }
  }

  // ── Unavailable message ───────────────────

  Widget _buildUnavailableMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.occupied.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.occupied.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.occupied, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This room is currently unavailable. Check back later or try another room.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success card ──────────────────────────

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.available.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.available.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.available, size: 52),
          const SizedBox(height: 14),
          const Text('Request Submitted!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.available)),
          const SizedBox(height: 8),
          const Text(
            'Your request is pending admin approval.\nCheck My Requests for status updates.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Rooms'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen())),
                  child: const Text('My Requests'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _sectionController.dispose();
    _classTimeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}