import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String role;
  final String? preferredLocationId;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.role,
    this.preferredLocationId,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory UserEntity.fromModel(UserModel model) => UserEntity(
        id: model.id,
        email: model.email,
        firstName: model.firstName,
        lastName: model.lastName,
        avatar: model.avatar,
        role: model.role,
        preferredLocationId: model.preferredLocationId,
      );

  @override
  List<Object?> get props =>
      [id, email, firstName, lastName, avatar, role, preferredLocationId];
}
