import 'package:kaye/models/room.dart';
import 'package:kaye/models/user.dart';
import 'package:kaye/models/reservation.dart';
import 'package:kaye/models/reservation_request.dart';
import 'package:kaye/repositories/room_repository.dart';
import 'package:kaye/repositories/user_repository.dart';
import 'package:kaye/repositories/request_repository.dart';
import 'package:kaye/repositories/reservation_repository.dart';

class AppData {
  AppData._();

  // Session
  static AppUser? currentUser;

  // Auth
  static Future<AppUser?> loginStudent(String id, String password) async {
    final user = await UserRepository.instance.loginStudent(id, password);
    currentUser = user;
    return user;
  }

  static Future<AppUser?> loginAdmin(String id, String password, String email) async {
    final user = await UserRepository.instance.loginAdmin(id, password, email);
    currentUser = user;
    return user;
  }

  static Future<AppUser?> registerStudent({
    required String name,
    required String id,
    required String email,
    required String password,
  }) async {
    final user = await UserRepository.instance.registerStudent(
        name: name,
        id: id,
        email: email,
        password: password,
      );
    return user;
  }

  static void logout() {
    UserRepository.instance.logout();
    currentUser = null;
  }

  // Rooms — expose streams for screens that use StreamBuilder
  static Stream<List<Room>> get roomsStream =>
      RoomRepository.instance.roomsStream();

  static Future<List<Room>> get rooms =>
      RoomRepository.instance.fetchRooms();

  static Future<List<Room>> roomsForBuilding(String b) =>
      RoomRepository.instance.fetchRoomsForBuilding(b);

  static Future<Room?> findRoom(String id) =>
      RoomRepository.instance.fetchRoom(id);

  static Future<Room> addRoom({
    required String building,
    required String name,
    required int capacity,
  }) =>
      RoomRepository.instance.addRoom(
        building: building,
        name: name,
        capacity: capacity,
      );

  static Future<void> deleteRoom(String id) =>
      RoomRepository.instance.deleteRoom(id);

  // Auto-expire reservations
  static Future<void> checkAndExpireReservations() =>
      RoomRepository.instance.checkAndExpireReservations();

  // Requests
  static Stream<List<ReservationRequest>> get requestsStream =>
      RequestRepository.instance.allRequestsStream();

  static Stream<List<ReservationRequest>> get myRequestsStream =>
      RequestRepository.instance.myRequestsStream(currentUser?.id ?? '');

  static Future<ReservationRequest?> submitRequest({
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
  }) =>
      RequestRepository.instance.submitRequest(
        roomId: roomId,
        roomName: roomName,
        building: building,
        studentId: studentId,
        studentName: studentName,
        purpose: purpose,
        durationMinutes: durationMinutes,
        reservedDate: reservedDate,  // NEW
        purposeType: purposeType,
        subject: subject,
        section: section,
        classTime: classTime,
      );

  static Future<void> approveRequest(String id) =>
      RequestRepository.instance.approveRequest(id);

  static Future<void> rejectRequest(String id) =>
      RequestRepository.instance.rejectRequest(id);

  // Reservations
  static Stream<List<Reservation>> get reservationsStream =>
      ReservationRepository.instance.reservationsStream();

  static Future<void> cancelReservation(String id) =>
      ReservationRepository.instance.cancelReservation(id);

  // Check existing reservation (for duplicate prevention)
  static Future<ReservationRequest?> checkExistingReservationForDate(String roomId, DateTime date) async {
    final studentId = currentUser?.id;
    if (studentId == null) return null;
    return RequestRepository.instance.getExistingReservationForDate(studentId, roomId, date);
  }

  // Stats — derived from stream, used in UI
  static Map<String, int> statsFromRooms(List<Room> rooms) => {
    'total': rooms.length,
    'available': rooms.where((r) => r.status == RoomStatus.available).length,
    'occupied': rooms.where((r) => r.status == RoomStatus.occupied).length,
    'reserved': rooms.where((r) => r.status == RoomStatus.reserved).length,
  };

  // Admin credentials — still hardcoded as fallback but real auth via Firebase
  static const String adminId = 'admin';
  static const String adminPassword = 'admin123';
  static const String adminName = 'Administrator';
  static const String adminEmail = 'admin@roomready.app';
}