class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl =
      'https://chinthamani-dept-manager.onrender.com/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';
  static String debts(String cId) => '/debts/$cId';
  static String debtMarkPaid(String id) => '/debts/$id/mark-paid';
  static String debt(String id) => '/debts/$id';
  static String credits(String cId) => '/credits/$cId';
  static String credit(String id) => '/credits/$id';
}
