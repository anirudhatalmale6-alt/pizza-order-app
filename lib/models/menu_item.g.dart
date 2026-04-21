// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 0;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MenuItem(
      name: fields[0] as String,
      nameThai: fields[1] as String,
      price: fields[2] as double,
      type: fields[3] as String,
      isActive: fields[4] as bool,
      optionGroup: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.nameThai)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.optionGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ToppingItemAdapter extends TypeAdapter<ToppingItem> {
  @override
  final int typeId = 1;

  @override
  ToppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ToppingItem(
      name: fields[0] as String,
      nameThai: fields[1] as String,
      price: fields[2] as double,
      isActive: fields[3] as bool,
      category: fields[4] as String? ?? 'all',
    );
  }

  @override
  void write(BinaryWriter writer, ToppingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.nameThai)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToppingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
