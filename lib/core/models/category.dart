import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class JobCategory with _$JobCategory {
  const factory JobCategory({
    required String id,
    required String name,
    required String type,
    String? icon,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _JobCategory;

  factory JobCategory.fromJson(Map<String, dynamic> json) => _$JobCategoryFromJson(json);
}
