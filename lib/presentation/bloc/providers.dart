import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/hive_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/usecases.dart';

// ---- Data Sources ----
final remoteDataSourceProvider = Provider<RemoteDataSource>(
  (_) => FirestoreRemoteDataSource(),
);

final localDataSourceProvider = Provider<LocalDataSource>(
  (_) => HiveLocalDataSource(),
);

// ---- Repositories ----
final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepositoryImpl(ref.read(remoteDataSourceProvider)),
);

final workEntryRepositoryProvider = Provider<WorkEntryRepository>(
  (ref) => WorkEntryRepositoryImpl(ref.read(remoteDataSourceProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.read(remoteDataSourceProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(ref.read(localDataSourceProvider)),
);

// ---- Use Cases ----
final verifyVehicleUseCaseProvider = Provider(
  (ref) => VerifyVehicleUseCase(ref.read(vehicleRepositoryProvider)),
);
final saveSessionUseCaseProvider = Provider(
  (ref) => SaveSessionUseCase(ref.read(sessionRepositoryProvider)),
);
final getSessionUseCaseProvider = Provider(
  (ref) => GetSessionUseCase(ref.read(sessionRepositoryProvider)),
);
final clearSessionUseCaseProvider = Provider(
  (ref) => ClearSessionUseCase(ref.read(sessionRepositoryProvider)),
);
final createWorkEntryUseCaseProvider = Provider(
  (ref) => CreateWorkEntryUseCase(ref.read(workEntryRepositoryProvider)),
);
final updateWorkEntryUseCaseProvider = Provider(
  (ref) => UpdateWorkEntryUseCase(ref.read(workEntryRepositoryProvider)),
);
final getEntriesByVehicleUseCaseProvider = Provider(
  (ref) => GetEntriesByVehicleUseCase(ref.read(workEntryRepositoryProvider)),
);
final watchEntriesUseCaseProvider = Provider(
  (ref) => WatchEntriesByVehicleUseCase(ref.read(workEntryRepositoryProvider)),
);
final checkNameUniqueUseCaseProvider = Provider(
  (ref) => CheckCustomerNameUniqueUseCase(ref.read(workEntryRepositoryProvider)),
);
final getNativeSuggestionsUseCaseProvider = Provider(
  (ref) => GetNativeSuggestionsUseCase(ref.read(workEntryRepositoryProvider)),
);
final uploadCustomerPhotoUseCaseProvider = Provider(
  (ref) => UploadCustomerPhotoUseCase(ref.read(workEntryRepositoryProvider)),
);
final uploadBillPhotoUseCaseProvider = Provider(
  (ref) => UploadBillPhotoUseCase(ref.read(workEntryRepositoryProvider)),
);
final createAdminEntryUseCaseProvider = Provider(
  (ref) => CreateAdminEntryUseCase(ref.read(adminRepositoryProvider)),
);
final getDashboardUseCaseProvider = Provider(
  (ref) => GetDashboardSummaryUseCase(ref.read(adminRepositoryProvider)),
);
final sendMessageUseCaseProvider = Provider(
  (ref) => SendMessageToVehicleUseCase(ref.read(adminRepositoryProvider)),
);
final getAllVehiclesUseCaseProvider = Provider(
  (ref) => GetAllVehiclesUseCase(ref.read(vehicleRepositoryProvider)),
);
