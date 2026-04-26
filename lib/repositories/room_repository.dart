import '../models/room.dart';
import '../services/firestore_service.dart';

class RoomRepository {
  RoomRepository._internal();
  static final RoomRepository instance = RoomRepository._internal();

  final FirestoreService _fs = FirestoreService.instance;

  // 1. Stream of all rooms
  Stream<List<Room>> roomsStream() {
    return _fs.rooms.snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Room.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Fetch all rooms (one-time)
  Future<List<Room>> fetchRooms() async {
    final snapshot = await _fs.rooms.get();
    return snapshot.docs
        .map((doc) => Room.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 3. Fetch rooms for a specific building
  Future<List<Room>> fetchRoomsForBuilding(String building) async {
    final snapshot =
        await _fs.rooms.where('building', isEqualTo: building).get();
    return snapshot.docs
        .map((doc) => Room.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 4. Fetch single room by ID
  Future<Room?> fetchRoom(String roomId) async {
    final doc = await _fs.rooms.doc(roomId).get();
    if (!doc.exists) return null;
    return Room.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // 5. Add a new room
  Future<Room> addRoom({
    required String building,
    required String name,
    required int capacity,
  }) async {
    final docRef = _fs.rooms.doc();
    final id = docRef.id;
    
    final room = Room(
      id: id,
      building: building,
      name: name,
      capacity: capacity,
      status: RoomStatus.available,
    );
    
    await docRef.set(room.toMap());
    return room;
  }

  // 6. Delete a room
  Future<void> deleteRoom(String roomId) async {
    await _fs.rooms.doc(roomId).delete();
  }

  // 7. Update room status
  Future<void> updateRoomStatus(
    String roomId,
    RoomStatus status, {
    OccupancyType? occupancyType,
    String? occupiedUntil,
    String? reservedBy,
    String? reservationPurpose,
  }) async {
    await _fs.rooms.doc(roomId).update({
      'status': status.name,
      'occupancyType': occupancyType?.name,
      'occupiedUntil': occupiedUntil,
      'reservedBy': reservedBy,
      'reservationPurpose': reservationPurpose,
    });
  }

  // 8. Clear room reservation (set back to available)
  Future<void> clearRoomReservation(String roomId) async {
    await _fs.rooms.doc(roomId).update({
      'status': RoomStatus.available.name,
      'occupancyType': null,
      'occupiedUntil': null,
      'reservedBy': null,
      'reservationPurpose': null,
    });
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timePart = parts[0];
      final period = parts.length > 1 ? parts[1] : 'AM';
      final hm = timePart.split(':');
      var hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  // 9. Check and expire expired reservations
  Future<void> checkAndExpireReservations() async {
    try {
      final rooms = await fetchRooms();
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      for (final room in rooms) {
        if (room.status == RoomStatus.reserved && room.occupiedUntil != null) {
          final occupiedMinutes = _parseTimeToMinutes(room.occupiedUntil!);
          
          if (currentMinutes > occupiedMinutes) {
            await clearRoomReservation(room.id);
          }
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
}