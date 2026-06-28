// lib/data/repositories/agri_repository_impl.dart
//
// Firebase-backed repository implementations for the agricultural Land/
// Worker/Work-Entry/Expense/Harvest module. Additive — the existing
// lib/data/repositories/repository_impl.dart (vehicle/work-log module,
// dartz/Either-based, wrapping a RemoteDataSource) is left untouched.
//
// These implementations talk to Cloud Firestore directly (no datasource
// indirection layer, per the agri module's design). Every write forces
// `ownerId` to FirebaseAuth.instance.currentUser!.uid, regardless of what
// the caller passed in the entity, so data can never be written under the
// wrong owner. Every read is explicitly scoped by an `ownerId` query
// parameter (see watchAll), which callers (Riverpod providers) always
// supply as FirebaseAuth.instance.currentUser!.uid. Firestore security
// rules (firestore.rules) provide the server-side enforcement of the same
// invariant.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/agri_constants.dart';
import '../../domain/entities/agri_entities.dart';
import '../../domain/repositories/agri_repositories.dart';
import '../models/agri_models.dart';

const _uuid = Uuid();

String _requireUid() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError(
      'No authenticated user. The agri module requires a signed-in '
      'Firebase user before any read/write can be performed.',
    );
  }
  return uid;
}

// =====================================================================
// Land repository impl
// =====================================================================
class FirebaseLandRepository implements LandRepository {
  final FirebaseFirestore _firestore;

  FirebaseLandRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.landsCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addLand(LandEntity land) async {
    final uid = _requireUid();
    final id = land.id.isNotEmpty ? land.id : _uuid.v4();
    final now = DateTime.now();
    final model = LandModel.fromEntity(
      land.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateLand(LandEntity land) async {
    final uid = _requireUid();
    final model = LandModel.fromEntity(
      land.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(land.id).update(model.toMap());
  }

  @override
  Future<void> deleteLand(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<LandEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LandModel.fromMap(d.data(), d.id))
            .toList());
  }
}

// =====================================================================
// Worker repository impl
// =====================================================================
class FirebaseWorkerRepository implements WorkerRepository {
  final FirebaseFirestore _firestore;

  FirebaseWorkerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.workersCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addWorker(WorkerEntity worker) async {
    final uid = _requireUid();
    final id = worker.id.isNotEmpty ? worker.id : _uuid.v4();
    final now = DateTime.now();
    final model = WorkerModel.fromEntity(
      worker.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateWorker(WorkerEntity worker) async {
    final uid = _requireUid();
    final model = WorkerModel.fromEntity(
      worker.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(worker.id).update(model.toMap());
  }

  @override
  Future<void> deleteWorker(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<WorkerEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkerModel.fromMap(d.data(), d.id))
            .toList());
  }
}

// =====================================================================
// Agri work entry repository impl
// =====================================================================
class FirebaseAgriWorkEntryRepository implements AgriWorkEntryRepository {
  final FirebaseFirestore _firestore;

  FirebaseAgriWorkEntryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.agriWorkEntriesCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addWorkEntry(AgriWorkEntryEntity entry) async {
    final uid = _requireUid();
    final id = entry.id.isNotEmpty ? entry.id : _uuid.v4();
    final now = DateTime.now();
    final model = AgriWorkEntryModel.fromEntity(
      entry.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateWorkEntry(AgriWorkEntryEntity entry) async {
    final uid = _requireUid();
    final model = AgriWorkEntryModel.fromEntity(
      entry.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(entry.id).update(model.toMap());
  }

  @override
  Future<void> deleteWorkEntry(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<AgriWorkEntryEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AgriWorkEntryModel.fromMap(d.data(), d.id))
            .toList());
  }
}

// =====================================================================
// Expense repository impl
// =====================================================================
class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirebaseExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.expensesCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    final uid = _requireUid();
    final id = expense.id.isNotEmpty ? expense.id : _uuid.v4();
    final now = DateTime.now();
    final model = ExpenseModel.fromEntity(
      expense.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    final uid = _requireUid();
    final model = ExpenseModel.fromEntity(
      expense.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(expense.id).update(model.toMap());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<ExpenseEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseModel.fromMap(d.data(), d.id))
            .toList());
  }
}

// =====================================================================
// Harvest repository impl
// =====================================================================
class FirebaseHarvestRepository implements HarvestRepository {
  final FirebaseFirestore _firestore;

  FirebaseHarvestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.harvestsCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addHarvest(HarvestEntity harvest) async {
    final uid = _requireUid();
    final id = harvest.id.isNotEmpty ? harvest.id : _uuid.v4();
    final now = DateTime.now();
    final model = HarvestModel.fromEntity(
      harvest.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateHarvest(HarvestEntity harvest) async {
    final uid = _requireUid();
    final model = HarvestModel.fromEntity(
      harvest.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(harvest.id).update(model.toMap());
  }

  @override
  Future<void> deleteHarvest(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<HarvestEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('harvestDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HarvestModel.fromMap(d.data(), d.id))
            .toList());
  }
}

// =====================================================================
// Agri vehicle repository impl
// =====================================================================
class FirebaseAgriVehicleRepository implements AgriVehicleRepository {
  final FirebaseFirestore _firestore;

  FirebaseAgriVehicleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(AgriConstants.agriVehiclesCollection)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (doc, _) => doc.data() ?? {},
        toFirestore: (data, _) => data,
      );

  @override
  Future<void> addVehicle(AgriVehicleEntity vehicle) async {
    final uid = _requireUid();
    final id = vehicle.id.isNotEmpty ? vehicle.id : _uuid.v4();
    final now = DateTime.now();
    final model = AgriVehicleModel.fromEntity(
      vehicle.copyWith(id: id, ownerId: uid, createdAt: now, updatedAt: now),
    );
    await _collection.doc(id).set(model.toMap());
  }

  @override
  Future<void> updateVehicle(AgriVehicleEntity vehicle) async {
    final uid = _requireUid();
    final model = AgriVehicleModel.fromEntity(
      vehicle.copyWith(ownerId: uid, updatedAt: DateTime.now()),
    );
    await _collection.doc(vehicle.id).update(model.toMap());
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<AgriVehicleEntity>> watchAll(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AgriVehicleModel.fromMap(d.data(), d.id))
            .toList());
  }
}
