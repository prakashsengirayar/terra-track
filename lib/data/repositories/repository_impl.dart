import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/models.dart';

// --- Vehicle Repository Implementation ---
class VehicleRepositoryImpl implements VehicleRepository {
  final RemoteDataSource _remote;
  VehicleRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, VehicleEntity>> verifyVehicle(
      String vehicleNumber) async {
    try {
      final vehicle = await _remote.verifyVehicle(vehicleNumber);
      if (vehicle == null) return const Left(NotFoundFailure('Vehicle not found'));
      return Right(vehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getAllVehicles() async {
    try {
      final list = await _remote.getAllVehicles();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleById(String id) async {
    try {
      final v = await _remote.getVehicleById(id);
      if (v == null) return const Left(NotFoundFailure());
      return Right(v);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getAllVehiclesIncludingInactive() async {
    try {
      final list = await _remote.getAllVehiclesIncludingInactive();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> createVehicle(VehicleEntity vehicle) async {
    try {
      final model = VehicleModel.fromEntity(vehicle);
      final result = await _remote.createVehicle(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> updateVehicle(VehicleEntity vehicle) async {
    try {
      final model = VehicleModel.fromEntity(vehicle);
      final result = await _remote.updateVehicle(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteVehicle(String id) async {
    try {
      final result = await _remote.deleteVehicle(id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// --- WorkEntry Repository Implementation ---
class WorkEntryRepositoryImpl implements WorkEntryRepository {
  final RemoteDataSource _remote;
  WorkEntryRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, WorkEntryEntity>> createEntry(
      WorkEntryEntity entry) async {
    try {
      final model = await _remote.createWorkEntry(
        WorkEntryModel.fromEntity(entry),
      );
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkEntryEntity>> updateEntry(
      WorkEntryEntity entry) async {
    try {
      final model = await _remote.updateWorkEntry(
        WorkEntryModel.fromEntity(entry),
      );
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkEntryEntity>>> getEntriesByVehicle(
    String vehicleName, {
    String? searchQuery,
    bool latestFirst = true,
  }) async {
    try {
      final list = await _remote.getEntriesByVehicle(
        vehicleName,
        searchQuery: searchQuery,
        latestFirst: latestFirst,
      );
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkEntryEntity>> getEntryById(String id) async {
    try {
      final e = await _remote.getEntryById(id);
      if (e == null) return const Left(NotFoundFailure());
      return Right(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isCustomerNameUnique(
    String name,
    String vehicleName, {
    String? excludeId,
  }) async {
    try {
      final result =
          await _remote.isCustomerNameUnique(name, vehicleName, excludeId: excludeId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getNativeSuggestions(
      String query) async {
    try {
      final list = await _remote.getNativeSuggestions(query);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadCustomerPhoto(
      Uint8List bytes, String entryId) async {
    try {
      final url = await _remote.uploadFile(
          bytes, '${AppConstants.customerPhotosPath}/$entryId.jpg');
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadBillPhoto(
      Uint8List bytes, String entryId) async {
    try {
      final url = await _remote.uploadFile(
          bytes, '${AppConstants.billPhotosPath}/$entryId.jpg');
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<WorkEntryEntity>> watchEntriesByVehicle(String vehicleName) {
    return _remote.watchEntriesByVehicle(vehicleName);
  }
}

// --- Admin Repository Implementation ---
class AdminRepositoryImpl implements AdminRepository {
  final RemoteDataSource _remote;
  AdminRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, AdminEntryEntity>> createAdminEntry(
      AdminEntryEntity entry) async {
    try {
      final model = await _remote.createAdminEntry(
        AdminEntryModel(
          id: '',
          vehicleId: entry.vehicleId,
          vehicleName: entry.vehicleName,
          entryType: entry.entryType,
          amount: entry.amount,
          note: entry.note,
          date: entry.date,
          createdBy: entry.createdBy,
          createdAt: DateTime.now(),
        ),
      );
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminEntryEntity>>> getAdminEntries(
      {String? vehicleId}) async {
    try {
      final list = await _remote.getAdminEntries(vehicleId: vehicleId);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardSummary() async {
    try {
      final data = await _remote.getDashboardData();
      final vehicles = (data['vehicles'] as List<VehicleModel>);
      final summaries = (data['vehicleSummaries'] as List<Map<String, dynamic>>)
          .map((m) {
        final vehicle = vehicles.firstWhere(
          (v) => v.vehicleName == m['vehicleName'],
          orElse: () => VehicleModel(
            id: '',
            vehicleNumber: '',
            vehicleName: m['vehicleName'] as String,
            driverName: '',
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );
        return VehicleSummaryEntity(
          vehicleId: vehicle.id,
          vehicleName: m['vehicleName'] as String,
          driverName: vehicle.driverName,
          isActive: vehicle.isActive,
          totalHours: (m['hours'] as double),
          totalEarnings: (m['earnings'] as double),
          totalPending: (m['pending'] as double),
          entryCount: (m['count'] as int),
        );
      }).toList();

      return Right(DashboardSummaryEntity(
        totalHours: data['totalHours'] as double,
        totalCollected: data['totalCollected'] as double,
        totalPending: data['totalPending'] as double,
        activeVehicleCount: data['activeVehicleCount'] as int,
        vehicleSummaries: summaries,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> sendMessageToVehicle(
      MessageEntity message) async {
    try {
      final result = await _remote.sendMessage(
        MessageModel(
          id: '',
          vehicleId: message.vehicleId,
          vehicleName: message.vehicleName,
          messageText: message.messageText,
          sentAt: DateTime.now(),
          sentBy: message.sentBy,
          isRead: false,
        ),
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(
      {String? vehicleId}) async {
    try {
      final list = await _remote.getMessages(vehicleId: vehicleId);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// --- Session Repository Implementation ---
class SessionRepositoryImpl implements SessionRepository {
  final LocalDataSource _local;
  SessionRepositoryImpl(this._local);

  @override
  Future<Either<Failure, SessionEntity>> saveSession(
      SessionEntity session) async {
    try {
      await _local.saveSession(
        SessionData(
          vehicleId: session.vehicleId,
          vehicleName: session.vehicleName,
          driverName: session.driverName,
          loginTime: session.loginTime,
        ),
      );
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Either<Failure, SessionEntity?> getSession() {
    try {
      final data = _local.getSession();
      if (data == null) return const Right(null);
      return Right(SessionEntity(
        vehicleId: data.vehicleId,
        vehicleName: data.vehicleName,
        driverName: data.driverName,
        loginTime: data.loginTime,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearSession() async {
    try {
      await _local.clearSession();
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
