// lib/domain/repositories/agri_repositories.dart
//
// Abstract repository interfaces for the agricultural Land/Worker/
// Work-Entry/Expense/Harvest module. Additive — the existing
// lib/domain/repositories/repositories.dart (dartz/Either-based, for the
// vehicle/work-log module) is left untouched.
//
// Per the agri module's explicit design choice, these interfaces use plain
// Future/Stream return types (no Either<Failure, T>) so the Riverpod layer
// can drive UI state directly via AsyncValue.
//
// Every read is scoped to a single user's data via `ownerId`, and every
// write must carry an entity whose `ownerId` equals
// FirebaseAuth.instance.currentUser!.uid (enforced in the data-layer
// implementations and in Firestore security rules).

import '../entities/agri_entities.dart';

abstract class LandRepository {
  Future<void> addLand(LandEntity land);
  Future<void> updateLand(LandEntity land);
  Future<void> deleteLand(String id);
  Stream<List<LandEntity>> watchAll(String ownerId);
}

abstract class WorkerRepository {
  Future<void> addWorker(WorkerEntity worker);
  Future<void> updateWorker(WorkerEntity worker);
  Future<void> deleteWorker(String id);
  Stream<List<WorkerEntity>> watchAll(String ownerId);
}

abstract class AgriWorkEntryRepository {
  Future<void> addWorkEntry(AgriWorkEntryEntity entry);
  Future<void> updateWorkEntry(AgriWorkEntryEntity entry);
  Future<void> deleteWorkEntry(String id);
  Stream<List<AgriWorkEntryEntity>> watchAll(String ownerId);
}

abstract class ExpenseRepository {
  Future<void> addExpense(ExpenseEntity expense);
  Future<void> updateExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String id);
  Stream<List<ExpenseEntity>> watchAll(String ownerId);
}

abstract class HarvestRepository {
  Future<void> addHarvest(HarvestEntity harvest);
  Future<void> updateHarvest(HarvestEntity harvest);
  Future<void> deleteHarvest(String id);
  Stream<List<HarvestEntity>> watchAll(String ownerId);
}

abstract class AgriVehicleRepository {
  Future<void> addVehicle(AgriVehicleEntity vehicle);
  Future<void> updateVehicle(AgriVehicleEntity vehicle);
  Future<void> deleteVehicle(String id);
  Stream<List<AgriVehicleEntity>> watchAll(String ownerId);
}
