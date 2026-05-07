import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 1)
class DebtModel extends HiveObject {
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

  @HiveField(5)
  bool isPaid;

  @HiveField(6)
  DateTime? paidAt;

  DebtModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.description,
    required this.date,
    this.isPaid = false,
    this.paidAt,
  });
}
