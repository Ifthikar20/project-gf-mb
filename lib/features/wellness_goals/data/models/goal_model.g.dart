// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 0;

  @override
  GoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      targetValue: fields[4] as int,
      currentValue: fields[5] as int,
      createdAt: fields[6] as DateTime,
      targetDate: fields[7] as DateTime?,
      isCompleted: fields[8] as bool,
      typeIndex: fields[9] as int,
      periodIndex: fields[10] as int,
      periodStart: fields[11] as DateTime?,
      trackedIdsList: (fields[12] as List).cast<String>(),
      streakDays: fields[13] as int,
      lastActivityDate: fields[14] as DateTime?,
      iconName: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.targetValue)
      ..writeByte(5)
      ..write(obj.currentValue)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.targetDate)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.typeIndex)
      ..writeByte(10)
      ..write(obj.periodIndex)
      ..writeByte(11)
      ..write(obj.periodStart)
      ..writeByte(12)
      ..write(obj.trackedIdsList)
      ..writeByte(13)
      ..write(obj.streakDays)
      ..writeByte(14)
      ..write(obj.lastActivityDate)
      ..writeByte(15)
      ..write(obj.iconName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
