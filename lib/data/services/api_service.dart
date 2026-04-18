import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders(
      {bool requiresAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
  try {
    final deviceInfo = DeviceInfoPlugin();

    // ✅ WEB SUPPORT
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      return {
        'device_id': webInfo.userAgent ?? 'web',
        'device_name': webInfo.browserName.name,
        'os_version': 'Web',
        'app_version': '1.0.0',
      };
    }

    // ✅ MOBILE
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'device_id': androidInfo.id ?? 'unknown',
        'device_name': androidInfo.model ?? 'unknown',
        'os_version': 'Android ${androidInfo.version.release}',
        'app_version': '1.0.0',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'device_id': iosInfo.identifierForVendor ?? 'unknown',
        'device_name': iosInfo.name ?? 'unknown',
        'os_version': 'iOS ${iosInfo.systemVersion}',
        'app_version': '1.0.0',
      };
    }
  } catch (e) {
    print("Device info error: $e");
  }

  return {};
}

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,      
  }) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.get(uri, headers: headers);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }

  // Auth APIs
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final deviceInfo = await _getDeviceInfo();

    return await post(ApiConstants.register, {
      'email': email,
      'password': password,
      'invite_code': inviteCode,
      'device_info': deviceInfo,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final deviceInfo = await _getDeviceInfo();

    return await post(ApiConstants.login, {
      'email': email,
      'password': password,
      'device_info': deviceInfo,
    });
  }

  // Attendance APIs
  static Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
  }) async {
    return await post(
      ApiConstants.clockIn,
      {'latitude': latitude, 'longitude': longitude},
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    return await post(
      ApiConstants.clockOut,
      {'latitude': latitude, 'longitude': longitude},
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> getTodayAttendance() async {
    return await get(ApiConstants.todayAttendance);
  }

  static Future<Map<String, dynamic>> getAttendanceHistory() async {
    return await get(ApiConstants.attendanceHistory);
  }

  static Future<Map<String, dynamic>> getMonthlyCalendar({
    required int month,
    required int year,
  }) async =>
      await get(ApiConstants.calendar,
          queryParams: {'month': month.toString(), 'year': year.toString()});
}