import 'package:freezed_annotation/freezed_annotation.dart';

part 'dispute.freezed.dart';
part 'dispute.g.dart';

enum DisputeStatus {
  open,
  @JsonValue('under_review')
  underReview,
  resolved,
  cancelled
}

@freezed
class Dispute with _$Dispute {
  const factory Dispute({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'raised_by') required String raisedBy,
    required String reason,
    required String description,
    @Default(DisputeStatus.open) DisputeStatus status,
    @JsonKey(name: 'resolution_summary') String? resolutionSummary,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Dispute;

  factory Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);
}
