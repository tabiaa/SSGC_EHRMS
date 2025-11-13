import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dependent.dart';

class ApiService {
  static const String baseUrl = 'http://202.83.165.73:2002/api1/';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  ));

 
  static Future<Map<String, dynamic>> login(int employeeId, String password) async {
    try {
      final response = await _dio.post(
        '/login.php',
        data: {'employee_id': employeeId, 'password': password},
      );

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
      }

      return data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Login failed: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Request OTP
  static Future<Map<String, dynamic>> requestOtp(String employeeId) async {
    try {
      final response = await _dio.post(
        '/request_otp.php',
        data: {'employee_id': employeeId},
      );
      return response.data is String ? jsonDecode(response.data) : response.data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to request OTP: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request OTP: $e'};
    }
  }

  // Verify OTP (first step)
  static Future<Map<String, dynamic>> verifyOtp({
    required String employeeId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/verify_otp.php',
        data: {'employee_id': employeeId, 'otp': otp},
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['success'] == true && data['token'] != null) {
        // Assuming it returns a temp token for the next step
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_token', data['token']);
      }

      return data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to verify OTP: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify OTP: $e'};
    }
  }

  // Create account (second step)
  static Future<Map<String, dynamic>> createPassword({
    required String employeeId,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempToken = prefs.getString('temp_token');
      if (tempToken == null) return {'success': false, 'message': 'Missing verification token.'};

      final response = await _dio.post(
        '/create_password.php', 
        data: {'employee_id': employeeId, 'password': password, 'token': tempToken},
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;


      if (data['success'] == true && data['token'] != null) {
         await prefs.setString('auth_token', data['token']); 
         await prefs.remove('temp_token'); 
      }

      return data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to create password: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create password: $e'};
    }
  }


  static Future<List<Dependent>> getDependents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return []; // Return empty list if not logged in

      final response = await _dio.get(
        '/get_dependants.php',
        options: Options(headers: {'Authorization': 'Bearer $token',
         'X-App-Key': '4Abb^!*%_)@549~+noD!e.J_',
        }),
      );

      print('Raw response type: ${response.data.runtimeType}');
      print('API Response: ${response.data}');

      dynamic data = response.data;

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
            print('Error: dependents field is not a list: $deps');
            return [];
          }
        } else {
          print('API returned success=false: ${data['message'] ?? data}');
          return [];
        }
      } else if (data is List) {
        dependentsList = data;
      } else {
        print('Error: Unexpected response format: $data');
        return [];
      }

      return dependentsList
          .map((d) => Dependent.fromJson(d as Map<String, dynamic>))
          .toList();

    } on DioException catch (e) {
      print('Network error: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      print('General error: $e');
      return [];
    }
  }

  // Update Dependent (example)
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

    print("Update response (raw): ${response.data}");

dynamic data = response.data;
if (data is String) {
  try {
    data = jsonDecode(data);
  } catch (e) {
    print("JSON decode error: $e");
    return {'success': false, 'message': 'Invalid JSON from server'};
  }
}

if (data is Map<String, dynamic>) {
  return data;
} else {
  return {'success': false, 'message': 'Unexpected response format: $data'};
}

  } on DioException catch (e) {
    print("Dio error  ${e.response?.data}");
    print("Dio status: ${e.response?.statusCode}");
    print("Dio message: ${e.message}");
    final errorMessage = e.response?.data?['message'] ?? 
                         e.response?.data?.toString() ?? 
                         'Update failed: ${e.message}';
    return {'success': false, 'message': errorMessage};
  } catch (e) {
    return {'success': false, 'message': 'Update failed: $e'};
  }
}

static Future<Map<String, dynamic>> uploadFile(
    int dependentId, String fieldKey, String filePath) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      return {'success': false, 'message': 'Missing auth token. Please log in again.'};
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
      'X-App-Key': '4Abb^!*%_)@549~+noD!e.J_',
    },
  ),
);

    print("Uploading $fieldKey for dependent $dependentId");
    print("Upload response: ${response.data}");
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {'success': false, 'message': 'Unexpected response format from server'};
    }
  } on DioException catch (e) {
    print(" Dio upload error: ${e.response?.data ?? e.message}");
    final errorMessage = e.response?.data?['message'] ?? 
                         e.response?.data?.toString() ?? 
                         'Upload failed: ${e.message}';
    return {'success': false, 'message': errorMessage};
  } catch (e) {
    print("General upload error: $e");
    return {'success': false, 'message': 'Upload failed: $e'};
  }
}

  // Forgot Password Methods
  static Future<Map<String, dynamic>> requestForgotPasswordOtp(String employeeId) async {
    try {
      final response = await _dio.post(
        '/forgot_password_request.php',
        data: {'employee_id': employeeId},
      );
      return response.data is String ? jsonDecode(response.data) : response.data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to request OTP: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request OTP: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String employeeId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/forgot_password_verify.php',
        data: {'employee_id': employeeId, 'otp': otp},
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['success'] == true && data['token'] != null) {
        // Store temp token for password reset
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('forgot_password_temp_token', data['token']);
      }

      return data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to verify OTP: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify OTP: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String employeeId,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempToken = prefs.getString('forgot_password_temp_token');
      if (tempToken == null) return {'success': false, 'message': 'Verification token expired. Please restart the process.'};

      final response = await _dio.post(
        '/forgot_password_reset.php',
        data: {'employee_id': employeeId, 'password': newPassword, 'token': tempToken},
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['success'] == true) {
        // Clear the temp token after successful reset
        await prefs.remove('forgot_password_temp_token');
      }

      return data;
    } on DioException catch (e) {
      // Return error message instead of throwing exception
      final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?.toString() ?? 
                           'Failed to reset password: ${e.message}';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reset password: $e'};
    }
  }

}