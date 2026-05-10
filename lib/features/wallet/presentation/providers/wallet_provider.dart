import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/models/withdrawal_request.dart';
import '../../../../core/repositories/transaction_repository_impl.dart';

/// Provider for wallet balance
final balanceProvider = FutureProvider<double>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getWalletBalance();
});

/// Provider for escrow balance
final escrowBalanceProvider = FutureProvider<double>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getEscrowBalance();
});

/// Provider for total earned amount
final totalEarnedProvider = FutureProvider<double>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getTotalEarned();
});

/// Provider for transaction history
final transactionHistoryProvider = FutureProvider<List<Transaction>>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getTransactionHistory();
});

/// Provider for withdrawal requests
final withdrawalRequestsProvider = FutureProvider<List<WithdrawalRequest>>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getMyWithdrawalRequests();
});
