import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String businessName;

  Customer({required this.name, required this.businessName});
}
