import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../constants/api_config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static String? _authToken;
  
  // Initialize token from storage on app start
  static Future<void> initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }
  
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    
    return headers;
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _authToken != null;

  // Authentication methods
  static Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/accounts/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(ApiConfig.connectTimeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = UserProfile.fromJson(data['user']);
        
        // Store the token persistently
        await setAuthToken(token);
        
        return LoginResponse(
          success: true,
          token: token,
          user: user,
          message: data['message'],
        );
      } else {
        return LoginResponse(
          success: false,
          error: data['error'] ?? 'Login failed',
          details: data['details'],
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  static Future<RegisterResponse> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/accounts/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      ).timeout(ApiConfig.connectTimeout);

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return RegisterResponse(
          success: true,
          user: UserProfile.fromJson(data['user']),
          message: data['message'],
        );
      } else {
        return RegisterResponse(
          success: false,
          error: data['error'] ?? 'Registration failed',
          details: data['details'],
        );
      }
    } catch (e) {
      return RegisterResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse<UserProfile>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/accounts/profile/'),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserProfile.fromJson(data['user']);
        
        return ApiResponse(
          results: [user],
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  static Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/accounts/logout/'),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        await clearAuthToken();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get all colleges
  static Future<ApiResponse<College>> getColleges({String? search}) async {
    try {
      String url = '${ApiConfig.baseUrl}/colleges/';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final colleges = data.map((json) => College.fromJson(json)).toList();
        
        return ApiResponse(
          results: colleges,
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load colleges: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get branches for a specific college
  static Future<ApiResponse<Branch>> getBranches(int collegeId, {String? search}) async {
    try {
      String url = '${ApiConfig.baseUrl}/branches/?college_id=$collegeId';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final branches = data.map((json) => Branch.fromJson(json)).toList();
        
        return ApiResponse(
          results: branches,
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load branches: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get subjects for a specific branch or all subjects in a college
  static Future<ApiResponse<Subject>> getSubjects({int? branchId, int? collegeId, String? search}) async {
    try {
      String url = '${ApiConfig.baseUrl}/subjects/?';
      
      if (branchId != null) {
        url += 'branch_id=$branchId';
      } else if (collegeId != null) {
        url += 'college_id=$collegeId';
      } else {
        // If neither is provided, return empty response
        return ApiResponse(
          results: [],
          success: false,
          error: 'Either branchId or collegeId must be provided',
        );
      }
      
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final subjects = data.map((json) => Subject.fromJson(json)).toList();
        
        return ApiResponse(
          results: subjects,
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load subjects: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get PYQs for a specific subject
  static Future<ApiResponse<PreviousYearQuestion>> getPYQs({
    required int subjectId,
    int? year,
    int? semester,
    String? regulation,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/pyqs/?subject_id=$subjectId';
      
      if (year != null) {
        url += '&year=$year';
      }
      if (semester != null) {
        url += '&semester=$semester';
      }
      if (regulation != null && regulation.isNotEmpty) {
        url += '&regulation=$regulation';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final pyqs = data.map((json) => PreviousYearQuestion.fromJson(json)).toList();
        
        return ApiResponse(
          results: pyqs,
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load PYQs: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Upload a new PYQ
  static Future<ApiResponse<PreviousYearQuestion>> uploadPYQ({
    required int subjectId,
    required int year,
    required int semester,
    required File pdfFile,
    String? regulation,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/pyqs/upload/'),
      );

      // Add headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Token $_authToken';
      }

      // Add form fields
      request.fields['subject'] = subjectId.toString();
      request.fields['year'] = year.toString();
      request.fields['semester'] = semester.toString();
      if (regulation != null && regulation.isNotEmpty) {
        request.fields['regulation'] = regulation;
      }

      // Add PDF file
      request.files.add(
        await http.MultipartFile.fromPath(
          'paper_file',
          pdfFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(minutes: 2));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Upload successful - don't try to parse the simplified response
        // Just return success without trying to create a full PYQ object
        return ApiResponse(
          results: [], // Empty results since we don't have a complete PYQ object
          success: true,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          results: [],
          success: false,
          error: errorData['error'] ?? 'Upload failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get user's uploaded PYQs
  static Future<ApiResponse<PreviousYearQuestion>> getUserPYQs() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/accounts/profile/'),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pyqs = (data['uploaded_pyqs'] as List<dynamic>?)
            ?.map((json) => PreviousYearQuestion.fromJson(json))
            .toList() ?? [];
        
        return ApiResponse(
          results: pyqs,
          success: true,
        );
      } else {
        return ApiResponse(
          results: [],
          success: false,
          error: 'Failed to load user PYQs: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        results: [],
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get download URL for a PYQ
  static String getPYQDownloadUrl(int pyqId, {bool download = false}) {
    String url = '${ApiConfig.baseUrl}/pyqs/$pyqId/download/';
    if (download) {
      url += '?download=true';
    }
    return url;
  }
}