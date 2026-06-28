import 'package:equatable/equatable.dart';

// --- Vehicle entity ---
class VehicleEntity extends Equatable {
  final String id;
  final String vehicleName;
  final String driverName;
  final bool isActive;
  final DateTime createdAt;

  const VehicleEntity({
    required this.id,
    required this.vehicleName,
    required this.driverName,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, vehicleName, driverName, isActive];
}

// --- WorkEntry entity ---
enum PaymentStatus { paid, pending }

class WorkEntryEntity extends Equatable {
  final String id;
  final String customerName;
  final String nativePlace;
  final String vehicleName;
  final String driverName;
  final double ratePerHour;
  final int timerDurationSeconds;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus status;
  final DateTime date;
  final String customerPhone;
  final String? billPhotoUrl;
  final String? customerPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkEntryEntity({
    required this.id,
    required this.customerName,
    required this.nativePlace,
    required this.vehicleName,
    required this.driverName,
    required this.ratePerHour,
    required this.timerDurationSeconds,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    required this.date,
    required this.customerPhone,
    this.billPhotoUrl,
    this.customerPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalHours => timerDurationSeconds / 3600;

  String get formattedHours {
    final h = timerDurationSeconds ~/ 3600;
    final m = (timerDurationSeconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  WorkEntryEntity copyWith({
    String? id,
    String? customerName,
    String? nativePlace,
    String? vehicleName,
    String? driverName,
    double? ratePerHour,
    int? timerDurationSeconds,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    PaymentStatus? status,
    DateTime? date,
    String? customerPhone,
    String? billPhotoUrl,
    String? customerPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkEntryEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      nativePlace: nativePlace ?? this.nativePlace,
      vehicleName: vehicleName ?? this.vehicleName,
      driverName: driverName ?? this.driverName,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      status: status ?? this.status,
      date: date ?? this.date,
      customerPhone: customerPhone ?? this.customerPhone,
      billPhotoUrl: billPhotoUrl ?? this.billPhotoUrl,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, customerName, vehicleName, status, paidAmount];
}

// --- AdminEntry entity ---
enum AdminEntryType { diesel, food, maintenance, vehicleAdvance, others }

class AdminEntryEntity extends Equatable {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final AdminEntryType entryType;
  final double amount;
  final String? note;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;

  const AdminEntryEntity({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.entryType,
    required this.amount,
    this.note,
    required this.date,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, vehicleId, entryType, amount, date];
}

// --- Message entity ---
class MessageEntity extends Equatable {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String messageText;
  final DateTime sentAt;
  final String sentBy;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.messageText,
    required this.sentAt,
    required this.sentBy,
    required this.isRead,
  });

  @override
  List<Object?> get props => [id, vehicleId, sentAt];
}

// --- Dashboard summary entity ---
class DashboardSummaryEntity extends Equatable {
  final double totalHours;
  final double totalCollected;
  final double totalPending;
  final int activeVehicleCount;
  final List<VehicleSummaryEntity> vehicleSummaries;

  const DashboardSummaryEntity({
    required this.totalHours,
    required this.totalCollected,
    required this.totalPending,
    required this.activeVehicleCount,
    required this.vehicleSummaries,
  });

  @override
  List<Object?> get props => [totalHours, totalCollected, totalPending];
}

class VehicleSummaryEntity extends Equatable {
  final String vehicleId;
  final String vehicleName;
  final String driverName;
  final bool isActive;
  final double totalHours;
  final double totalEarnings;
  final double totalPending;
  final int entryCount;

  const VehicleSummaryEntity({
    required this.vehicleId,
    required this.vehicleName,
    required this.driverName,
    required this.isActive,
    required this.totalHours,
    required this.totalEarnings,
    required this.totalPending,
    required this.entryCount,
  });

  @override
  List<Object?> get props => [vehicleId, totalHours, totalEarnings];
}

// --- Session entity ---
class SessionEntity extends Equatable {
  final String vehicleId;
  final String vehicleName;
  final String driverName;
  final DateTime loginTime;

  const SessionEntity({
    required this.vehicleId,
    required this.vehicleName,
    required this.driverName,
    required this.loginTime,
  });

  @override
  List<Object?> get props => [vehicleId, driverName];
}
