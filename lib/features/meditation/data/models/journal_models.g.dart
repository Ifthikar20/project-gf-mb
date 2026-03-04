// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeditationJournalEntryAdapter
    extends TypeAdapter<MeditationJournalEntry> {
  @override
  final int typeId = 32;

  @override
  MeditationJournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeditationJournalEntry(
      date: fields[0] as DateTime,
      moodAfter: fields[1] as int,
      gratitude: fields[2] as String?,
      note: fields[3] as String?,
      sessionType: fields[4] as String,
      durationSeconds: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MeditationJournalEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.moodAfter)
      ..writeByte(2)
      ..write(obj.gratitude)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.sessionType)
      ..writeByte(5)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeditationJournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
