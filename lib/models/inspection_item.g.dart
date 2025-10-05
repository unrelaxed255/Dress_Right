// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InspectionItemAdapter extends TypeAdapter<InspectionItem> {
  @override
  final int typeId = 3;

  @override
  InspectionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionItem(
      compositeId: fields[0] as String,
      inspectionId: fields[1] as String,
      itemId: fields[2] as String,
      fieldKey: fields[3] as String,
      label: fields[4] as String,
      result: fields[5] as String,
      comment: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.compositeId)
      ..writeByte(1)
      ..write(obj.inspectionId)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.fieldKey)
      ..writeByte(4)
      ..write(obj.label)
      ..writeByte(5)
      ..write(obj.result)
      ..writeByte(6)
      ..write(obj.comment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
