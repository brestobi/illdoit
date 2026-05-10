import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';
import 'transaction_repository_impl.dart';

class OrderRepositoryImpl implements OrderRepository {
  final SupabaseService _supabaseService;
  final Ref _ref;

  OrderRepositoryImpl(this._supabaseService, this._ref);

  @override
  Future<Order> createOrder({
    required String serviceId,
    required String sellerId,
    required double amount,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      // 1. Create the order
      final response = await _supabaseService.insert(
        table: 'orders',
        data: {
          'buyer_id': currentUser.id,
          'seller_id': sellerId,
          'service_id': serviceId,
          'amount': amount,
          'status': 'pending',
        },
      );
      final order = Order.fromJson(response);

      // 2. Create escrow transaction
      await _ref.read(transactionRepositoryProvider).createEscrowPayment(
        amount: amount,
        receiverId: sellerId,
        orderId: order.id,
      );

      return order;
    } catch (e) {
      throw ServerException('Failed to create order: $e');
    }
  }

  @override
  Future<Order> getOrderById({required String orderId}) async {
    try {
      final response = await _supabaseService.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      return Order.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      throw ServerException('Failed to fetch order: $e');
    }
  }

  @override
  Future<List<Order>> getMyPurchases() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.client
          .from('orders')
          .select()
          .eq('buyer_id', currentUser.id)
          .order('created_at', ascending: false);
      
      return (results as List).map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch purchases: $e');
    }
  }

  @override
  Future<List<Order>> getMySales() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.client
          .from('orders')
          .select()
          .eq('seller_id', currentUser.id)
          .order('created_at', ascending: false);
      
      return (results as List).map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch sales: $e');
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await _supabaseService.client
          .from('orders')
          .update({'status': status.name, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      // Handle escrow release/refund
      if (status == OrderStatus.completed) {
        await _ref.read(transactionRepositoryProvider).releaseEscrow(orderId: orderId);
      } else if (status == OrderStatus.cancelled) {
        await _ref.read(transactionRepositoryProvider).refundEscrow(orderId: orderId);
      }
    } catch (e) {
      throw ServerException('Failed to update order status: $e');
    }
  }

  @override
  Future<void> raiseDispute({
    required String orderId,
    required String reason,
    required String description,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      // 1. Create the dispute entry
      await _supabaseService.insert(
        table: 'disputes',
        data: {
          'order_id': orderId,
          'raised_by': currentUser.id,
          'reason': reason,
          'description': description,
          'status': 'open',
        },
      );

      // 2. Update order status to 'disputed'
      await updateOrderStatus(orderId: orderId, status: OrderStatus.disputed);
    } catch (e) {
      throw ServerException('Failed to raise dispute: $e');
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return OrderRepositoryImpl(supabaseService, ref);
});
