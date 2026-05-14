import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@freezed
class AppLocation with _$Location {
  const factory AppLocation({
    required String id,
    required String name,
    required String province,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Location;

  factory AppLocation.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
}
