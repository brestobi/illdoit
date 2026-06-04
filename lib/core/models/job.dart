import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const Job._(); // Required for getters

  const factory Job({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    @JsonKey(name: 'job_type') @Default('digital') String jobType,
    required String title,
    required String description,
    required String category,
    @Default([]) List<String> tags,
    @JsonKey(name: 'location_id') String? locationId,
    String? location,
    required double budget,
    required DateTime deadline,
    @Default('open') String status,
    @Default([]) List<String> images,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    double? latitude,
    double? longitude,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  bool get isExpired => DateTime.now().isAfter(deadline);
  bool get isUrgent => status == 'open' && deadline.difference(DateTime.now()).inDays < 2;
  String get formattedBudget => 'R${budget.toStringAsFixed(0)}';
}
