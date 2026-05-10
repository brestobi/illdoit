import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/order.dart';
import '../../../../core/repositories/order_repository_impl.dart';
import '../../../../core/services/invoice_service.dart';
import '../providers/orders_provider.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Sales'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(provider: myPurchasesProvider, isBuyer: true),
          _OrdersList(provider: mySalesProvider, isBuyer: false),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final FutureProvider<List<Order>> provider;
  final bool isBuyer;

  const _OrdersList({
    Key? key,
    required this.provider,
    required this.isBuyer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(provider);

    return ordersAsync.when(
      data: (orders) => orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderTile(order: order, isBuyer: isBuyer);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final Order order;
  final bool isBuyer;

  const _OrderTile({
    Key? key,
    required this.order,
    required this.isBuyer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isBuyer ? 'Purchased Service' : 'Sale of Service',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount: R${order.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (!isBuyer && order.status == OrderStatus.pending)
                ElevatedButton(
                  onPressed: () {
                    ref.read(orderNotifierProvider.notifier).updateStatus(
                          orderId: order.id,
                          status: OrderStatus.accepted,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Accept'),
                ),
              if (isBuyer && order.status == OrderStatus.accepted)
                ElevatedButton(
                  onPressed: () {
                    ref.read(orderNotifierProvider.notifier).updateStatus(
                          orderId: order.id,
                          status: OrderStatus.completed,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Complete'),
                ),
              if (order.status == OrderStatus.completed)
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(invoiceServiceProvider).generateAndDownloadInvoice(order);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Invoice'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              if (order.status != OrderStatus.pending && order.status != OrderStatus.disputed)
                TextButton(
                  onPressed: () => _showDisputeDialog(context, ref, order),
                  child: const Text('Dispute', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDisputeDialog(BuildContext context, WidgetRef ref, Order order) async {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Raise a Dispute', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Reason (e.g., Service not delivered)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Detailed Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Raise Dispute'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(orderRepositoryProvider).raiseDispute(
          orderId: order.id,
          reason: reasonController.text.trim(),
          description: descController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised successfully.')));
          ref.invalidate(myPurchasesProvider);
          ref.invalidate(mySalesProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        break;
      case OrderStatus.inProgress:
        color = Colors.purple;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      case OrderStatus.disputed:
        color = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
