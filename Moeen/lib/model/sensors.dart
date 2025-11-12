import 'package:hive/hive.dart';
part 'sensors.g.dart';

@HiveType(typeId: 0)
class SensorData extends HiveObject {
  @HiveField(0)
  final int heartRate;

  @HiveField(1)
  final int spo2;

  @HiveField(2)
  final int ir;

  @HiveField(3)
  final int red;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final DateTime timestamp;

  SensorData({
    required this.heartRate,
    required this.spo2,
    required this.ir,
    required this.red,
    required this.status,
    required this.timestamp,
  });
}