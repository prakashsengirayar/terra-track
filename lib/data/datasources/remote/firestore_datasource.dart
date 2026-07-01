import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/models.dart';

abstract class RemoteDataSource {
  Future<VehicleModel?> verifyVehicle(String vehicleNumber);
  Future<List<VehicleModel>> getAllVehicles();
  Future<List<VehicleModel>> getAllVehiclesIncludingInactive();
  Future<VehicleModel?> getVehicleById(String id);
  Future<VehicleModel> createVehicle(VehicleModel vehicle);
  Future<VehicleModel> updateVehicle(VehicleModel vehicle);
  Future<bool> deleteVehicle(String id);
  Future<WorkEntryModel> createWorkEntry(WorkEntryModel entry);
  Future<WorkEntryModel> updateWorkEntry(WorkEntryModel entry);
  Future<List<WorkEntryModel>> getEntriesByVehicle(
    String vehicleName, {
    String? searchQuery,
    bool latestFirst = true,
  });
  Future<WorkEntryModel?> getEntryById(String id);
  Future<bool> isCustomerNameUnique(String name, String vehicleName, {String? excludeId});
  Future<List<String>> getNativeSuggestions(String query);
  Future<String?> uploadFile(Uint8List bytes, String path);
  Stream<List<WorkEntryModel>> watchEntriesByVehicle(String vehicleName);
  Future<AdminEntryModel> createAdminEntry(AdminEntryModel entry);
  Future<List<AdminEntryModel>> getAdminEntries({String? vehicleId});
  Future<bool> sendMessage(MessageModel message);
  Future<List<MessageModel>> getMessages({String? vehicleId});
  Future<Map<String, dynamic>> getDashboardData();
}

class FirestoreRemoteDataSource implements RemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  FirestoreRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _vehicles =>
      _firestore.collection(AppConstants.vehiclesCollection);
  CollectionReference get _entries =>
      _firestore.collection(AppConstants.workEntriesCollection);
  CollectionReference get _adminEntries =>
      _firestore.collection(AppConstants.adminEntriesCollection);
  CollectionReference get _messages =>
      _firestore.collection(AppConstants.messagesCollection);

  @override
  Future<VehicleModel?> verifyVehicle(String vehicleNumber) async {
    final target = vehicleNumber.trim().toLowerCase();
    final snap = await _vehicles.where('isActive', isEqualTo: true).get();
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final number = (data['vehicleNumber'] as String? ?? '').trim().toLowerCase();
      if (number == target) return VehicleModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<List<VehicleModel>> getAllVehicles() async {
    final snap = await _vehicles
        .where('isActive', isEqualTo: true)
        .orderBy('vehicleName')
        .get();
    return snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList();
  }

  @override
  Future<VehicleModel?> getVehicleById(String id) async {
    final doc = await _vehicles.doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromFirestore(doc);
  }

  @override
  Future<List<VehicleModel>> getAllVehiclesIncludingInactive() async {
    final snap = await _vehicles.orderBy('vehicleName').get();
    return snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList();
  }

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) async {
    final id = _uuid.v4();
    final model = VehicleModel(
      id: id,
      vehicleNumber: vehicle.vehicleNumber,
      vehicleName: vehicle.vehicleName,
      driverName: vehicle.driverName,
      isActive: vehicle.isActive,
      createdAt: DateTime.now(),
    );
    await _vehicles.doc(id).set(model.toFirestore());
    return model;
  }

  @override
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) async {
    await _vehicles.doc(vehicle.id).update(vehicle.toFirestore());
    return vehicle;
  }

  @override
  Future<bool> deleteVehicle(String id) async {
    await _vehicles.doc(id).delete();
    return true;
  }

  @override
  Future<WorkEntryModel> createWorkEntry(WorkEntryModel entry) async {
    final id = _uuid.v4();
    final model = WorkEntryModel(
      id: id,
      customerName: entry.customerName,
      nativePlace: entry.nativePlace,
      vehicleName: entry.vehicleName,
      driverName: entry.driverName,
      ratePerHour: entry.ratePerHour,
      timerDurationSeconds: entry.timerDurationSeconds,
      totalAmount: entry.totalAmount,
      paidAmount: entry.paidAmount,
      balanceAmount: entry.balanceAmount,
      status: entry.status,
      date: entry.date,
      customerPhone: entry.customerPhone,
      billPhotoUrl: entry.billPhotoUrl,
      customerPhotoUrl: entry.customerPhotoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _entries.doc(id).set(model.toFirestore());

    // Upsert native to natives collection
    await _upsertNative(entry.nativePlace);

    return model;
  }

  Future<void> _upsertNative(String native) async {
    final key = native.trim().toLowerCase();
    if (key.isEmpty) return;
    await _firestore.collection(AppConstants.nativesCollection).doc(key).set(
      {'name': native.trim(), 'key': key},
      SetOptions(merge: true),
    );
  }

  @override
  Future<WorkEntryModel> updateWorkEntry(WorkEntryModel entry) async {
    final updated = WorkEntryModel(
      id: entry.id,
      customerName: entry.customerName,
      nativePlace: entry.nativePlace,
      vehicleName: entry.vehicleName,
      driverName: entry.driverName,
      ratePerHour: entry.ratePerHour,
      timerDurationSeconds: entry.timerDurationSeconds,
      totalAmount: entry.totalAmount,
      paidAmount: entry.paidAmount,
      balanceAmount: entry.balanceAmount,
      status: entry.status,
      date: entry.date,
      customerPhone: entry.customerPhone,
      billPhotoUrl: entry.billPhotoUrl,
      customerPhotoUrl: entry.customerPhotoUrl,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
    );
    await _entries.doc(entry.id).update(updated.toFirestore());
    return updated;
  }

  @override
  Future<List<WorkEntryModel>> getEntriesByVehicle(
    String vehicleName, {
    String? searchQuery,
    bool latestFirst = true,
  }) async {
    Query query = _entries
        .where('vehicleName', isEqualTo: vehicleName)
        .orderBy('date', descending: latestFirst);

    final snap = await query.get();
    var results =
        snap.docs.map((d) => WorkEntryModel.fromFirestore(d)).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results
          .where((e) => e.customerName.toLowerCase().contains(q))
          .toList();
    }
    return results;
  }

  @override
  Stream<List<WorkEntryModel>> watchEntriesByVehicle(String vehicleName) {
    return _entries
        .where('vehicleName', isEqualTo: vehicleName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => WorkEntryModel.fromFirestore(d)).toList());
  }

  @override
  Future<WorkEntryModel?> getEntryById(String id) async {
    final doc = await _entries.doc(id).get();
    if (!doc.exists) return null;
    return WorkEntryModel.fromFirestore(doc);
  }

  @override
  Future<bool> isCustomerNameUnique(
    String name,
    String vehicleName, {
    String? excludeId,
  }) async {
    // Name must be unique globally (across all vehicles)
    final snap = await _entries
        .where('customerName', isEqualTo: name.trim())
        .limit(5)
        .get();

    if (snap.docs.isEmpty) return true;
    if (excludeId == null) return false;
    // Allow same entry to keep its own name
    return snap.docs.every((d) => d.id == excludeId);
  }

  @override
  Future<List<String>> getNativeSuggestions(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await _firestore
        .collection(AppConstants.nativesCollection)
        .orderBy('key')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(8)
        .get();
    return snap.docs.map((d) => d['name'] as String).toList();
  }

  @override
  Future<String?> uploadFile(Uint8List bytes, String path) async {
    // putData (Uint8List) works on Android, iOS and Web — unlike putFile
    // (dart:io File), which is unavailable on Web.
    final ref = _storage.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  @override
  Future<AdminEntryModel> createAdminEntry(AdminEntryModel entry) async {
    final id = _uuid.v4();
    final model = AdminEntryModel(
      id: id,
      vehicleId: entry.vehicleId,
      vehicleName: entry.vehicleName,
      entryType: entry.entryType,
      amount: entry.amount,
      note: entry.note,
      date: entry.date,
      createdBy: entry.createdBy,
      createdAt: DateTime.now(),
    );
    await _adminEntries.doc(id).set(model.toFirestore());
    return model;
  }

  @override
  Future<List<AdminEntryModel>> getAdminEntries({String? vehicleId}) async {
    Query q = _adminEntries.orderBy('date', descending: true);
    if (vehicleId != null) q = q.where('vehicleId', isEqualTo: vehicleId);
    final snap = await q.get();
    return snap.docs.map((d) => AdminEntryModel.fromFirestore(d)).toList();
  }

  @override
  Future<bool> sendMessage(MessageModel message) async {
    final id = _uuid.v4();
    await _messages.doc(id).set(MessageModel(
      id: id,
      vehicleId: message.vehicleId,
      vehicleName: message.vehicleName,
      messageText: message.messageText,
      sentAt: DateTime.now(),
      sentBy: message.sentBy,
      isRead: false,
    ).toFirestore());
    return true;
  }

  @override
  Future<List<MessageModel>> getMessages({String? vehicleId}) async {
    Query q = _messages.orderBy('sentAt', descending: true);
    if (vehicleId != null) q = q.where('vehicleId', isEqualTo: vehicleId);
    final snap = await q.get();
    return snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
  }

  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    final entriesSnap = await _entries.get();
    final entries =
        entriesSnap.docs.map((d) => WorkEntryModel.fromFirestore(d)).toList();
    final vehiclesSnap = await _vehicles
        .where('isActive', isEqualTo: true)
        .get();

    double totalHours = 0;
    double totalCollected = 0;
    double totalPending = 0;

    final Map<String, Map<String, dynamic>> vehicleMap = {};

    for (final e in entries) {
      totalHours += e.timerDurationSeconds / 3600;
      totalCollected += e.paidAmount;
      totalPending += e.balanceAmount;

      vehicleMap[e.vehicleName] ??= {
        'vehicleName': e.vehicleName,
        'hours': 0.0,
        'earnings': 0.0,
        'pending': 0.0,
        'count': 0,
      };
      vehicleMap[e.vehicleName]!['hours'] =
          (vehicleMap[e.vehicleName]!['hours'] as double) +
              e.timerDurationSeconds / 3600;
      vehicleMap[e.vehicleName]!['earnings'] =
          (vehicleMap[e.vehicleName]!['earnings'] as double) + e.paidAmount;
      vehicleMap[e.vehicleName]!['pending'] =
          (vehicleMap[e.vehicleName]!['pending'] as double) + e.balanceAmount;
      vehicleMap[e.vehicleName]!['count'] =
          (vehicleMap[e.vehicleName]!['count'] as int) + 1;
    }

    return {
      'totalHours': totalHours,
      'totalCollected': totalCollected,
      'totalPending': totalPending,
      'activeVehicleCount': vehiclesSnap.docs.length,
      'vehicleSummaries': vehicleMap.values.toList(),
      'vehicles':
          vehiclesSnap.docs.map((d) => VehicleModel.fromFirestore(d)).toList(),
    };
  }
}
