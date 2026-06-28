// lib/data/models/agri_models.dart
//
// Data models for the agricultural Land/Worker/Work-Entry/Expense/Harvest
// module. Additive — the existing lib/data/models/models.dart (vehicle/
// work-log module) is left untouched.
//
// Each model extends its domain entity and provides:
//   - fromMap(Map<String, dynamic>, String id)  — pure map -> entity parsing
//   - toMap()                                    — entity -> map for writes
//   - fromFirestore(DocumentSnapshot)            — convenience wrapper
//     matching this codebase's existing Firestore convention
//   - fromEntity(...)                            — wraps a plain entity so
//     repositories can persist it without callers needing to know about
//     the model class

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/agri_entities.dart';

// =====================================================================
// Land model
// =====================================================================
class LandModel extends LandEntity {
  const LandModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.location,
    required super.areaInAcres,
    required super.soilType,
    super.currentCrop,
    super.photoUrl,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LandModel.fromMap(Map<String, dynamic> map, String id) {
    return LandModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      areaInAcres: (map['areaInAcres'] as num?)?.toDouble() ?? 0.0,
      soilType: map['soilType'] as String? ?? '',
      currentCrop: map['currentCrop'] as String?,
      photoUrl: map['photoUrl'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'location': location,
        'areaInAcres': areaInAcres,
        'soilType': soilType,
        'currentCrop': currentCrop,
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory LandModel.fromFirestore(DocumentSnapshot doc) =>
      LandModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory LandModel.fromEntity(LandEntity e) => LandModel(
        id: e.id,
        ownerId: e.ownerId,
        name: e.name,
        location: e.location,
        areaInAcres: e.areaInAcres,
        soilType: e.soilType,
        currentCrop: e.currentCrop,
        photoUrl: e.photoUrl,
        notes: e.notes,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// =====================================================================
// Worker model
// =====================================================================
class WorkerModel extends WorkerEntity {
  const WorkerModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.phone,
    required super.dailyWage,
    super.address,
    super.photoUrl,
    required super.isActive,
    required super.joinedDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkerModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      dailyWage: (map['dailyWage'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      joinedDate:
          (map['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'phone': phone,
        'dailyWage': dailyWage,
        'address': address,
        'photoUrl': photoUrl,
        'isActive': isActive,
        'joinedDate': Timestamp.fromDate(joinedDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) =>
      WorkerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory WorkerModel.fromEntity(WorkerEntity e) => WorkerModel(
        id: e.id,
        ownerId: e.ownerId,
        name: e.name,
        phone: e.phone,
        dailyWage: e.dailyWage,
        address: e.address,
        photoUrl: e.photoUrl,
        isActive: e.isActive,
        joinedDate: e.joinedDate,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// =====================================================================
// Agri work entry model
// =====================================================================
class AgriWorkEntryModel extends AgriWorkEntryEntity {
  const AgriWorkEntryModel({
    required super.id,
    required super.ownerId,
    required super.landId,
    required super.landName,
    required super.workerId,
    required super.workerName,
    required super.workDescription,
    required super.date,
    required super.hoursWorked,
    required super.wageAmount,
    super.photoUrl,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AgriWorkEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return AgriWorkEntryModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      landId: map['landId'] as String? ?? '',
      landName: map['landName'] as String? ?? '',
      workerId: map['workerId'] as String? ?? '',
      workerName: map['workerName'] as String? ?? '',
      workDescription: map['workDescription'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hoursWorked: (map['hoursWorked'] as num?)?.toDouble() ?? 0.0,
      wageAmount: (map['wageAmount'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'landId': landId,
        'landName': landName,
        'workerId': workerId,
        'workerName': workerName,
        'workDescription': workDescription,
        'date': Timestamp.fromDate(date),
        'hoursWorked': hoursWorked,
        'wageAmount': wageAmount,
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory AgriWorkEntryModel.fromFirestore(DocumentSnapshot doc) =>
      AgriWorkEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory AgriWorkEntryModel.fromEntity(AgriWorkEntryEntity e) =>
      AgriWorkEntryModel(
        id: e.id,
        ownerId: e.ownerId,
        landId: e.landId,
        landName: e.landName,
        workerId: e.workerId,
        workerName: e.workerName,
        workDescription: e.workDescription,
        date: e.date,
        hoursWorked: e.hoursWorked,
        wageAmount: e.wageAmount,
        photoUrl: e.photoUrl,
        notes: e.notes,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// =====================================================================
// Expense model
// =====================================================================
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.ownerId,
    super.landId,
    super.landName,
    required super.category,
    required super.amount,
    required super.date,
    required super.description,
    super.receiptPhotoUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  static ExpenseCategory _parseCategory(String? s) {
    switch (s) {
      case 'seeds':
        return ExpenseCategory.seeds;
      case 'fertilizer':
        return ExpenseCategory.fertilizer;
      case 'pesticide':
        return ExpenseCategory.pesticide;
      case 'labor':
        return ExpenseCategory.labor;
      case 'equipment':
        return ExpenseCategory.equipment;
      case 'irrigation':
        return ExpenseCategory.irrigation;
      case 'transport':
        return ExpenseCategory.transport;
      default:
        return ExpenseCategory.other;
    }
  }

  static String _categoryToString(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.seeds:
        return 'seeds';
      case ExpenseCategory.fertilizer:
        return 'fertilizer';
      case ExpenseCategory.pesticide:
        return 'pesticide';
      case ExpenseCategory.labor:
        return 'labor';
      case ExpenseCategory.equipment:
        return 'equipment';
      case ExpenseCategory.irrigation:
        return 'irrigation';
      case ExpenseCategory.transport:
        return 'transport';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      landId: map['landId'] as String?,
      landName: map['landName'] as String?,
      category: _parseCategory(map['category'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] as String? ?? '',
      receiptPhotoUrl: map['receiptPhotoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'landId': landId,
        'landName': landName,
        'category': _categoryToString(category),
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'description': description,
        'receiptPhotoUrl': receiptPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) =>
      ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory ExpenseModel.fromEntity(ExpenseEntity e) => ExpenseModel(
        id: e.id,
        ownerId: e.ownerId,
        landId: e.landId,
        landName: e.landName,
        category: e.category,
        amount: e.amount,
        date: e.date,
        description: e.description,
        receiptPhotoUrl: e.receiptPhotoUrl,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// =====================================================================
// Harvest model
// =====================================================================
class HarvestModel extends HarvestEntity {
  const HarvestModel({
    required super.id,
    required super.ownerId,
    required super.landId,
    required super.landName,
    required super.cropName,
    required super.quantity,
    required super.unit,
    required super.pricePerUnit,
    required super.totalRevenue,
    required super.harvestDate,
    super.photoUrl,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HarvestModel.fromMap(Map<String, dynamic> map, String id) {
    return HarvestModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      landId: map['landId'] as String? ?? '',
      landName: map['landName'] as String? ?? '',
      cropName: map['cropName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      harvestDate:
          (map['harvestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'landId': landId,
        'landName': landName,
        'cropName': cropName,
        'quantity': quantity,
        'unit': unit,
        'pricePerUnit': pricePerUnit,
        'totalRevenue': totalRevenue,
        'harvestDate': Timestamp.fromDate(harvestDate),
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory HarvestModel.fromFirestore(DocumentSnapshot doc) =>
      HarvestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory HarvestModel.fromEntity(HarvestEntity e) => HarvestModel(
        id: e.id,
        ownerId: e.ownerId,
        landId: e.landId,
        landName: e.landName,
        cropName: e.cropName,
        quantity: e.quantity,
        unit: e.unit,
        pricePerUnit: e.pricePerUnit,
        totalRevenue: e.totalRevenue,
        harvestDate: e.harvestDate,
        photoUrl: e.photoUrl,
        notes: e.notes,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// =====================================================================
// Agri vehicle model
// =====================================================================
class AgriVehicleModel extends AgriVehicleEntity {
  const AgriVehicleModel({
    required super.id,
    required super.ownerId,
    required super.vehicleName,
    required super.vehicleNumber,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AgriVehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return AgriVehicleModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      vehicleName: map['vehicleName'] as String? ?? '',
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'vehicleName': vehicleName,
        'vehicleNumber': vehicleNumber,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory AgriVehicleModel.fromFirestore(DocumentSnapshot doc) =>
      AgriVehicleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory AgriVehicleModel.fromEntity(AgriVehicleEntity e) => AgriVehicleModel(
        id: e.id,
        ownerId: e.ownerId,
        vehicleName: e.vehicleName,
        vehicleNumber: e.vehicleNumber,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}
