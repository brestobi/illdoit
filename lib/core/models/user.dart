import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    String? email,
    String? phone,
    @JsonKey(name: 'display_name') required String displayName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? location,
    @JsonKey(name: 'user_type') @Default('viewer') String userType,
    @JsonKey(name: 'is_onboarding_completed') @Default(false) bool isOnboardingCompleted,
    @JsonKey(name: 'push_token') String? pushToken,
    @Default([]) List<String> skills,
    @Default(0.0) double rating,
    @JsonKey(name: 'completed_jobs') @Default(0) int completedJobs,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'verification_status') String? verificationStatus,
    @JsonKey(name: 'verification_metadata') Map<String, dynamic>? verificationMetadata,
    @Default(0.0) double balance,
    @JsonKey(name: 'escrow_balance') @Default(0.0) double escrowBalance,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
