import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { available, occupied, reserved }

enum OccupancyType { classSchedule, meeting, reserved }

class Room {
  final String id;
  final String building;
  final String name;
  final int capacity;
  RoomStatus status;
  OccupancyType? occupancyType;
  String? occupiedUntil;
  DateTime? reservedDate;  // NEW
  String? reservedBy;
  String? reservationPurpose;

  Room({
    required this.id,
    required this.building,
    required this.name,
    required this.capacity,
    required this.status,
    this.occupancyType,
    this.occupiedUntil,
    this.reservedDate,
    this.reservedBy,
    this.reservationPurpose,
  });

  factory Room.fromMap(Map<String, dynamic> map, String docId) {
    return Room(
      id: docId,
      building: map['building'] ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 0,
      status: _parseRoomStatus(map['status']),
      occupancyType: _parseOccupancyType(map['occupancyType']),
      occupiedUntil: map['occupiedUntil'],
      reservedDate: (map['reservedDate'] as Timestamp?)?.toDate(),
      reservedBy: map['reservedBy'],
      reservationPurpose: map['reservationPurpose'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'building': building,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'occupancyType': occupancyType?.name,
      'occupiedUntil': occupiedUntil,
      'reservedDate': reservedDate != null ? Timestamp.fromDate(reservedDate!) : null,
      'reservedBy': reservedBy,
      'reservationPurpose': reservationPurpose,
    };
  }

  String get statusLabel {
    switch (status) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return occupancyType == OccupancyType.classSchedule
            ? 'Class in Progress'
            : occupancyType == OccupancyType.meeting
                ? 'Meeting in Progress'
                : 'Occupied';
      case RoomStatus.reserved:
        return 'Reserved';
    }
  }

  String get typeLabel {
    if (status == RoomStatus.available) return 'Free';
    switch (occupancyType) {
      case OccupancyType.classSchedule:
        return 'Class';
      case OccupancyType.meeting:
        return 'Meeting';
      case OccupancyType.reserved:
        return 'Reserved';
      default:
        return 'Occupied';
    }
  }

  static RoomStatus _parseRoomStatus(String? statusStr) {
    switch (statusStr) {
      case 'available':
        return RoomStatus.available;
      case 'occupied':
        return RoomStatus.occupied;
      case 'reserved':
        return RoomStatus.reserved;
      default:
        return RoomStatus.available; // default fallback
    }
  }

  static OccupancyType? _parseOccupancyType(String? typeStr) {
    switch (typeStr) {
      case 'classSchedule':
        return OccupancyType.classSchedule;
      case 'meeting':
        return OccupancyType.meeting;
      case 'reserved':
        return OccupancyType.reserved;
      default:
        return null;
    }
  }

  bool get isReservationExpired {
    if (status != RoomStatus.reserved || occupiedUntil == null) return false;
    try {
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMin = now.minute;
      final period = currentHour >= 12 ? 'PM' : 'AM';
      final hour = currentHour > 12 ? currentHour - 12 : (currentHour == 0 ? 12 : currentHour);
      final currentTimeStr = '$hour:${currentMin.toString().padLeft(2, '0')} $period';
      return currentTimeStr.compareTo(occupiedUntil!) > 0;
    } catch (e) {
      return false;
    }
  }
}