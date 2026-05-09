class ApiEndpoints {
  ApiEndpoints._();

  // ⚠️ Replace with YOUR PC's IP from ipconfig/ifconfig
  // Must be on same WiFi network as your phone
  static const String _ip = '192.168.31.248';
  static const String baseUrl = 'http://$_ip:5000/api';

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
