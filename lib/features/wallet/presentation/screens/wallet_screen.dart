import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/repositories/transaction_repository_impl.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/payment_service.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    balanceAsync.when(
                      data: (balance) => Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBg,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 44,
                        child: Center(child: CircularProgressIndicator(color: AppColors.darkBg)),
                      ),
                      error: (err, _) => const Text('R 0.00', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.darkBg)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showWithdrawDialog(context, ref),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBg),
                            child: const Text('Withdraw', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showDepositDialog(context, ref),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBg),
                            child: const Text('Add Funds', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox('Pending', 'R 0.00'), // Placeholder for future use
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: escrowAsync.when(
                      data: (escrow) => _buildStatBox('In Escrow', currencyFormat.format(escrow)),
                      loading: () => _buildStatBox('In Escrow', '...'),
                      error: (_, __) => _buildStatBox('In Escrow', 'R 0.00'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transaction History
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              historyAsync.when(
                data: (transactions) => transactions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No transactions yet.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(transactions[index], currentUserId);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx, String? currentUserId) {
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final dateStr = DateFormat('MMM dd, yyyy').format(tx.createdAt);
    final isIncoming = tx.type == 'deposit' || (tx.type == 'payment' && tx.receiverId == currentUserId) || (tx.type == 'escrow_release' && tx.receiverId == currentUserId);

    IconData icon;
    if (tx.type == 'withdrawal') {
      icon = Icons.account_balance_wallet_outlined;
    } else if (tx.type == 'deposit') {
      icon = Icons.arrow_downward;
    } else if (tx.type == 'escrow') {
      icon = Icons.lock_outline;
    } else {
      icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tx.type == 'escrow' 
                ? AppColors.primary.withValues(alpha: 0.1)
                : isIncoming
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: tx.type == 'escrow' 
                ? AppColors.primary 
                : isIncoming ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.reference ?? 'Transaction',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            tx.type == 'escrow' 
              ? currencyFormat.format(tx.amount)
              : '${isIncoming ? '+' : '-'}${currencyFormat.format(tx.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tx.type == 'escrow' 
                ? AppColors.primary 
                : isIncoming ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDepositDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    String selectedGateway = 'Yoco';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Add Funds', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'R ',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  _buildGatewayTile('Yoco', 'Card / Instant EFT', selectedGateway, (val) => setState(() => selectedGateway = val!)),
                  _buildGatewayTile('Ozow', 'Instant EFT', selectedGateway, (val) => setState(() => selectedGateway = val!)),
                  _buildGatewayTile('PayFast', 'Card / EFT', selectedGateway, (val) => setState(() => selectedGateway = val!)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add Funds')),
              ],
            );
          }
        );
      },
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum deposit is R 10.')));
      return;
    }

    try {
      if (selectedGateway == 'Yoco') {
        // Show loading state or processing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecting to Yoco...'), duration: Duration(seconds: 2)),
        );

        final paymentService = ref.read(paymentServiceProvider);
        final paymentData = await paymentService.createYocoCheckout(
          amount: amount,
          currency: 'ZAR',
          reference: 'wallet_topup_${DateTime.now().millisecondsSinceEpoch}',
        );

        final checkoutUrl = paymentData['checkout_url'] as String;
        final paymentId = paymentData['payment_id'] as String;

        await paymentService.launchCheckout(checkoutUrl);

        // Polling for webhook confirmation
        final success = await paymentService.verifyPayment(paymentId);

        if (!context.mounted) return;

        if (success) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds added successfully via Yoco!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yoco payment could not be verified.')));
        }
      } else {
        // Fallback for other gateways (Ozow/PayFast)
        await ref.read(transactionRepositoryProvider).depositFunds(
          amount: amount,
          reference: 'Wallet top-up',
          gateway: selectedGateway,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds added successfully!')));
      }

      ref.invalidate(balanceProvider);
      ref.invalidate(transactionHistoryProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Widget _buildGatewayTile(String name, String sub, String selected, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      value: name,
      groupValue: selected,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _showWithdrawDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    final accController = TextEditingController();
    final branchController = TextEditingController();
    String selectedBank = 'Absa';
    String accType = 'Savings';

    final banks = ['Absa', 'Capitec', 'FNB', 'Nedbank', 'Standard Bank', 'TymeBank', 'Discovery Bank'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Withdrawal Request', style: TextStyle(color: AppColors.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Amount (R)', prefixText: 'R '),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBank,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Bank'),
                      items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) => setState(() => selectedBank = val!),
                    ),
                    TextField(
                      controller: accController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                    TextField(
                      controller: branchController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Branch Code'),
                    ),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Account Holder Name'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit Request')),
              ],
            );
          }
        );
      },
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is R 50.')));
      return;
    }

    try {
      await ref.read(transactionRepositoryProvider).requestWithdrawal(
        amount: amount,
        bankName: selectedBank,
        accountHolder: nameController.text.trim(),
        accountNumber: accController.text.trim(),
        branchCode: branchController.text.trim(),
        accountType: accType,
      );
      if (!context.mounted) return;
      ref.invalidate(balanceProvider);
      ref.invalidate(transactionHistoryProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted for review.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
