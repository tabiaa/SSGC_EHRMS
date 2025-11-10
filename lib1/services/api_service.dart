import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dependent.dart';

class ApiService {
  static const String baseUrl = 'http://10.86.24.182/api1';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  ));

  // Store JWT after login
  static Future<Map<String, dynamic>> login(int employeeId, String password) async {
    try {
      final response = await _dio.post(
        '/login.php',
        data: {'employee_id': employeeId, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['token'] != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
      }

      return data;
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }

  // Authorized GET dependents request
static Future<List<Dependent>> getDependents() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('Not logged in: token missing');

    final response = await _dio.get(
      '/get_dependants.php',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    print('✅ Raw response type: ${response.data.runtimeType}');
    print('✅ API Response: ${response.data}');

    dynamic data = response.data;

    // 🧩 FIX HERE
    if (data is String) {
      data = jsonDecode(data);
    }

    List<dynamic> dependentsList;

    if (data is Map<String, dynamic>) {
      if (data['success'] == true) {
        final deps = data['dependents'];
        if (deps is List) {
          dependentsList = deps;
        } else {
          throw Exception('dependents field is not a list: $deps');
        }
      } else {
        throw Exception('API returned success=false: ${data['message'] ?? data}');
      }
    } else if (data is List) {
      dependentsList = data;
    } else {
      throw Exception('Unexpected response format: $data');
    }

    return dependentsList
        .map((d) => Dependent.fromJson(d as Map<String, dynamic>))
        .toList();

  } on DioException catch (e) {
    print('❌ Network error: ${e.response?.data ?? e.message}');
    throw Exception('Network error: ${e.message}');
  }
}

  // 🧩 Update dependent (authorized)
  static Future<Map<String, dynamic>> updateDependent(
    int id, Map<String, dynamic> fields) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await _dio.post(
      '/update_dependant.php',
      data: {'id': id, ...fields},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    print("✅ Update response: ${response.data}");
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    print("❌ Dio error data: ${e.response?.data}");
    print("❌ Dio status: ${e.response?.statusCode}");
    print("❌ Dio message: ${e.message}");
    throw Exception('Update failed: ${e.response?.data ?? e.message}');
  }
}


  // 🧩 Upload file (authorized)
  static Future<Map<String, dynamic>> uploadFile(
    int dependentId, String fieldKey, String filePath) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Missing auth token. Please log in again.');
    }

    final formData = FormData.fromMap({
      'dependent_id': dependentId.toString(),
      'field': fieldKey,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/upload.php',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    print("📤 Uploading $fieldKey for dependent $dependentId");
    print("✅ Upload response: ${response.data}");

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Unexpected response format from server');
    }
  } on DioException catch (e) {
    print("❌ Dio upload error: ${e.response?.data ?? e.message}");
    throw Exception(
        'Upload failed: ${e.response?.data ?? e.message ?? 'Unknown error'}');
  } catch (e) {
    print("❌ General upload error: $e");
    throw Exception('Upload failed: $e');
  }
}
}
