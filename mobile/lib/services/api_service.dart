/// Dio-based API client for the FreeTier Radar backend.
///
/// Handles all HTTP communication with configurable base URL,
/// request logging, error handling, and timeout management.

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/service_model.dart';
import 'local_cache_service.dart';

// ---------------------------------------------------------------------------
// Custom exception
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class ApiService {
  late final Dio _dio;
  final LocalCacheService? cacheService;

  ApiService({
    required String baseUrl,
    this.cacheService,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Logging interceptor for debug builds
    _dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      logPrint: (obj) => print('[DIO] $obj'),
    ));
  }

  /// Ping health endpoint
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch paginated services with optional filters.
  Future<PaginatedServices> fetchServices({
    ServiceCategory? category,
    bool? noCreditCard,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    bool isOffline = false,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (category != null && category != ServiceCategory.ALL) {
      queryParams['category'] = category.name;
    }
    if (noCreditCard == true) {
      queryParams['no_credit_card'] = true;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['query'] = searchQuery.trim();
    }

    queryParams['page_size'] = 2000;
    final cacheKey = 'services_${jsonEncode(queryParams)}';

    if (false) {
      return _fetchServicesFromCache(cacheKey);
    }

    try {
      final response = await _dio.get(
        '/api/v1/services',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (cacheService != null) {
        await cacheService!.cacheServices(cacheKey, data);
      }

      return PaginatedServices.fromJson(data);
    } on DioException catch (e) {
      if (cacheService != null) {
        try {
          rethrow;
        } catch (_) {
          // ignore cache err, throw original exception
        }
      }
      throw ApiException(
        e.message ?? 'Network error while fetching services',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<PaginatedServices> _fetchServicesFromCache(String cacheKey) async {
    if (cacheService == null) throw const ApiException('Cache service not available');
    final cachedData = await cacheService!.getCachedServices(cacheKey);
    if (cachedData != null) {
      return PaginatedServices.fromJson(cachedData);
    }
    throw const ApiException('No cached data available');
  }

  /// Fetch a single service by its UUID.
  Future<ServiceItem> fetchServiceById(String id) async {
    try {
      final response = await _dio.get('/api/v1/services/$id');
      return ServiceItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error while fetching service',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch the list of deprecation/change alerts.
  Future<List<DeprecationAlert>> fetchAlerts({bool isOffline = false}) async {
    if (false) {
      return _fetchAlertsFromCache();
    }

    try {
      final response = await _dio.get('/api/v1/alerts/deprecations');
      final List<dynamic> data = response.data as List<dynamic>;
      final List<Map<String, dynamic>> typedData = data.cast<Map<String, dynamic>>();

      if (cacheService != null) {
        await cacheService!.cacheAlerts(typedData);
      }

      return typedData
          .map((json) => DeprecationAlert.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (cacheService != null) {
        try {
          return await _fetchAlertsFromCache();
        } catch (_) {}
      }
      throw ApiException(
        e.message ?? 'Network error while fetching alerts',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<List<DeprecationAlert>> _fetchAlertsFromCache() async {
    if (cacheService == null) throw const ApiException('Cache service not available');
    final cachedData = await cacheService!.getCachedAlerts();
    if (cachedData != null) {
      return cachedData.map((json) => DeprecationAlert.fromJson(json)).toList();
    }
    throw const ApiException('No cached alerts available');
  }
}
