import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final UserModel? user;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
    this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final access = (json['access_token'] ?? json['access'])?.toString();
    final refresh = (json['refresh_token'] ?? json['refresh'])?.toString();
    if (access == null || refresh == null) {
      throw const FormatException('Invalid token response payload');
    }
    return TokenResponse(
      accessToken: access,
      refreshToken: refresh,
      tokenType: json['token_type']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String role;
  @JsonKey(name: 'preferred_location_id')
  final String? preferredLocationId;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.role,
    this.preferredLocationId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name']?.toString().trim() ?? '';
    final firstNameFromApi = json['first_name']?.toString().trim();
    final lastNameFromApi = json['last_name']?.toString().trim();
    final fullNameParts = fullName.isEmpty ? <String>[] : fullName.split(' ');

    final derivedFirstName = firstNameFromApi ??
        (fullNameParts.isNotEmpty ? fullNameParts.first : '');
    final derivedLastName = lastNameFromApi ??
        (fullNameParts.length > 1 ? fullNameParts.sublist(1).join(' ') : '');

    return UserModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      firstName: derivedFirstName,
      lastName: derivedLastName,
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? '',
      preferredLocationId: json['preferred_location_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String get fullName => '$firstName $lastName'.trim();
}

@JsonSerializable()
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String token;
  final String password;

  const ResetPasswordRequest({required this.token, required this.password});

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}
