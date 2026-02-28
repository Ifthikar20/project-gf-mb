// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual Hive adapters for FitnessProfileModel + enums

part of 'fitness_profile_model.dart';

class FitnessProfileModelAdapter extends TypeAdapter<FitnessProfileModel> {
  @override
  final int typeId = 21;

  @override
  FitnessProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FitnessProfileModel(
      bodyTypeIndex: fields[0] as int,
      fitnessGoalIndex: fields[1] as int,
      intensityIndex: fields[2] as int,
      preferredWorkoutIds: (fields[3] as List).cast<String>(),
      isSetUp: fields[4] as bool,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FitnessProfileModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.bodyTypeIndex)
      ..writeByte(1)
      ..write(obj.fitnessGoalIndex)
      ..writeByte(2)
      ..write(obj.intensityIndex)
      ..writeByte(3)
      ..write(obj.preferredWorkoutIds)
      ..writeByte(4)
      ..write(obj.isSetUp)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BodyTypeAdapter extends TypeAdapter<BodyType> {
  @override
  final int typeId = 22;

  @override
  BodyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BodyType.lean;
      case 1:
        return BodyType.athletic;
      case 2:
        return BodyType.stocky;
      default:
        return BodyType.athletic;
    }
  }

  @override
  void write(BinaryWriter writer, BodyType obj) {
    switch (obj) {
      case BodyType.lean:
        writer.writeByte(0);
        break;
      case BodyType.athletic:
        writer.writeByte(1);
        break;
      case BodyType.stocky:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FitnessGoalAdapter extends TypeAdapter<FitnessGoal> {
  @override
  final int typeId = 23;

  @override
  FitnessGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FitnessGoal.loseWeight;
      case 1:
        return FitnessGoal.buildMuscle;
      case 2:
        return FitnessGoal.stayActive;
      case 3:
        return FitnessGoal.improveFlexibility;
      default:
        return FitnessGoal.stayActive;
    }
  }

  @override
  void write(BinaryWriter writer, FitnessGoal obj) {
    switch (obj) {
      case FitnessGoal.loseWeight:
        writer.writeByte(0);
        break;
      case FitnessGoal.buildMuscle:
        writer.writeByte(1);
        break;
      case FitnessGoal.stayActive:
        writer.writeByte(2);
        break;
      case FitnessGoal.improveFlexibility:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutIntensityAdapter extends TypeAdapter<WorkoutIntensity> {
  @override
  final int typeId = 24;

  @override
  WorkoutIntensity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutIntensity.calm;
      case 1:
        return WorkoutIntensity.moderate;
      case 2:
        return WorkoutIntensity.aggressive;
      default:
        return WorkoutIntensity.moderate;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutIntensity obj) {
    switch (obj) {
      case WorkoutIntensity.calm:
        writer.writeByte(0);
        break;
      case WorkoutIntensity.moderate:
        writer.writeByte(1);
        break;
      case WorkoutIntensity.aggressive:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutIntensityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
