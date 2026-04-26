// lib/models/reservation_request.dart
// ─────────────────────────────────────────────
// A student's request to reserve a room.
// Supports purpose types: class schedule,
// group study, meeting, other.
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, rejected }

enum PurposeType { classSchedule, groupStudy, meeting, other }

class ReservationRequest {
  final String id;
  final String roomId;
  final String roomName;
  final String building;
  final String studentId;
  final String studentName;
  final String purpose;
  final int durationMinutes;
  final DateTime submittedAt;
  final DateTime reservedDate;  // NEW - specific date for reservation
  RequestStatus status;

  // ── Purpose type ──────────────────────────
  final PurposeType purposeType;

  // ── Class schedule fields (optional) ──────
  // Only filled when purposeType == classSchedule
  final String? subject;    // e.g. "Data Structures"
  final String? section;    // e.g. "BSCS 2-A"
  final String? classTime;  // e.g. "8:00 AM - 9:30 AM"

  ReservationRequest({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.building,
    required this.studentId,
    required this.studentName,
    required this.purpose,
    required this.durationMinutes,
    required this.submittedAt,
    required this.reservedDate,  // NEW
    this.status      = RequestStatus.pending,
    this.purposeType = PurposeType.other,
    this.subject,
    this.section,
    this.classTime,
  });

  factory ReservationRequest.fromMap(Map<String, dynamic> map, String docId) {
    return ReservationRequest(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      building: map['building'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      purpose: map['purpose'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reservedDate: (map['reservedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseRequestStatus(map['status']),
      purposeType: _parsePurposeType(map['purposeType']),
      subject: map['subject'],
      section: map['section'],
      classTime: map['classTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'building': building,
      'studentId': studentId,
      'studentName': studentName,
      'purpose': purpose,
      'durationMinutes': durationMinutes,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reservedDate': Timestamp.fromDate(reservedDate),
      'status': status.name,
      'purposeType': purposeType.name,
      'subject': subject,
      'section': section,
      'classTime': classTime,
    };
  }

  // ── Helpers ───────────────────────────────

  bool get isClassSchedule => purposeType == PurposeType.classSchedule;

  String get purposeTypeLabel {
    switch (purposeType) {
      case PurposeType.classSchedule: return 'Class Schedule';
      case PurposeType.groupStudy:    return 'Group Study';
      case PurposeType.meeting:       return 'Meeting';
      case PurposeType.other:         return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:  return 'Pending';
      case RequestStatus.approved: return 'Approved';
      case RequestStatus.rejected: return 'Rejected';
    }
  }

  String get endsAtLabel {
    final end    = submittedAt.add(Duration(minutes: durationMinutes));
    final h      = end.hour;
    final m      = end.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour   = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  static RequestStatus _parseRequestStatus(String? statusStr) {
    switch (statusStr) {
      case 'pending':
        return RequestStatus.pending;
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending; // default fallback
    }
  }

  static PurposeType _parsePurposeType(String? typeStr) {
    switch (typeStr) {
      case 'classSchedule':
        return PurposeType.classSchedule;
      case 'groupStudy':
        return PurposeType.groupStudy;
      case 'meeting':
        return PurposeType.meeting;
      case 'other':
        return PurposeType.other;
      default:
        return PurposeType.other; // default fallback
    }
  }
}
