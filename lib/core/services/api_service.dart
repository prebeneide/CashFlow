import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import 'supabase_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Dio get client => _dio;

  // Initialiser med auth token
  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Legg til auth token hvis bruker er logget inn
          final session = SupabaseService.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Håndter 401 (unauthorized) - token kan være utløpt
          if (error.response?.statusCode == 401) {
            // Logg ut bruker hvis token er ugyldig
            SupabaseService.client.auth.signOut();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET request
  static Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST request
  static Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PUT request
  static Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // DELETE request
  static Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

