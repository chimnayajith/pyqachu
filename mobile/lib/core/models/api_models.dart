import '../constants/api_config.dart';

class College {
  final int id;
  final String name;
  final String? location;
  final bool isActive;
  final DateTime createdAt;
  final int adminCount;
  final int moderatorCount;
  final String? userRole;

  College({
    required this.id,
    required this.name,
    this.location,
    required this.isActive,
    required this.createdAt,
    required this.adminCount,
    required this.moderatorCount,
    this.userRole,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      adminCount: json['admin_count'] ?? 0,
      moderatorCount: json['moderator_count'] ?? 0,
      userRole: json['user_role'],
    );
  }
}

class Branch {
  final int id;
  final String name;
  final String? code;
  final int college;
  final String collegeName;
  final bool isActive;
  final int? createdBy;
  final String? createdByUsername;
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.name,
    this.code,
    required this.college,
    required this.collegeName,
    required this.isActive,
    this.createdBy,
    this.createdByUsername,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      college: json['college'],
      collegeName: json['college_name'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String? code;
  final int branch;
  final String branchName;
  final String collegeName;
  final bool isActive;
  final int? createdBy;
  final String? createdByUsername;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    this.code,
    required this.branch,
    required this.branchName,
    required this.collegeName,
    required this.isActive,
    this.createdBy,
    this.createdByUsername,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      branch: json['branch'],
      branchName: json['branch_name'],
      collegeName: json['college_name'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PreviousYearQuestion {
  final int id;
  final int year;
  final int semester;
  final String? regulation;
  final String paperFile;
  final String _pdfUrl; // Store relative URL from backend
  final int uploadedBy;
  final String uploadedByUsername;
  final String status;
  final String statusDisplay;
  final int? reviewedBy;
  final String? reviewedByUsername;
  final String? reviewNotes;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final int subject;
  final String subjectName;
  final String branchName;
  final String collegeName;

  PreviousYearQuestion({
    required this.id,
    required this.year,
    required this.semester,
    this.regulation,
    required this.paperFile,
    required String pdfUrl,
    required this.uploadedBy,
    required this.uploadedByUsername,
    required this.status,
    required this.statusDisplay,
    this.reviewedBy,
    this.reviewedByUsername,
    this.reviewNotes,
    required this.uploadedAt,
    this.reviewedAt,
    required this.subject,
    required this.subjectName,
    required this.branchName,
    required this.collegeName,
  }) : _pdfUrl = pdfUrl;

  // Construct complete PDF URL using ApiConfig.baseUrl
  String get pdfUrl {
    if (_pdfUrl.isNotEmpty) {
      // If the URL is already complete (starts with http), return as is
      if (_pdfUrl.startsWith('http')) {
        return _pdfUrl;
      }
      // Otherwise, construct complete URL by removing /api from baseUrl
      final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
      return '$baseUrlWithoutApi$_pdfUrl';
    }
    return '';
  }

  factory PreviousYearQuestion.fromJson(Map<String, dynamic> json) {
    return PreviousYearQuestion(
      id: json['id'],
      year: json['year'],
      semester: json['semester'],
      regulation: json['regulation'],
      paperFile: json['paper_file'],
      pdfUrl: json['pdf_url'] ?? '',
      uploadedBy: json['uploaded_by'],
      uploadedByUsername: json['uploaded_by_username'],
      status: json['status'],
      statusDisplay: json['status_display'],
      reviewedBy: json['reviewed_by'],
      reviewedByUsername: json['reviewed_by_username'],
      reviewNotes: json['review_notes'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      subject: json['subject'],
      subjectName: json['subject_name'],
      branchName: json['branch_name'],
      collegeName: json['college_name'],
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
    );
  }
}

class LoginResponse {
  final bool success;
  final String? token;
  final UserProfile? user;
  final String? message;
  final String? error;
  final Map<String, dynamic>? details;

  LoginResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.error,
    this.details,
  });
}

class RegisterResponse {
  final bool success;
  final UserProfile? user;
  final String? message;
  final String? error;
  final Map<String, dynamic>? details;

  RegisterResponse({
    required this.success,
    this.user,
    this.message,
    this.error,
    this.details,
  });
}

class ApiResponse<T> {
  final List<T> results;
  final bool success;
  final String? error;

  ApiResponse({
    required this.results,
    required this.success,
    this.error,
  });
}