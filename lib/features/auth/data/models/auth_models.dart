// ⚠️ API CONTRACT v1.0.0 — Models match §3.1 and §3.3.

import 'package:equatable/equatable.dart';

import '../../../profile/data/models/employee_profile_model.dart';

/// Successful login payload.
///
/// Contract (simplified):
/// `{ token, token_type, employee }`
class LoginData extends Equatable {
  final String token;
  final String tokenType;
  final EmployeeProfile employee;

  const LoginData({
    required this.token,
    required this.tokenType,
    required this.employee,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    print('LoginData.fromJson: $json');
    return LoginData(
      token: json['token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      employee: EmployeeProfile.fromJson(
        json['employee'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'token_type': tokenType,
        'employee': employee.toJson(),
      };

  @override
  List<Object?> get props => [token, tokenType, employee];
}

/// Logout-all payload.
///
/// Contract example:
/// `{ revoked_tokens: 3 }`
class LogoutAllData extends Equatable {
  final int revokedTokens;

  const LogoutAllData({required this.revokedTokens});

  factory LogoutAllData.fromJson(Map<String, dynamic> json) {
    return LogoutAllData(
      revokedTokens: (json['revoked_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'revoked_tokens': revokedTokens,
      };

  @override
  List<Object?> get props => [revokedTokens];
}
