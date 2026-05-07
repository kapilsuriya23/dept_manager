import 'package:hive/hive.dart';

part 'credit_model.g.dart';

@HiveType(typeId: 2)
class CreditModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String description;

  @HiveField(4)
  final DateTime date;

  CreditModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.description,
    required this.date,
  });
}
