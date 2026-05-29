/// Constantes de comunicação com o backend Python local.
abstract final class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 30000;

  // Endpoints
  static const String health = '/health';
  static const String projects = '/projects';
  static const String upload = '/upload';
  static const String train = '/train';
  static const String models = '/models';
  static const String predict = '/predict';
  static const String metrics = '/metrics';
  static const String assistant = '/assistant/chat';
  static const String systemResources = '/system/resources';
}
