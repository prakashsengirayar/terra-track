// lib/core/constants/agri_constants.dart
//
// Constants for the agricultural Land/Worker/Work-Entry/Expense/Harvest
// module. Kept separate from `AppConstants` (core/constants/app_constants.dart)
// so the existing vehicle/work-log module is never touched by this addition.

class AgriConstants {
  AgriConstants._();

  // --- Firestore collections ---
  // Deliberately distinct from the existing `workEntries` collection (which
  // stores vehicle/customer work logs) to avoid any data collision.
  static const String landsCollection = 'lands';
  static const String workersCollection = 'workers';
  static const String agriWorkEntriesCollection = 'agriWorkEntries';
  static const String expensesCollection = 'expenses';
  static const String harvestsCollection = 'harvests';
  // Deliberately distinct from the existing `vehicles` collection (which
  // stores the vehicle/driver login records for the work-log module).
  static const String agriVehiclesCollection = 'agriVehicles';

  // --- Firebase Storage paths ---
  static const String landPhotosPath = 'agri/land_photos';
  static const String workerPhotosPath = 'agri/worker_photos';
  static const String workEntryPhotosPath = 'agri/work_entry_photos';
  static const String expenseReceiptsPath = 'agri/expense_receipts';
  static const String harvestPhotosPath = 'agri/harvest_photos';

  // --- Common field name used for per-user data scoping ---
  static const String ownerIdField = 'ownerId';
  static const String createdAtField = 'createdAt';
}
