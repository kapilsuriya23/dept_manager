class UserModel {
  final String id;
  final String shopName;
  final String phone;

  UserModel({
    required this.id,
    required this.shopName,
    required this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['_id'] ?? '',
        shopName: json['shopName'] ?? '',
        phone: json['phone'] ?? '',
      );
}
