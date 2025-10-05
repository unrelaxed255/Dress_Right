// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prefs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrefsAdapter extends TypeAdapter<Prefs> {
  @override
  final int typeId = 4;

  @override
  Prefs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Prefs(
      theme: fields[0] as String,
      emailSignature: fields[1] as EmailSignature?,
      dafiLocalPath: fields[2] as String?,
      dafiLastPage: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Prefs obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.emailSignature)
      ..writeByte(2)
      ..write(obj.dafiLocalPath)
      ..writeByte(3)
      ..write(obj.dafiLastPage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailSignatureAdapter extends TypeAdapter<EmailSignature> {
  @override
  final int typeId = 5;

  @override
  EmailSignature read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailSignature(
      rankName: fields[0] as String,
      phone: fields[1] as String,
      email: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmailSignature obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.rankName)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.email);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSignatureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
