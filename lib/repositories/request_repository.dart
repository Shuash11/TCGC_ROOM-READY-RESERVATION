import '../models/room.dart';
import '../models/reservation_request.dart';
import '../models/reservation.dart';
import '../services/firestore_service.dart';

class RequestRepository {
  RequestRepository._internal();
  static final RequestRepository instance = RequestRepository._internal();

  final FirestoreService _fs = FirestoreService.instance;

  // 1. Stream of all requests (admin use)
  Stream<List<ReservationRequest>> allRequestsStream() {
    return _fs.requests.snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Stream of requests for a specific student
  Stream<List<ReservationRequest>> myRequestsStream(String studentId) {
    return _fs.requests.where('studentId', isEqualTo: studentId).snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 3. Submit a request
  Future<ReservationRequest?> submitRequest({
    required String roomId,
    required String roomName,
    required String building,
    required String studentId,
    required String studentName,
    required String purpose,
    required int durationMinutes,
    required DateTime reservedDate,  // NEW
    required PurposeType purposeType,
    String? subject,
    String? section,
    String? classTime,
  }) async {
    try {
      // First check if room is available
      final roomDoc = await _fs.rooms.doc(roomId).get();
      if (!roomDoc.exists) return null;
      
      final roomData = roomDoc.data();
      if (roomData == null || roomData['status'] != 'available') return null;
      
      // Create request document
      final docRef = _fs.requests.doc();
      final id = docRef.id;
      
      final request = ReservationRequest(
        id: id,
        roomId: roomId,
        roomName: roomName,
        building: building,
        studentId: studentId,
        studentName: studentName,
        purpose: purpose,
        durationMinutes: durationMinutes,
        submittedAt: DateTime.now(),
        reservedDate: reservedDate,  // NEW
        status: RequestStatus.pending,
        purposeType: purposeType,
        subject: subject,
        section: section,
        classTime: classTime,
      );
      
      await docRef.set(request.toMap());
      return request;
    } catch (e) {
      return null;
    }
  }

  // 4. Approve request (uses transaction)
  Future<void> approveRequest(String requestId) async {
    await _fs.runTransaction((transaction) async {
      // Get the request
      final requestDoc = await transaction.get(_fs.requests.doc(requestId));
      if (!requestDoc.exists) throw Exception('Request not found');
      
      final requestData = requestDoc.data();
      if (requestData == null) throw Exception('Request data missing');
      
      final request = ReservationRequest.fromMap(requestData, requestDoc.id);
      
      // Verify request is still pending
      if (request.status != RequestStatus.pending) {
        throw Exception('Request is not pending');
      }
      
      // Get the room
      final roomDoc = await transaction.get(_fs.rooms.doc(request.roomId));
      if (!roomDoc.exists) throw Exception('Room not found');
      
      // Update request status to approved
      transaction.update(requestDoc.reference, {
        'status': RequestStatus.approved.name,
      });
      
      // Update room status to reserved
      final endTime = request.reservedDate.add(Duration(minutes: request.durationMinutes));
      final h = endTime.hour;
      final m = endTime.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final endTimeLabel = '$hour:$m $period';
      
      transaction.update(roomDoc.reference, {
        'status': RoomStatus.reserved.name,
        'occupancyType': OccupancyType.reserved.name,
        'occupiedUntil': endTimeLabel,
        'reservedDate': request.reservedDate,
        'reservedBy': request.studentName,
        'reservationPurpose': request.purpose,
      });
      
      // Create reservation document
      final reservationRef = _fs.reservations.doc();
      final reservation = Reservation(
        id: reservationRef.id,
        roomId: request.roomId,
        roomName: request.roomName,
        building: request.building,
        reservedBy: request.studentName,
        purpose: request.purpose,
        durationMinutes: request.durationMinutes,
        createdAt: DateTime.now(),
      );
      
      transaction.set(reservationRef, reservation.toMap());
    });
  }

  // 5. Reject request
  Future<void> rejectRequest(String requestId) async {
    await _fs.requests.doc(requestId).update({
      'status': RequestStatus.rejected.name,
    });
  }

  // 6. Check if student already has pending/approved/rejected reservation for room on specific date
  Future<ReservationRequest?> getExistingReservationForDate(String studentId, String roomId, DateTime date) async {
    try {
      final snapshot = await _fs.requests
          .where('studentId', isEqualTo: studentId)
          .get();

      for (final doc in snapshot.docs) {
        final request = ReservationRequest.fromMap(doc.data(), doc.id);
        
        // Filter: same room + any status + same date (block ALL: pending, approved, rejected)
        if (request.roomId == roomId &&
            request.reservedDate.year == date.year &&
            request.reservedDate.month == date.month &&
            request.reservedDate.day == date.day) {
          return request;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}