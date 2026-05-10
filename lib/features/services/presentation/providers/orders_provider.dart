import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/order.dart';
import '../../../../core/repositories/abstract_repositories.dart';
import '../../../../core/repositories/order_repository_impl.dart';

/// Provider for user's purchases
final myPurchasesProvider = FutureProvider<List<Order>>((ref) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getMyPurchases();
});

/// Provider for user's sales
final mySalesProvider = FutureProvider<List<Order>>((ref) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getMySales();
});

/// Notifier for order actions
class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _orderRepository;

  OrderNotifier(this._orderRepository) : super(const AsyncValue.data(null));

  Future<void> createOrder({
    required String serviceId,
    required String sellerId,
    required double amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _orderRepository.createOrder(
        serviceId: serviceId,
        sellerId: sellerId,
        amount: amount,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<void>>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(orderRepository);
});
