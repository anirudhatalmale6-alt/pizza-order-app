import 'package:hive/hive.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 0)
class MenuItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String nameThai;

  @HiveField(2)
  double price;

  @HiveField(3)
  String type; // 'pizza' or 'drink'

  @HiveField(4)
  bool isActive;

  MenuItem({
    required this.name,
    required this.nameThai,
    required this.price,
    required this.type,
    this.isActive = true,
  });
}

@HiveType(typeId: 1)
class ToppingItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String nameThai;

  @HiveField(2)
  double price;

  @HiveField(3)
  bool isActive;

  ToppingItem({
    required this.name,
    required this.nameThai,
    required this.price,
    this.isActive = true,
  });
}
