/// API endpoint constants
class ApiConstants {
  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String properties = '/properties';
  static const String offers = '/offers';
  static const String visits = '/visits';
  static const String favorites = '/favorites';
  
  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String refreshToken = '$auth/refresh';
  static const String logout = '$auth/logout';
  
  // User endpoints
  static const String userMe = '$users/me';
  static const String userKyc = '$users/kyc';
  
  // Property endpoints
  static const String propertyList = properties;
  static String propertyDetail(int id) => '$properties/$id';
  static String propertyMedia(int id) => '$properties/$id/media';
  
  // Favorites endpoints
  static const String favoritesList = favorites;
  static String favoriteToggle(String id) => '$favorites/$id';
}
