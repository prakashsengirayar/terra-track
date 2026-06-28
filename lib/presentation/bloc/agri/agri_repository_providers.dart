// lib/presentation/bloc/agri/agri_repository_providers.dart
//
// Riverpod providers wiring the abstract agri repository interfaces
// (domain/repositories/agri_repositories.dart) to their Firebase-backed
// implementations (data/repositories/agri_repository_impl.dart), plus the
// Storage helper. Mirrors the wiring style of
// lib/presentation/bloc/providers.dart (the existing vehicle/work-log
// module), kept in a separate file so that module is never touched.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/agri_storage_service.dart';
import '../../../data/repositories/agri_repository_impl.dart';
import '../../../domain/repositories/agri_repositories.dart';

final landRepositoryProvider = Provider<LandRepository>(
  (_) => FirebaseLandRepository(),
);

final workerRepositoryProvider = Provider<WorkerRepository>(
  (_) => FirebaseWorkerRepository(),
);

final agriWorkEntryRepositoryProvider = Provider<AgriWorkEntryRepository>(
  (_) => FirebaseAgriWorkEntryRepository(),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (_) => FirebaseExpenseRepository(),
);

final harvestRepositoryProvider = Provider<HarvestRepository>(
  (_) => FirebaseHarvestRepository(),
);

final agriVehicleRepositoryProvider = Provider<AgriVehicleRepository>(
  (_) => FirebaseAgriVehicleRepository(),
);

final agriStorageServiceProvider = Provider<AgriStorageService>(
  (_) => AgriStorageService(),
);
