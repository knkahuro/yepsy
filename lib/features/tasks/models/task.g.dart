// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityTaskAdapter extends TypeAdapter<ActivityTask> {
  @override
  final int typeId = 5;

  @override
  ActivityTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityTask(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String,
      isFavorite: fields[3] as bool,
      category: fields[5] as String,
      date: fields[7] as DateTime?,
      taskTime: fields[8] as DateTime?,
      completedDates: (fields[9] as List?)?.cast<DateTime>(),
      frequency: (fields[10] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, ActivityTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isFavorite)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.taskTime)
      ..writeByte(9)
      ..write(obj.completedDates)
      ..writeByte(10)
      ..write(obj.frequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
