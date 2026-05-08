class ApiEndpoints {
  ApiEndpoints._();

  // Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:5000
  // For physical device use: http://YOUR_LOCAL_IP:5000
  // For production use: https://your-deployed-api.com
  static const String baseUrl = 'http://192.168.170.82:5000/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Customers
  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';

  // Debts
  static String debts(String customerId) => '/debts/$customerId';
  static String debtMarkPaid(String id) => '/debts/$id/mark-paid';
  static String debt(String id) => '/debts/$id';

  // Credits
  static String credits(String customerId) => '/credits/$customerId';
  static String credit(String id) => '/credits/$id';
}
