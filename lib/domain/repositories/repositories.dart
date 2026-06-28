import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/entities.dart';

abstract class VehicleRepository {
  Future<Either<Failure, VehicleEntity>> verifyVehicle(String vehicleName);
  Future<Either<Failure, List<VehicleEntity>>> getAllVehicles();
  Future<Either<Failure, VehicleEntity>> getVehicleById(String id);
}

abstract class WorkEntryRepository {
  Future<Either<Failure, WorkEntryEntity>> createEntry(WorkEntryEntity entry);
  Future<Either<Failure, WorkEntryEntity>> updateEntry(WorkEntryEntity entry);
  Future<Either<Failure, List<WorkEntryEntity>>> getEntriesByVehicle(
    String vehicleName, {
    String? searchQuery,
    bool latestFirst = true,
  });
  Future<Either<Failure, WorkEntryEntity>> getEntryById(String id);
  Future<Either<Failure, bool>> isCustomerNameUnique(
    String name,
    String vehicleName, {
    String? excludeId,
  });
  Future<Either<Failure, List<String>>> getNativeSuggestions(String query);
  Future<Either<Failure, String?>> uploadCustomerPhoto(Uint8List bytes, String entryId);
  Future<Either<Failure, String?>> uploadBillPhoto(Uint8List bytes, String entryId);
  Stream<List<WorkEntryEntity>> watchEntriesByVehicle(String vehicleName);
}

abstract class AdminRepository {
  Future<Either<Failure, AdminEntryEntity>> createAdminEntry(AdminEntryEntity entry);
  Future<Either<Failure, List<AdminEntryEntity>>> getAdminEntries({String? vehicleId});
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardSummary();
  Future<Either<Failure, bool>> sendMessageToVehicle(MessageEntity message);
  Future<Either<Failure, List<MessageEntity>>> getMessages({String? vehicleId});
}

abstract class SessionRepository {
  Future<Either<Failure, SessionEntity>> saveSession(SessionEntity session);
  Either<Failure, SessionEntity?> getSession();
  Future<Either<Failure, bool>> clearSession();
}
