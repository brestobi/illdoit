import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    required String title,
    required String description,
    required String category,
    required double budget,
    required DateTime deadline,
    @Default('open') String status,
    @Default([]) List<String> images,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
