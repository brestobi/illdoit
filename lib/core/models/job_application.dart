import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_application.freezed.dart';
part 'job_application.g.dart';

enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  withdrawn
}

@freezed
class JobApplication with _$JobApplication {
  const factory JobApplication({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    @JsonKey(name: 'applicant_id') required String applicantId,
    @JsonKey(name: 'cover_letter') String? coverLetter,
    @JsonKey(name: 'bid_amount') double? bidAmount,
    @Default(ApplicationStatus.pending) ApplicationStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _JobApplication;

  factory JobApplication.fromJson(Map<String, dynamic> json) => _$JobApplicationFromJson(json);
}
