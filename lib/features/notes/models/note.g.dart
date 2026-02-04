// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 3;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      title: fields[0] as String,
      message: fields[1] as String,
      isPinned: fields[2] as bool,
      mood: fields[3] as Mood?,
      date: fields[4] as DateTime?,
      id: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.isPinned)
      ..writeByte(3)
      ..write(obj.mood)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodAdapter extends TypeAdapter<Mood> {
  @override
  final int typeId = 4;

  @override
  Mood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Mood.happy;
      case 1:
        return Mood.sad;
      case 2:
        return Mood.neutral;
      case 3:
        return Mood.excited;
      case 4:
        return Mood.tired;
      default:
        return Mood.happy;
    }
  }

  @override
  void write(BinaryWriter writer, Mood obj) {
    switch (obj) {
      case Mood.happy:
        writer.writeByte(0);
        break;
      case Mood.sad:
        writer.writeByte(1);
        break;
      case Mood.neutral:
        writer.writeByte(2);
        break;
      case Mood.excited:
        writer.writeByte(3);
        break;
      case Mood.tired:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
