import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/withdrawal_request.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of TransactionRepository using Supabase
class TransactionRepositoryImpl implements TransactionRepository {

  TransactionRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<List<Transaction>> getTransactionHistory() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      // Fetch where user is either sender or receiver directly in the query for performance and security
      final results = await _supabaseService.client
          .from('transactions')
          .select()
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
          .order('created_at', ascending: false);

      return (results as List).map((e) => Transaction.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch transaction history: $e');
    }
  }

  @override
  Future<double> getWalletBalance() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.query(
        table: 'users',
        select: 'balance',
        filters: {'id': currentUser.id},
      );
      
      if (results.isEmpty) throw ServerException('User profile not found');
      return (results.first['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw ServerException('Failed to fetch wallet balance: $e');
    }
  }

  @override
  Future<double> getEscrowBalance() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.query(
        table: 'users',
        select: 'escrow_balance',
        filters: {'id': currentUser.id},
      );
      
      if (results.isEmpty) throw ServerException('User profile not found');
      return (results.first['escrow_balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw ServerException('Failed to fetch escrow balance: $e');
    }
  }

  @override
  Future<double> getTotalEarned() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final transactions = await getTransactionHistory();
      double earned = 0;

      for (final tx in transactions) {
        if (tx.status == 'completed' && tx.receiverId == currentUser.id) {
          if (tx.type == 'payment' || tx.type == 'escrow_release' || tx.type == 'deposit') {
            earned += tx.amount;
          }
        }
      }
      return earned;
    } catch (e) {
      throw ServerException('Failed to calculate total earned: $e');
    }
  }

  @override
  Future<Transaction> depositFunds({
    required double amount,
    required String reference,
    required String paymentId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final response = await _supabaseService.insert(
        table: 'transactions',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': currentUser.id,
          'amount': amount,
          'type': 'deposit',
          'status': 'pending',
          'reference': 'Yoco: $reference',
          'payment_id': paymentId,
        },
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw ServerException('Deposit failed: $e');
    }
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branchCode,
    required String accountType,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    final balance = await getWalletBalance();
    if (amount > balance) throw InsufficientFundsException('Insufficient funds');

    try {
      await _supabaseService.insert(
        table: 'withdrawal_requests',
        data: {
          'user_id': currentUser.id,
          'amount': amount,
          'bank_name': bankName,
          'account_holder': accountHolder,
          'account_number': accountNumber,
          'branch_code': branchCode,
          'account_type': accountType,
          'status': 'pending',
        },
      );
      
      // Also record as a pending transaction to deduct from viewable balance
      await _supabaseService.insert(
        table: 'transactions',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': currentUser.id,
          'amount': amount,
          'type': 'withdrawal',
          'status': 'pending', // Mark as pending until admin approves
          'reference': 'Withdrawal to $bankName',
        },
      );
    } catch (e) {
      throw ServerException('Withdrawal request failed: $e');
    }
  }

  @override
  Future<Transaction> createEscrowPayment({
    required double amount,
    required String receiverId,
    required String orderId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final response = await _supabaseService.insert(
        table: 'transactions',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': receiverId,
          'amount': amount,
          'type': 'escrow',
          'status': 'pending',
          'order_id': orderId,
          'reference': 'Escrow for order $orderId',
        },
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw ServerException('Escrow creation failed: $e');
    }
  }

  @override
  Future<void> releaseEscrow({required String orderId}) async {
    try {
      // 1. Fetch order to get the fee
      final orderResults = await _supabaseService.query(
        table: 'orders',
        filters: {'id': orderId},
      );
      if (orderResults.isEmpty) throw ServerException('Order not found');
      final fee = (orderResults.first['fee'] as num?)?.toDouble() ?? 0.0;

      // 2. Find the escrow transaction
      final results = await _supabaseService.query(
        table: 'transactions',
        filters: {'order_id': orderId, 'type': 'escrow'},
      );

      if (results.isEmpty) throw ServerException('Escrow transaction not found');
      
      final txId = results.first['id'];

      // 3. Mark as completed and record the fee
      await _supabaseService.update(
        table: 'transactions',
        id: txId,
        data: {
          'status': 'completed', 
          'type': 'escrow_release',
          'fee': fee,
        },
      );
    } catch (e) {
      throw ServerException('Failed to release escrow: $e');
    }
  }

  @override
  Future<void> refundEscrow({required String orderId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'transactions',
        filters: {'order_id': orderId, 'type': 'escrow'},
      );

      if (results.isEmpty) throw ServerException('Escrow transaction not found');
      
      final txId = results.first['id'];

      // Mark as cancelled
      await _supabaseService.update(
        table: 'transactions',
        id: txId,
        data: {'status': 'cancelled'},
      );
    } catch (e) {
      throw ServerException('Failed to refund escrow: $e');
    }
  }

  @override
  Future<List<WithdrawalRequest>> getMyWithdrawalRequests() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.query(
        table: 'withdrawal_requests',
        filters: {'user_id': currentUser.id},
      );

      return results.map(WithdrawalRequest.fromJson).toList();
    } catch (e) {
      throw ServerException('Failed to fetch withdrawal requests: $e');
    }
  }

  @override
  Future<Transaction> processPayment({
    required double amount,
    required String receiverId,
    required String serviceId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final response = await _supabaseService.insert(
        table: 'transactions',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': receiverId,
          'amount': amount,
          'type': 'payment',
          'status': 'completed',
          'reference': 'Payment for service $serviceId',
        },
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw ServerException('Payment failed: $e');
    }
  }
}

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return TransactionRepositoryImpl(supabaseService);
});
