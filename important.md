# 🔥 RoomReady — Firestore Integration Guide
> **Agent Instructions: Read this entire document before writing a single line of code.**

---

## 📌 What This Project Is

**RoomReady** is a Flutter mobile app for classroom/room availability and reservation management built for a school (TCGC). The app currently uses a **static in-memory data layer** (`lib/data/app_data.dart`) with no persistence — all data resets on app restart.

**Your job is to replace the entire in-memory data layer with Firebase Firestore**, wiring every operation to a real database while preserving all existing UI behavior, navigation, and logic. Nothing in the UI screens should break. Nothing in the model classes should be removed.

---

## 🏗️ Project Architecture (Current State)

```
lib/
├── main.dart                        ← App entry point
├── data/
│   └── app_data.dart                ← ⚠️ THE FILE YOU WILL REPLACE / REFACTOR
├── models/
│   ├── room.dart                    ← Room, RoomStatus, OccupancyType
│   ├── user.dart                    ← AppUser, UserRole
│   ├── reservation.dart             ← Reservation model
│   └── reservation_request.dart     ← ReservationRequest, RequestStatus, PurposeType
├── screens/
│   ├── login_screen.dart            ← Login (Admin + Student)
│   ├── signup_screen.dart           ← Student registration
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart  ← 4-tab admin panel
│   │   └── add_room_screen.dart         ← Admin adds a new room
│   └── student/
│       ├── student_home_screen.dart     ← Building picker + quick stats
│       ├── room_list_screen.dart        ← Rooms for a building
│       ├── room_detail_screen.dart      ← Room detail + request form
│       └── reques_screen.dart           ← Student's request history
├── widgets/
│   ├── building_card.dart
│   ├── room_card.dart
│   ├── room_status_badge.dart
│   └── stat_card.dart
└── theme/
    └── app_theme.dart
```

---

## 🔥 Firestore Database Design

You will create and manage the following **4 Firestore collections**. Study the field names carefully — they must match exactly.

### Collection: `rooms`
Each document = one physical room.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID (e.g. `A101`, `M102`, `T103`) |
| `building` | `String` | `"Annex"`, `"Main"`, or `"Tab"` |
| `name` | `String` | Display name e.g. `"A-101"` |
| `capacity` | `int` | Seat count |
| `status` | `String` | `"available"`, `"occupied"`, or `"reserved"` |
| `occupancyType` | `String?` | `"classSchedule"`, `"meeting"`, `"reserved"`, or `null` |
| `occupiedUntil` | `String?` | e.g. `"10:30 AM"` or `null` |
| `reservedBy` | `String?` | Student name or `null` |
| `reservationPurpose` | `String?` | e.g. `"Group Study"` or `null` |

### Collection: `users`
Each document = one registered student. Document ID = student's ID string.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Student ID e.g. `"2023-00123"` |
| `name` | `String` | Full name |
| `email` | `String` | School email |
| `passwordHash` | `String` | SHA-256 hashed password (never store plaintext) |
| `role` | `String` | Always `"student"` for registered users |
| `createdAt` | `Timestamp` | When the account was created |

### Collection: `reservation_requests`
Each document = one student's room request.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID e.g. `"REQ-001"` |
| `roomId` | `String` | Reference to `rooms` document ID |
| `roomName` | `String` | Display name (denormalized for fast reads) |
| `building` | `String` | Denormalized building name |
| `studentId` | `String` | Reference to `users` document ID |
| `studentName` | `String` | Denormalized student name |
| `purpose` | `String` | Text description of purpose |
| `purposeType` | `String` | `"classSchedule"`, `"groupStudy"`, `"meeting"`, `"other"` |
| `durationMinutes` | `int` | Duration requested (max 60) |
| `submittedAt` | `Timestamp` | When the request was submitted |
| `status` | `String` | `"pending"`, `"approved"`, or `"rejected"` |
| `subject` | `String?` | Only for classSchedule type |
| `section` | `String?` | Only for classSchedule type |
| `classTime` | `String?` | Only for classSchedule type |

### Collection: `reservations`
Each document = one active/approved reservation.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID e.g. `"RES-001"` |
| `roomId` | `String` | Reference to rooms document |
| `roomName` | `String` | Denormalized |
| `building` | `String` | Denormalized |
| `reservedBy` | `String` | Student name |
| `purpose` | `String` | Purpose text |
| `durationMinutes` | `int` | Duration |
| `createdAt` | `Timestamp` | When reservation was created |

---

## 🔐 Authentication Rules

### Firebase Authentication Setup
- **Students** authenticate using **Email + Password** via `firebase_auth`.
- **Admin** is a **single hardcoded account** created manually in the Firebase Console:
  - Email: `admin@roomready.app` (or any agreed-upon admin email)
  - The admin document in Firestore `users` collection will have `role: "admin"`.
- **No anonymous auth**. Every user must be authenticated before any Firestore read/write.
- On `login_screen.dart`, the Student tab calls `FirebaseAuth.signInWithEmailAndPassword()`.
- On `signup_screen.dart`, call `FirebaseAuth.createUserWithEmailAndPassword()` then write the user document to Firestore `users` collection.
- On logout, call `FirebaseAuth.signOut()`.
- After login, check the `users` collection to get the user's role (`student` or `admin`) and name.

### Firestore Security Rules
Apply the following rules to your Firestore database. The agent must not skip this step.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: check if the requester is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper: check if the requester is an admin
    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Helper: check if the requester owns this document
    function isOwner(studentId) {
      return isAuthenticated() && request.auth.uid == studentId;
    }

    // ── ROOMS ───────────────────────────────────────────
    match /rooms/{roomId} {
      // Anyone logged in can read rooms
      allow read: if isAuthenticated();
      // Only admin can create, update, or delete rooms
      allow create, update, delete: if isAdmin();
    }

    // ── USERS ───────────────────────────────────────────
    match /users/{userId} {
      // A user can read their own document; admin can read all
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      // A user can create their own document at signup
      allow create: if isAuthenticated() && request.auth.uid == userId;
      // Only admin can update user documents
      allow update: if isAdmin();
      // Nobody can delete user documents (admin must do it via console)
      allow delete: if false;
    }

    // ── RESERVATION REQUESTS ────────────────────────────
    match /reservation_requests/{requestId} {
      // Owner (student) or admin can read
      allow read: if isAuthenticated() &&
        (resource.data.studentId == request.auth.uid || isAdmin());
      // Only authenticated students can create requests
      allow create: if isAuthenticated() &&
        request.resource.data.studentId == request.auth.uid &&
        request.resource.data.status == 'pending';
      // Only admin can update (approve/reject)
      allow update: if isAdmin();
      // Nobody can delete requests
      allow delete: if false;
    }

    // ── RESERVATIONS ────────────────────────────────────
    match /reservations/{reservationId} {
      // All logged-in users can read (needed for room status display)
      allow read: if isAuthenticated();
      // Only admin can create, update, delete reservations
      allow create, update, delete: if isAdmin();
    }
  }
}
```

---

## 📐 OOP Architecture You Must Follow

This is a mandatory **Object-Oriented Programming** approach. Every service, repository, and model must be a proper class. No free-floating functions. No global variables. Dependency injection via constructors.

### Layer Structure to Create

```
lib/
├── services/
│   ├── auth_service.dart         ← Wraps FirebaseAuth (login, signup, logout, stream)
│   └── firestore_service.dart    ← Raw Firestore calls (CRUD wrappers only)
├── repositories/
│   ├── room_repository.dart      ← All room operations (CRUD + streams)
│   ├── user_repository.dart      ← User registration, fetch, session
│   ├── request_repository.dart   ← Submit, approve, reject requests
│   └── reservation_repository.dart ← Active reservations CRUD
├── models/
│   ├── room.dart                 ← ADD: fromMap(), toMap()
│   ├── user.dart                 ← ADD: fromMap(), toMap()
│   ├── reservation.dart          ← ADD: fromMap(), toMap()
│   └── reservation_request.dart  ← ADD: fromMap(), toMap()
└── data/
    └── app_data.dart             ← REPLACE entirely with a thin facade that
                                     delegates to repositories (keeps screens working)
```

### Class Rules
1. Each repository class has a **private constructor** and is accessed via a **singleton instance** (`static final instance = RepositoryName._internal()`).
2. Each repository holds a reference to `FirestoreService` injected via constructor or `FirestoreService.instance`.
3. `AuthService` wraps ALL Firebase Auth calls. No screen ever imports `firebase_auth` directly.
4. `FirestoreService` wraps ALL `FirebaseFirestore.instance` calls. No repository accesses Firestore directly except through this service.
5. Every model class (`Room`, `AppUser`, `Reservation`, `ReservationRequest`) must have:
   - `factory ClassName.fromMap(Map<String, dynamic> map, String docId)` — deserialize from Firestore.
   - `Map<String, dynamic> toMap()` — serialize to Firestore.
6. `AppData` becomes a **facade class** that delegates every call to the appropriate repository and `AuthService`. This keeps every screen working with zero changes.

---

## 📋 Step-by-Step Implementation Tasks

Follow these steps **in exact order**. Do not skip or reorder.

---

### STEP 1 — Add Firebase Dependencies to `pubspec.yaml`

Add the following packages:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  crypto: ^3.0.3         # for SHA-256 password hashing
```

Run `flutter pub get` after editing.

---

### STEP 2 — Initialize Firebase in `main.dart`

- Call `Firebase.initializeApp()` inside `main()` before `runApp()`.
- Use `WidgetsFlutterBinding.ensureInitialized()` (already present — keep it).
- You will receive the `google-services.json` (Android) file from the owner. Place it at `android/app/google-services.json`. Do not hardcode any API keys.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ... rest of main
}
```

---

### STEP 3 — Add `fromMap()` / `toMap()` to All Model Classes

**Room model** — add to `lib/models/room.dart`:
- `fromMap(Map<String, dynamic> map, String docId)`: parse `status` string to `RoomStatus` enum, `occupancyType` string to `OccupancyType` enum.
- `toMap()`: convert enums back to strings using their `.name` property.

**AppUser model** — add to `lib/models/user.dart`:
- `fromMap(Map<String, dynamic> map, String docId)`: parse `role` string to `UserRole`.
- `toMap()`: include `id`, `name`, `email`, `role`.

**Reservation model** — add to `lib/models/reservation.dart`:
- `fromMap`: parse `createdAt` as `Timestamp` then convert to `DateTime`.
- `toMap`: convert `createdAt` to `Timestamp`.

**ReservationRequest model** — add to `lib/models/reservation_request.dart`:
- `fromMap`: parse `status` and `purposeType` strings to enums; parse `submittedAt` as `Timestamp`.
- `toMap`: convert enums to strings using `.name`; convert `submittedAt` to `Timestamp`.

---

### STEP 4 — Create `FirestoreService`

Create `lib/services/firestore_service.dart`.

This class is a **thin wrapper** around `FirebaseFirestore.instance`. It exposes collection references and common helpers. No business logic here.

```dart
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get rooms =>
      _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get requests =>
      _db.collection('reservation_requests');
  CollectionReference<Map<String, dynamic>> get reservations =>
      _db.collection('reservations');
}
```

**Optimization rules for FirestoreService:**
- Enable Firestore offline persistence: `_db.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);` — call this once in the constructor.
- Never call `.get()` in a loop. Always use `.where()` to batch-query.

---

### STEP 5 — Create `AuthService`

Create `lib/services/auth_service.dart`.

```dart
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Returns the Firebase User on success, throws on failure
  Future<UserCredential> signIn(String email, String password) async { ... }

  // Creates the Firebase Auth account
  Future<UserCredential> signUp(String email, String password) async { ... }

  Future<void> signOut() async { ... }

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```

**Important rules:**
- Catch `FirebaseAuthException` and rethrow as meaningful messages (e.g. `"Email already in use"`, `"Wrong password"`).
- Never expose `FirebaseAuth` or `User` objects outside this service. Return `bool` or custom result objects where possible.

---

### STEP 6 — Create `UserRepository`

Create `lib/repositories/user_repository.dart`.

Methods required:
1. `Future<AppUser?> fetchUserById(String uid)` — reads `users/{uid}` from Firestore, returns `AppUser` or `null`.
2. `Future<AppUser?> loginStudent(String email, String password)` — calls `AuthService.signIn()` then fetches the user document. Sets `AppData.currentUser`.
3. `Future<AppUser?> loginAdmin(String id, String password)` — for the admin tab. The admin logs in via `AuthService.signIn()` using the admin email. Verifies the fetched user document has `role == "admin"`.
4. `Future<AppUser?> registerStudent({required String name, required String id, required String email, required String password})` — calls `AuthService.signUp()`, then writes a new document to `users/{uid}` with all fields. Checks for duplicate `id` field using a Firestore query before creating.
5. `void logout()` — calls `AuthService.signOut()`, clears `AppData.currentUser`.

**Optimization:** When checking for duplicate student ID, use `.where('id', isEqualTo: studentId).limit(1).get()` — never fetch the entire collection.

---

### STEP 7 — Create `RoomRepository`

Create `lib/repositories/room_repository.dart`.

Methods required:
1. `Stream<List<Room>> roomsStream()` — real-time stream of all rooms via `.snapshots()`. Convert each `DocumentSnapshot` using `Room.fromMap()`.
2. `Future<List<Room>> fetchRooms()` — one-time fetch of all rooms.
3. `Future<List<Room>> fetchRoomsForBuilding(String building)` — query with `.where('building', isEqualTo: building)`.
4. `Future<Room?> fetchRoom(String roomId)` — fetch single room document.
5. `Future<Room> addRoom({required String building, required String name, required int capacity})` — generate a unique ID using `FirestoreService.instance.rooms.doc().id`, write document, return the new `Room`.
6. `Future<void> deleteRoom(String roomId)` — delete the document.
7. `Future<void> updateRoomStatus(String roomId, RoomStatus status, {OccupancyType? occupancyType, String? occupiedUntil, String? reservedBy, String? reservationPurpose})` — partial update using `.update()`.
8. `Future<void> clearRoomReservation(String roomId)` — set status back to `"available"`, nullify occupancy fields.

**Optimization rules:**
- Use `Stream<List<Room>>` (Firestore real-time) for the admin overview and student home screen so stats update live without manual refreshes.
- Cache room data locally using Firestore offline persistence (already enabled in Step 4).
- Index: create a composite index in Firestore Console on `rooms` collection: `(building ASC, status ASC)`.

---

### STEP 8 — Create `RequestRepository`

Create `lib/repositories/request_repository.dart`.

Methods required:
1. `Stream<List<ReservationRequest>> allRequestsStream()` — real-time stream of ALL requests (admin use).
2. `Stream<List<ReservationRequest>> myRequestsStream(String studentId)` — real-time stream filtered by `studentId`.
3. `Future<ReservationRequest?> submitRequest({...all fields...})` — check room status first (must be `available`), then write document to `reservation_requests`. Use `FirestoreService.instance.requests.doc().id` for ID generation.
4. `Future<void> approveRequest(String requestId)` — use a Firestore **transaction** to: (a) update the request status to `"approved"`, (b) update the room status to `"reserved"` with appropriate occupancy fields, (c) create a new `reservations` document. All three writes must happen atomically.
5. `Future<void> rejectRequest(String requestId)` — update request status to `"rejected"`. Room stays untouched.

**Optimization rules:**
- `approveRequest` MUST use `FirebaseFirestore.instance.runTransaction()` — never do the three writes separately, as partial failures would corrupt the database.
- Add a Firestore index on `reservation_requests`: `(studentId ASC, submittedAt DESC)`.
- Add a Firestore index on `reservation_requests`: `(status ASC, submittedAt DESC)` for the admin pending tab.

---

### STEP 9 — Create `ReservationRepository`

Create `lib/repositories/reservation_repository.dart`.

Methods required:
1. `Stream<List<Reservation>> reservationsStream()` — real-time stream of all reservations.
2. `Future<void> cancelReservation(String reservationId)` — use a Firestore **transaction** to: (a) delete the reservation document, (b) set the room's status back to `"available"` and clear occupancy fields.

**Optimization:** Use `runTransaction()` for cancel — same reason as approveRequest.

---

### STEP 10 — Refactor `AppData` as a Facade

Replace the contents of `lib/data/app_data.dart` entirely. The new `AppData` class is a **pure facade** — it delegates every method call to the correct repository. All method signatures must stay identical so no screen requires changes.

```dart
class AppData {
  AppData._();

  // Session
  static AppUser? currentUser;

  // Auth
  static Future<AppUser?> loginStudent(String id, String password) =>
      UserRepository.instance.loginStudent(id, password);

  static Future<AppUser?> loginAdmin(String id, String password) =>
      UserRepository.instance.loginAdmin(id, password);

  static Future<AppUser?> registerStudent({...}) =>
      UserRepository.instance.registerStudent(...);

  static void logout() => UserRepository.instance.logout();

  // Rooms — expose streams for screens that use StreamBuilder
  static Stream<List<Room>> get roomsStream =>
      RoomRepository.instance.roomsStream();

  static Future<List<Room>> get rooms =>
      RoomRepository.instance.fetchRooms();

  static Future<List<Room>> roomsForBuilding(String b) =>
      RoomRepository.instance.fetchRoomsForBuilding(b);

  static Future<Room?> findRoom(String id) =>
      RoomRepository.instance.fetchRoom(id);

  static Future<Room> addRoom({...}) =>
      RoomRepository.instance.addRoom(...);

  static Future<void> deleteRoom(String id) =>
      RoomRepository.instance.deleteRoom(id);

  // Requests
  static Stream<List<ReservationRequest>> get requestsStream =>
      RequestRepository.instance.allRequestsStream();

  static Stream<List<ReservationRequest>> get myRequestsStream =>
      RequestRepository.instance.myRequestsStream(currentUser?.id ?? '');

  static Future<ReservationRequest?> submitRequest({...}) =>
      RequestRepository.instance.submitRequest(...);

  static Future<void> approveRequest(String id) =>
      RequestRepository.instance.approveRequest(id);

  static Future<void> rejectRequest(String id) =>
      RequestRepository.instance.rejectRequest(id);

  // Reservations
  static Stream<List<Reservation>> get reservationsStream =>
      ReservationRepository.instance.reservationsStream();

  static Future<void> cancelReservation(String id) =>
      ReservationRepository.instance.cancelReservation(id);

  // Stats — derived from stream, used in UI
  static Map<String, int> statsFromRooms(List<Room> rooms) => {
    'total':     rooms.length,
    'available': rooms.where((r) => r.status == RoomStatus.available).length,
    'occupied':  rooms.where((r) => r.status == RoomStatus.occupied).length,
    'reserved':  rooms.where((r) => r.status == RoomStatus.reserved).length,
  };

  // Admin credentials — still hardcoded as fallback but real auth via Firebase
  static const String adminId       = 'admin';
  static const String adminPassword = 'admin123';
  static const String adminName     = 'Administrator';
}
```

---

### STEP 11 — Update Screens to Use Async / Stream

Since `AppData` now returns `Future<>` and `Stream<>`, the following screens need targeted updates:

**`login_screen.dart`** — `_handleLogin()` already uses `await`. Change `AppData.login()` calls to `await AppData.loginStudent()` or `await AppData.loginAdmin()` based on selected role tab. Handle exceptions with try/catch and show error messages.

**`signup_screen.dart`** — `_handleSignup()` already uses `await`. Change `AppData.registerStudent()` to `await AppData.registerStudent()`. Wrap in try/catch.

**`admin_dashboard_screen.dart`** — Replace lists with `StreamBuilder<List<Room>>` and `StreamBuilder<List<ReservationRequest>>` so stats and request counts update in real time. `approveRequest` and `rejectRequest` are now `await`-ed inside `onPressed` handlers.

**`student_home_screen.dart`** — Use `StreamBuilder<List<Room>>` for the quick stats panel. Buildings list stays static (just 3 buildings).

**`room_list_screen.dart`** — Use `StreamBuilder<List<Room>>` filtered by building.

**`room_detail_screen.dart`** — `submitRequest()` is now `await`-ed. Show a loading indicator and handle errors.

**`reques_screen.dart`** — Use `StreamBuilder<List<ReservationRequest>>` via `AppData.myRequestsStream`.

---

### STEP 12 — Seed Initial Data

Write a one-time Firestore seeder function (can be a separate `dev_seeder.dart` file or a button hidden in admin debug mode). This seeder writes all the hardcoded rooms from the original `app_data.dart` to Firestore. Run it once.

Rooms to seed:
- Annex: A101–A106
- Main: M101–M105
- Tab: T101–T104

See original `app_data.dart` for all seed values. Use batch writes for efficiency:

```dart
final batch = FirebaseFirestore.instance.batch();
for (final room in seedRooms) {
  final ref = FirestoreService.instance.rooms.doc(room.id);
  batch.set(ref, room.toMap());
}
await batch.commit();
```

---

## ⚡ Optimization Requirements (Non-Negotiable)

1. **Firestore offline persistence** must be enabled (`Settings.CACHE_SIZE_UNLIMITED`).
2. **Never fetch the entire collection** when you only need one document. Always use `.doc(id).get()`.
3. **All multi-step writes** (approve request, cancel reservation) must use `runTransaction()`.
4. **Batch writes** for seeding or any operation that writes 2+ documents.
5. **`StreamBuilder`** must be used in all screens that display live data (rooms, requests, stats). No polling. No manual `setState` to refresh from Firestore.
6. **`.limit()`** must be applied on all queries where only 1 result is needed (duplicate checks, single-record lookups).
7. **Denormalize** room name and building into request and reservation documents to avoid join reads.
8. **Indexes** — create the following compound indexes in the Firestore Console:
   - `rooms`: `building` (ASC) + `status` (ASC)
   - `reservation_requests`: `studentId` (ASC) + `submittedAt` (DESC)
   - `reservation_requests`: `status` (ASC) + `submittedAt` (DESC)
9. **Error handling**: every `Future<>` call must be wrapped in try/catch. UI must show meaningful error messages — never crash silently.
10. **No duplicate listeners**: when using `StreamBuilder`, ensure the stream is only subscribed once per screen. Use `const` constructors where applicable.

---

## 🔑 API Key / Config Delivery

The project owner will provide:
- `google-services.json` → place at `android/app/google-services.json`
- Firebase Project ID, App ID, and API key (these go into `google-services.json` — do not hardcode them anywhere in Dart files)

Do not request or print the API key in any log. Do not commit `google-services.json` to version control (add to `.gitignore`).

---

## ✅ Definition of Done

The implementation is complete when:

- [ ] All 4 Firestore collections exist and are structured as specified.
- [ ] Firestore security rules are deployed and enforced.
- [ ] Student can sign up → data persists in Firestore after app restart.
- [ ] Student can log in → `AppData.currentUser` is populated from Firestore.
- [ ] Admin can log in → role verified from Firestore user document.
- [ ] Admin can add a room → appears in Firestore and in all connected screens in real time.
- [ ] Admin can delete a room → removed from Firestore immediately.
- [ ] Student can submit a reservation request → document written to `reservation_requests`.
- [ ] Admin can approve a request → transaction updates request + room + creates reservation atomically.
- [ ] Admin can reject a request → request status updated to `"rejected"`.
- [ ] Admin can cancel a reservation → transaction deletes reservation + resets room status.
- [ ] All screens that show room/request data use `StreamBuilder` (real-time updates).
- [ ] App works offline (reads from cache) and syncs when reconnected.
- [ ] No plaintext passwords stored in Firestore.
- [ ] No API keys hardcoded in Dart source files.
- [ ] All multi-step Firestore writes use transactions or batch commits.

---

## 🚫 Rules the Agent Must Never Break

1. **Never store plaintext passwords.** Use SHA-256 hash via the `crypto` package.
2. **Never import `firebase_auth` or `cloud_firestore` directly in any screen file.** All Firebase access goes through `AuthService`, `FirestoreService`, and the repositories.
3. **Never use `.get()` on a collection without a `.where()` or `.limit()` unless it is an explicit full-list fetch by design.**
4. **Never perform two or more related Firestore writes outside a transaction.**
5. **Never remove or rename any existing model class fields.** The UI depends on them.
6. **Never change any widget file's `build()` method structure** unless required by the async migration in Step 11. Keep all visual behavior identical.
7. **Never hardcode the Firestore project ID or API key** in any Dart file.