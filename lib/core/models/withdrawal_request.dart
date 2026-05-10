import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_request.freezed.dart';
part 'withdrawal_request.g.dart';

@freezed
class WithdrawalRequest with _$WithdrawalRequest {
  const factory WithdrawalRequest({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required double amount,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'account_holder') required String accountHolder,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'branch_code') required String branchCode,
    @JsonKey(name: 'account_type') required String accountType,
    @Default('pending') String status,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _WithdrawalRequest;

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) => _$WithdrawalRequestFromJson(json);
}
