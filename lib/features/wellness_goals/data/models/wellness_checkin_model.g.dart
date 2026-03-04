// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wellness_checkin_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WellnessCheckInModelAdapter extends TypeAdapter<WellnessCheckInModel> {
  @override
  final int typeId = 20;

  @override
  WellnessCheckInModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WellnessCheckInModel(
      mood: fields[0] as int,
      energyLevel: fields[1] as int,
      sleepQuality: fields[2] as int?,
      date: fields[3] as DateTime,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WellnessCheckInModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.mood)
      ..writeByte(1)
      ..write(obj.energyLevel)
      ..writeByte(2)
      ..write(obj.sleepQuality)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WellnessCheckInModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
