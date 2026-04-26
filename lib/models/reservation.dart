// lib/models/reservation.dart
// ─────────────────────────────────────────────
// Reservation model for tracking active bookings.
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String roomId;
  final String roomName;
  final String building;
  final String reservedBy;
  final String purpose;
  final int durationMinutes; // max 60
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.building,
    required this.reservedBy,
    required this.purpose,
    required this.durationMinutes,
    required this.createdAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> map, String docId) {
    return Reservation(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      building: map['building'] ?? '',
      reservedBy: map['reservedBy'] ?? '',
      purpose: map['purpose'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'building': building,
      'reservedBy': reservedBy,
      'purpose': purpose,
      'durationMinutes': durationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Computed end time
  DateTime get endsAt => createdAt.add(Duration(minutes: durationMinutes));

  // Human-readable end time string
  String get endsAtLabel {
    final h = endsAt.hour;
    final m = endsAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}