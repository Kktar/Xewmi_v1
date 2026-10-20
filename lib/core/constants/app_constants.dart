class AppConstants {
  AppConstants._();

  static const String appName = 'Sunu Tikeu';
  static const String appTagline = 'Achetez vos billets en toute sécurité';

  // Supabase (à remplacer par vos vraies valeurs)
  static const String supabaseUrl = 'https://sdhmzszlwubwlemdzoju.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkaG16c3psd3Vid2xlbWR6b2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0OTA0NjAsImV4cCI6MjEwNzA2NjQ2MH0.jupAF5Z_bLb7_YuP_YTOtAJ5KTuHS3y26gGeoKGB5GE';

  // Payment providers (Senegal)
  // Recommandé : PayDunya ou CinetPay pour Wave + Orange Money + Free Money
  static const String paydunyaMasterKey =
      String.fromEnvironment('PAYDUNYA_MASTER_KEY');
  static const String paydunyaPrivateKey =
      String.fromEnvironment('PAYDUNYA_PRIVATE_KEY');
  static const String paydunyaToken = String.fromEnvironment('PAYDUNYA_TOKEN');
  static const String paydunyaMode =
      String.fromEnvironment('PAYDUNYA_MODE', defaultValue: 'test');

  static const String cinetpayApiKey =
      String.fromEnvironment('CINETPAY_API_KEY');
  static const String cinetpaySiteId =
      String.fromEnvironment('CINETPAY_SITE_ID');

  // Currency
  static const String currency = 'XOF';
  static const String currencySymbol = 'FCFA';

  /// Frais de publication pour un événement à entrée libre (FCFA)
  static const int freeEventPublishFee = 50000;

  // Pagination
  static const int pageSize = 20;

  // Categories
  static const List<String> eventCategories = [
    'Concerts',
    'Festivals',
    'Conférences',
    'Sport',
    'Théâtre',
    'Culture',
    'Business',
    'Autres',
  ];
}
