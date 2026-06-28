import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

abstract class LocalDataSource {
  SessionData? getSession();
  Future<void> saveSession(SessionData session);
  Future<void> clearSession();
}

class SessionData {
  final String vehicleId;
  final String vehicleName;
  final String driverName;
  final DateTime loginTime;

  SessionData({
    required this.vehicleId,
    required this.vehicleName,
    required this.driverName,
    required this.loginTime,
  });

  Map<String, dynamic> toMap() => {
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'driverName': driverName,
        'loginTime': loginTime.toIso8601String(),
      };

  factory SessionData.fromMap(Map<dynamic, dynamic> map) => SessionData(
        vehicleId: map['vehicleId'] as String,
        vehicleName: map['vehicleName'] as String,
        driverName: map['driverName'] as String,
        loginTime: DateTime.parse(map['loginTime'] as String),
      );
}

class HiveLocalDataSource implements LocalDataSource {
  final Box _sessionBox;

  HiveLocalDataSource() : _sessionBox = Hive.box(AppConstants.sessionBox);

  @override
  SessionData? getSession() {
    try {
      final data = _sessionBox.get('current');
      if (data == null) return null;
      return SessionData.fromMap(data as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(SessionData session) async {
    await _sessionBox.put('current', session.toMap());
  }

  @override
  Future<void> clearSession() async {
    await _sessionBox.delete('current');
  }
}
