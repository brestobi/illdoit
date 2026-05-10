import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus {
  pending,
  accepted,
  @JsonValue('in_progress')
  inProgress,
  completed,
  cancelled,
  disputed
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'buyer_id') required String buyerId,
    @JsonKey(name: 'seller_id') required String sellerId,
    @JsonKey(name: 'service_id') required String serviceId,
    required double amount,
    @Default(OrderStatus.pending) OrderStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
