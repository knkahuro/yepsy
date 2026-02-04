// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleDataAdapter extends TypeAdapter<CycleData> {
  @override
  final int typeId = 6;

  @override
  CycleData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleData(
      periodStartDate: fields[0] as DateTime,
      periodEndDate: fields[1] as DateTime?,
      cycleLength: fields[2] as int,
      periodLength: fields[3] as int,
      isAnomaly: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CycleData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.periodStartDate)
      ..writeByte(1)
      ..write(obj.periodEndDate)
      ..writeByte(2)
      ..write(obj.cycleLength)
      ..writeByte(3)
      ..write(obj.periodLength)
      ..writeByte(4)
      ..write(obj.isAnomaly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserCycleProfileAdapter extends TypeAdapter<UserCycleProfile> {
  @override
  final int typeId = 7;

  @override
  UserCycleProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserCycleProfile(
      averageCycleLength: fields[0] as int,
      averagePeriodLength: fields[1] as int,
      historicalCycles: (fields[2] as List).cast<CycleData>(),
      lastPeriodStart: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserCycleProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.averageCycleLength)
      ..writeByte(1)
      ..write(obj.averagePeriodLength)
      ..writeByte(2)
      ..write(obj.historicalCycles)
      ..writeByte(3)
      ..write(obj.lastPeriodStart);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCycleProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
