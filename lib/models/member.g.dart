// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 0;

  @override
  Member read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Member(
      memberId: fields[0] as String,
      rank: fields[1] as String,
      name: fields[2] as String,
      workcenter: fields[3] as String,
      status: fields[4] as String,
      assignments: (fields[5] as List?)?.cast<MemberAssignment>(),
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.rank)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.workcenter)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.assignments)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemberAssignmentAdapter extends TypeAdapter<MemberAssignment> {
  @override
  final int typeId = 1;

  @override
  MemberAssignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberAssignment(
      workcenter: fields[0] as String,
      startedAt: fields[1] as DateTime,
      endedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MemberAssignment obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.workcenter)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.endedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
