import '../models/reservation.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';

class ReservationRepository {
  ReservationRepository._internal();
  static final ReservationRepository instance = ReservationRepository._internal();

  final FirestoreService _fs = FirestoreService.instance;

  // 1. Stream of all reservations
  Stream<List<Reservation>> reservationsStream() {
    return _fs.reservations.snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Cancel reservation (uses transaction)
  Future<void> cancelReservation(String reservationId) async {
    await _fs.runTransaction((transaction) async {
      // Get the reservation
      final reservationDoc = await transaction.get(_fs.reservations.doc(reservationId));
      if (!reservationDoc.exists) throw Exception('Reservation not found');
      
      final reservationData = reservationDoc.data();
      if (reservationData == null) throw Exception('Reservation data missing');
      
      final reservation = Reservation.fromMap(reservationData, reservationDoc.id);
      
      // Delete reservation document
      transaction.delete(reservationDoc.reference);
      
      // Reset room status to available
      final roomDoc = await transaction.get(_fs.rooms.doc(reservation.roomId));
      if (!roomDoc.exists) throw Exception('Room not found');
      
      transaction.update(roomDoc.reference, {
        'status': RoomStatus.available.name,
        'occupancyType': null,
        'occupiedUntil': null,
        'reservedBy': null,
        'reservationPurpose': null,
      });
    });
  }
}