import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? address;

  @HiveField(4)
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.createdAt,
  });
}
