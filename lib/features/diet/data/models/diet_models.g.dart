// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diet_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override
  final int typeId = 31;

  @override
  MealLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealLog(
      name: fields[0] as String,
      calories: fields[1] as int,
      proteinGrams: fields[2] as int,
      carbsGrams: fields[3] as int,
      fatGrams: fields[4] as int,
      mealType: fields[5] as MealType,
      timestamp: fields[6] as DateTime,
      notes: fields[7] as String?,
      imagePath: fields[8] as String?,
      scanId: fields[9] as String?,
      mealName: fields[10] as String?,
      sugarGrams: fields[11] == null ? 0 : fields[11] as int,
      fiberGrams: fields[12] == null ? 0 : fields[12] as int,
      sodiumMg: fields[13] == null ? 0 : fields[13] as int,
      caffeineMg: fields[14] == null ? 0 : fields[14] as int,
      itemType: fields[15] == null ? 'solid' : fields[15] as String?,
      warningsJson: fields[16] as String?,
      imageUrl: fields[17] as String?,
      benefitsJson: fields[18] as String?,
      calorieBurnJson: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.proteinGrams)
      ..writeByte(3)
      ..write(obj.carbsGrams)
      ..writeByte(4)
      ..write(obj.fatGrams)
      ..writeByte(5)
      ..write(obj.mealType)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.imagePath)
      ..writeByte(9)
      ..write(obj.scanId)
      ..writeByte(10)
      ..write(obj.mealName)
      ..writeByte(11)
      ..write(obj.sugarGrams)
      ..writeByte(12)
      ..write(obj.fiberGrams)
      ..writeByte(13)
      ..write(obj.sodiumMg)
      ..writeByte(14)
      ..write(obj.caffeineMg)
      ..writeByte(15)
      ..write(obj.itemType)
      ..writeByte(16)
      ..write(obj.warningsJson)
      ..writeByte(17)
      ..write(obj.imageUrl)
      ..writeByte(18)
      ..write(obj.benefitsJson)
      ..writeByte(19)
      ..write(obj.calorieBurnJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealTypeAdapter extends TypeAdapter<MealType> {
  @override
  final int typeId = 30;

  @override
  MealType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealType.breakfast;
      case 1:
        return MealType.lunch;
      case 2:
        return MealType.dinner;
      case 3:
        return MealType.snack;
      default:
        return MealType.breakfast;
    }
  }

  @override
  void write(BinaryWriter writer, MealType obj) {
    switch (obj) {
      case MealType.breakfast:
        writer.writeByte(0);
        break;
      case MealType.lunch:
        writer.writeByte(1);
        break;
      case MealType.dinner:
        writer.writeByte(2);
        break;
      case MealType.snack:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
