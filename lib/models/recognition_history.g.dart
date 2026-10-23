// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecognitionHistoryAdapter extends TypeAdapter<RecognitionHistory> {
  @override
  final int typeId = 0;

  @override
  RecognitionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecognitionHistory(
      artworkId: fields[0] as String,
      artworkName: fields[1] as String,
      artista: fields[2] as String,
      sala: fields[3] as String,
      salaId: fields[4] as String,
      timestamp: fields[5] as DateTime,
      confidence: fields[6] as double,
      isFavorite: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecognitionHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.artworkId)
      ..writeByte(1)
      ..write(obj.artworkName)
      ..writeByte(2)
      ..write(obj.artista)
      ..writeByte(3)
      ..write(obj.sala)
      ..writeByte(4)
      ..write(obj.salaId)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.confidence)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
