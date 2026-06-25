import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/models/withdrawal_request.dart';
import '../../../../core/repositories/transaction_repository_impl.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/pin_service.dart';
import '../../../../core/widgets/walking_worker_loader.dart';
import '../providers/wallet_provider.dart';
import '../providers/pin_provider.dart';
import 'pin_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _pinGuardPassed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPin());
  }

  Future<void> _checkPin() async {
    if (_pinGuardPassed) return;

    await ref.read(pinProvider.notifier).checkPinStatus();
    if (!mounted) return;

    final pinStatus = ref.read(pinProvider);
    if (pinStatus == PinStatus.unlocked) {
      setState(() => _pinGuardPassed = true);
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      setState(() => _pinGuardPassed = true);
    } else if (mounted) {
      // User cancelled — go back
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_pinGuardPassed) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: const Center(child: WalkingWorkerLoader(size: 40)),
      );
    }
    return _buildWalletContent(context, ref);
  }

  Widget _buildWalletContent(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final escrowAsync = ref.watch(escrowBalanceProvider);
    final historyAsync = ref.watch(transactionHistoryProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final currentUserId = ref.watch(supabaseServiceProvider).currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Wallet'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(escrowBalanceProvider);
          ref.invalidate(transactionHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(fontSize: 14, color: AppColors.darkBg, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    balanceAsync.when(
                      data: (balance) => Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.darkBg),
                      ),
                      loading: () => const SizedBox(
                        height: 44,
                        child: Center(child: WalkingWorkerLoader(size: 30, color: AppColors.darkBg)),
                      ),
                      error: (err, _) => const Text('R 0.00', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.darkBg)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showWithdrawDialog(context),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBg),
                            child: const Text('Withdraw', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showDepositDialog(context),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBg),
                            child: const Text('Cash In', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Transaction History', style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              historyAsync.when(
                data: (history) => history.isEmpty
                    ? const Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final tx = history[index];
                          return Card(
                            color: AppColors.surface,
                            child: ListTile(
                              title: Text(tx.type, style: const TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text(DateFormat('yyyy-MM-dd').format(tx.createdAt), style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: Text(
                                (tx.type == 'withdrawal' ? '-' : '+') + currencyFormat.format(tx.amount),
                                style: TextStyle(color: tx.type == 'withdrawal' ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: WalkingWorkerLoader(size: 30)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDepositDialog(BuildContext context) async {
    final controller = TextEditingController();
    final paymentService = ref.read(paymentServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cash In', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (R)', prefixText: 'R ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(controller.text) ?? 0.0;
    if (amount < 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum deposit is R 10.'))); return; }
    try {
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final reference = 'DEPOSIT-$paymentId';
      final checkoutUrl = await paymentService.createCheckoutSession(amount: amount, reference: reference);
      
      // Create the pending transaction BEFORE opening the payment page.
      await ref.read(transactionRepositoryProvider).depositFunds(
        amount: amount,
        reference: reference,
        paymentId: paymentId,
      );
      
      ref.invalidate(balanceProvider);
      ref.invalidate(transactionHistoryProvider);
      
      debugPrint('Navigating to Yoco payment: $checkoutUrl');
      
      final success = await context.push<bool>(
          AppRoutes.yocoPayment, 
          extra: {'checkoutUrl': checkoutUrl, 'callbackUrl': 'https://illdoit.space/payment-success'},
      );
      debugPrint('Yoco payment returned: $success');
      
      if (success == true) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment submitted. Confirming with Yoco...')),
          );
          final verified = await paymentService.verifyPayment(paymentId);
          if (!context.mounted) return;
          ref.invalidate(balanceProvider);
          ref.invalidate(transactionHistoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verified ? 'Deposit confirmed!' : 'Payment processing. It may take a few minutes to appear in your balance.')),
          );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showWithdrawDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    final accController = TextEditingController();
    final branchController = TextEditingController();
    String selectedBank = 'Absa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Withdrawal Request', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (R)', prefixText: 'R ')),
              DropdownButtonFormField<String>(
                value: selectedBank,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Bank'),
                items: ['Absa', 'Capitec', 'FNB', 'Nedbank', 'Standard Bank', 'TymeBank', 'Discovery Bank'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBank = val!,
              ),
              TextField(controller: accController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account Number')),
              TextField(controller: branchController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Branch Code')),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Account Holder Name')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit Request')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount < 50) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is R 50.'))); return; }
    try {
      await ref.read(transactionRepositoryProvider).requestWithdrawal(amount: amount, bankName: selectedBank, accountHolder: nameController.text.trim(), accountNumber: accController.text.trim(), branchCode: branchController.text.trim(), accountType: 'Savings');
      if (!context.mounted) return;
      ref.invalidate(balanceProvider);
      ref.invalidate(transactionHistoryProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
