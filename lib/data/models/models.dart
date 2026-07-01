import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

// --- Vehicle Model ---
class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.vehicleNumber,
    required super.vehicleName,
    required super.driverName,
    required super.isActive,
    required super.createdAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      vehicleName: data['vehicleName'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'vehicleNumber': vehicleNumber,
        'vehicleName': vehicleName,
        'driverName': driverName,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory VehicleModel.fromEntity(VehicleEntity entity) => VehicleModel(
        id: entity.id,
        vehicleNumber: entity.vehicleNumber,
        vehicleName: entity.vehicleName,
        driverName: entity.driverName,
        isActive: entity.isActive,
        createdAt: entity.createdAt,
      );
}

// --- WorkEntry Model ---
class WorkEntryModel extends WorkEntryEntity {
  const WorkEntryModel({
    required super.id,
    required super.customerName,
    required super.nativePlace,
    required super.vehicleName,
    required super.driverName,
    required super.ratePerHour,
    required super.timerDurationSeconds,
    required super.totalAmount,
    required super.paidAmount,
    required super.balanceAmount,
    required super.status,
    required super.date,
    required super.customerPhone,
    super.billPhotoUrl,
    super.customerPhotoUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WorkEntryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorkEntryModel(
      id: doc.id,
      customerName: d['customerName'] as String? ?? '',
      nativePlace: d['nativePlace'] as String? ?? '',
      vehicleName: d['vehicleName'] as String? ?? '',
      driverName: d['driverName'] as String? ?? '',
      ratePerHour: (d['ratePerHour'] as num?)?.toDouble() ?? 0.0,
      timerDurationSeconds: d['timerDurationSeconds'] as int? ?? 0,
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (d['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (d['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      status: d['status'] == 'paid' ? PaymentStatus.paid : PaymentStatus.pending,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerPhone: d['customerPhone'] as String? ?? '',
      billPhotoUrl: d['billPhotoUrl'] as String?,
      customerPhotoUrl: d['customerPhotoUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerName': customerName,
        'nativePlace': nativePlace,
        'vehicleName': vehicleName,
        'driverName': driverName,
        'ratePerHour': ratePerHour,
        'timerDurationSeconds': timerDurationSeconds,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'status': status == PaymentStatus.paid ? 'paid' : 'pending',
        'date': Timestamp.fromDate(date),
        'customerPhone': customerPhone,
        'billPhotoUrl': billPhotoUrl,
        'customerPhotoUrl': customerPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory WorkEntryModel.fromEntity(WorkEntryEntity e) => WorkEntryModel(
        id: e.id,
        customerName: e.customerName,
        nativePlace: e.nativePlace,
        vehicleName: e.vehicleName,
        driverName: e.driverName,
        ratePerHour: e.ratePerHour,
        timerDurationSeconds: e.timerDurationSeconds,
        totalAmount: e.totalAmount,
        paidAmount: e.paidAmount,
        balanceAmount: e.balanceAmount,
        status: e.status,
        date: e.date,
        customerPhone: e.customerPhone,
        billPhotoUrl: e.billPhotoUrl,
        customerPhotoUrl: e.customerPhotoUrl,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}

// --- AdminEntry Model ---
class AdminEntryModel extends AdminEntryEntity {
  const AdminEntryModel({
    required super.id,
    required super.vehicleId,
    required super.vehicleName,
    required super.entryType,
    required super.amount,
    super.note,
    required super.date,
    required super.createdBy,
    required super.createdAt,
  });

  static AdminEntryType _parseType(String? s) {
    switch (s) {
      case 'diesel': return AdminEntryType.diesel;
      case 'food': return AdminEntryType.food;
      case 'maintenance': return AdminEntryType.maintenance;
      case 'vehicleAdvance': return AdminEntryType.vehicleAdvance;
      default: return AdminEntryType.others;
    }
  }

  static String _typeToString(AdminEntryType t) {
    switch (t) {
      case AdminEntryType.diesel: return 'diesel';
      case AdminEntryType.food: return 'food';
      case AdminEntryType.maintenance: return 'maintenance';
      case AdminEntryType.vehicleAdvance: return 'vehicleAdvance';
      case AdminEntryType.others: return 'others';
    }
  }

  factory AdminEntryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminEntryModel(
      id: doc.id,
      vehicleId: d['vehicleId'] as String? ?? '',
      vehicleName: d['vehicleName'] as String? ?? '',
      entryType: _parseType(d['entryType'] as String?),
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      note: d['note'] as String?,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'entryType': _typeToString(entryType),
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// --- Message Model ---
class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.vehicleId,
    required super.vehicleName,
    required super.messageText,
    required super.sentAt,
    required super.sentBy,
    required super.isRead,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      vehicleId: d['vehicleId'] as String? ?? '',
      vehicleName: d['vehicleName'] as String? ?? '',
      messageText: d['messageText'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentBy: d['sentBy'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'messageText': messageText,
        'sentAt': Timestamp.fromDate(sentAt),
        'sentBy': sentBy,
        'isRead': isRead,
      };
}
