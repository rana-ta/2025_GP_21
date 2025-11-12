// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensors.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorDataAdapter extends TypeAdapter<SensorData> {
  @override
  final int typeId = 0;

  @override
  SensorData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorData(
      heartRate: fields[0] as int,
      spo2: fields[1] as int,
      ir: fields[2] as int,
      red: fields[3] as int,
      status: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SensorData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.heartRate)
      ..writeByte(1)
      ..write(obj.spo2)
      ..writeByte(2)
      ..write(obj.ir)
      ..writeByte(3)
      ..write(obj.red)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SensorDataAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}