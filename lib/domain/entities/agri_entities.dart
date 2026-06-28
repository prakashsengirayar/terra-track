// lib/domain/entities/agri_entities.dart
//
// Domain entities for the agricultural Land/Worker/Work-Entry/Expense/Harvest
// module. This is a new, additive module living alongside the existing
// vehicle/work-log domain (lib/domain/entities/entities.dart), which is left
// untouched. All entities below are scoped per-user via `ownerId`, which is
// always set to FirebaseAuth.instance.currentUser!.uid at creation time.

import 'package:equatable/equatable.dart';

// =====================================================================
// Land entity
// =====================================================================
class LandEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String location;
  final double areaInAcres;
  final String soilType;
  final String? currentCrop;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LandEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.areaInAcres,
    required this.soilType,
    this.currentCrop,
    this.photoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  LandEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? location,
    double? areaInAcres,
    String? soilType,
    String? currentCrop,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LandEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      location: location ?? this.location,
      areaInAcres: areaInAcres ?? this.areaInAcres,
      soilType: soilType ?? this.soilType,
      currentCrop: currentCrop ?? this.currentCrop,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, ownerId, name, location, areaInAcres, soilType, currentCrop];
}

// =====================================================================
// Worker entity
// =====================================================================
class WorkerEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String phone;
  final double dailyWage;
  final String? address;
  final String? photoUrl;
  final bool isActive;
  final DateTime joinedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkerEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.dailyWage,
    this.address,
    this.photoUrl,
    required this.isActive,
    required this.joinedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkerEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? phone,
    double? dailyWage,
    String? address,
    String? photoUrl,
    bool? isActive,
    DateTime? joinedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkerEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dailyWage: dailyWage ?? this.dailyWage,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, phone, dailyWage, isActive];
}

// =====================================================================
// Agri work entry entity
// (named `AgriWorkEntryEntity` — distinct from the existing
// `WorkEntryEntity` in entities.dart, which models vehicle/customer logs)
// =====================================================================
class AgriWorkEntryEntity extends Equatable {
  final String id;
  final String ownerId;
  final String landId;
  final String landName;
  final String workerId;
  final String workerName;
  final String workDescription;
  final DateTime date;
  final double hoursWorked;
  final double wageAmount;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgriWorkEntryEntity({
    required this.id,
    required this.ownerId,
    required this.landId,
    required this.landName,
    required this.workerId,
    required this.workerName,
    required this.workDescription,
    required this.date,
    required this.hoursWorked,
    required this.wageAmount,
    this.photoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  AgriWorkEntryEntity copyWith({
    String? id,
    String? ownerId,
    String? landId,
    String? landName,
    String? workerId,
    String? workerName,
    String? workDescription,
    DateTime? date,
    double? hoursWorked,
    double? wageAmount,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgriWorkEntryEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      landId: landId ?? this.landId,
      landName: landName ?? this.landName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workDescription: workDescription ?? this.workDescription,
      date: date ?? this.date,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      wageAmount: wageAmount ?? this.wageAmount,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, ownerId, landId, workerId, date, hoursWorked, wageAmount];
}

// =====================================================================
// Expense entity
// =====================================================================
enum ExpenseCategory {
  seeds,
  fertilizer,
  pesticide,
  labor,
  equipment,
  irrigation,
  transport,
  other,
}

class ExpenseEntity extends Equatable {
  final String id;
  final String ownerId;
  final String? landId;
  final String? landName;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String description;
  final String? receiptPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseEntity({
    required this.id,
    required this.ownerId,
    this.landId,
    this.landName,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.receiptPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  ExpenseEntity copyWith({
    String? id,
    String? ownerId,
    String? landId,
    String? landName,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? receiptPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      landId: landId ?? this.landId,
      landName: landName ?? this.landName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, ownerId, landId, category, amount, date, description];
}

// =====================================================================
// Harvest entity
// =====================================================================
class HarvestEntity extends Equatable {
  final String id;
  final String ownerId;
  final String landId;
  final String landName;
  final String cropName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalRevenue;
  final DateTime harvestDate;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HarvestEntity({
    required this.id,
    required this.ownerId,
    required this.landId,
    required this.landName,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalRevenue,
    required this.harvestDate,
    this.photoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  HarvestEntity copyWith({
    String? id,
    String? ownerId,
    String? landId,
    String? landName,
    String? cropName,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? totalRevenue,
    DateTime? harvestDate,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HarvestEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      landId: landId ?? this.landId,
      landName: landName ?? this.landName,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      harvestDate: harvestDate ?? this.harvestDate,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, ownerId, landId, cropName, quantity, unit, totalRevenue, harvestDate];
}

// =====================================================================
// Agri vehicle entity
// (named `AgriVehicleEntity` and stored in its own `agriVehicles`
// collection — deliberately distinct from the existing `VehicleEntity` /
// `vehicles` collection in entities.dart, which models the vehicle/driver
// work-log login flow, has a completely different shape (vehicleName,
// driverName, isActive — no ownerId), and is governed by its own
// `allow read: if true; allow write: if false;` Firestore rule. Reusing
// either name or collection here would collide with that flow.)
// =====================================================================
class AgriVehicleEntity extends Equatable {
  final String id;
  final String ownerId;
  final String vehicleName;
  final String vehicleNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgriVehicleEntity({
    required this.id,
    required this.ownerId,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  AgriVehicleEntity copyWith({
    String? id,
    String? ownerId,
    String? vehicleName,
    String? vehicleNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgriVehicleEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, vehicleName, vehicleNumber];
}
