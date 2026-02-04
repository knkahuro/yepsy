// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SymptomLogAdapter extends TypeAdapter<SymptomLog> {
  @override
  final int typeId = 1;

  @override
  SymptomLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymptomLog(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      symptoms: (fields[2] as List).cast<String>(),
      painLevel: fields[3] as int?,
      flowIntensity: fields[4] as int?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SymptomLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.symptoms)
      ..writeByte(3)
      ..write(obj.painLevel)
      ..writeByte(4)
      ..write(obj.flowIntensity)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
