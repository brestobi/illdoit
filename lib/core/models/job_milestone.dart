import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_milestone.freezed.dart';
part 'job_milestone.g.dart';

@freezed
class JobMilestone with _$JobMilestone {
  const factory JobMilestone({
    required String id,
    required String jobId,
    required String title,
    String? description,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _JobMilestone;

  factory JobMilestone.fromJson(Map<String, dynamic> json) => _$JobMilestoneFromJson(json);
}
