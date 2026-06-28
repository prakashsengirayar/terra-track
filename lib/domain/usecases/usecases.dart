import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

// --- Auth Use Cases ---
class VerifyVehicleUseCase {
  final VehicleRepository repository;
  VerifyVehicleUseCase(this.repository);

  Future<Either<Failure, VehicleEntity>> call(String vehicleName) =>
      repository.verifyVehicle(vehicleName);
}

class SaveSessionUseCase {
  final SessionRepository repository;
  SaveSessionUseCase(this.repository);

  Future<Either<Failure, SessionEntity>> call(SessionEntity session) =>
      repository.saveSession(session);
}

class GetSessionUseCase {
  final SessionRepository repository;
  GetSessionUseCase(this.repository);

  Either<Failure, SessionEntity?> call() => repository.getSession();
}

class ClearSessionUseCase {
  final SessionRepository repository;
  ClearSessionUseCase(this.repository);

  Future<Either<Failure, bool>> call() => repository.clearSession();
}

// --- Work Entry Use Cases ---
class CreateWorkEntryUseCase {
  final WorkEntryRepository repository;
  CreateWorkEntryUseCase(this.repository);

  Future<Either<Failure, WorkEntryEntity>> call(WorkEntryEntity entry) =>
      repository.createEntry(entry);
}

class UpdateWorkEntryUseCase {
  final WorkEntryRepository repository;
  UpdateWorkEntryUseCase(this.repository);

  Future<Either<Failure, WorkEntryEntity>> call(WorkEntryEntity entry) =>
      repository.updateEntry(entry);
}

class GetEntriesByVehicleUseCase {
  final WorkEntryRepository repository;
  GetEntriesByVehicleUseCase(this.repository);

  Future<Either<Failure, List<WorkEntryEntity>>> call(
    String vehicleName, {
    String? searchQuery,
    bool latestFirst = true,
  }) =>
      repository.getEntriesByVehicle(
        vehicleName,
        searchQuery: searchQuery,
        latestFirst: latestFirst,
      );
}

class WatchEntriesByVehicleUseCase {
  final WorkEntryRepository repository;
  WatchEntriesByVehicleUseCase(this.repository);

  Stream<List<WorkEntryEntity>> call(String vehicleName) =>
      repository.watchEntriesByVehicle(vehicleName);
}

class CheckCustomerNameUniqueUseCase {
  final WorkEntryRepository repository;
  CheckCustomerNameUniqueUseCase(this.repository);

  Future<Either<Failure, bool>> call(
    String name,
    String vehicleName, {
    String? excludeId,
  }) =>
      repository.isCustomerNameUnique(name, vehicleName, excludeId: excludeId);
}

class GetNativeSuggestionsUseCase {
  final WorkEntryRepository repository;
  GetNativeSuggestionsUseCase(this.repository);

  Future<Either<Failure, List<String>>> call(String query) =>
      repository.getNativeSuggestions(query);
}

class UploadCustomerPhotoUseCase {
  final WorkEntryRepository repository;
  UploadCustomerPhotoUseCase(this.repository);

  Future<Either<Failure, String?>> call(Uint8List bytes, String entryId) =>
      repository.uploadCustomerPhoto(bytes, entryId);
}

class UploadBillPhotoUseCase {
  final WorkEntryRepository repository;
  UploadBillPhotoUseCase(this.repository);

  Future<Either<Failure, String?>> call(Uint8List bytes, String entryId) =>
      repository.uploadBillPhoto(bytes, entryId);
}

// --- Admin Use Cases ---
class CreateAdminEntryUseCase {
  final AdminRepository repository;
  CreateAdminEntryUseCase(this.repository);

  Future<Either<Failure, AdminEntryEntity>> call(AdminEntryEntity entry) =>
      repository.createAdminEntry(entry);
}

class GetDashboardSummaryUseCase {
  final AdminRepository repository;
  GetDashboardSummaryUseCase(this.repository);

  Future<Either<Failure, DashboardSummaryEntity>> call() =>
      repository.getDashboardSummary();
}

class SendMessageToVehicleUseCase {
  final AdminRepository repository;
  SendMessageToVehicleUseCase(this.repository);

  Future<Either<Failure, bool>> call(MessageEntity message) =>
      repository.sendMessageToVehicle(message);
}

class GetAllVehiclesUseCase {
  final VehicleRepository repository;
  GetAllVehiclesUseCase(this.repository);

  Future<Either<Failure, List<VehicleEntity>>> call() =>
      repository.getAllVehicles();
}
