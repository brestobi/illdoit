import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispute.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  final SupabaseService _supabaseService;

  DisputeRepositoryImpl(this._supabaseService);

  @override
  Future<Dispute?> getDisputeByOrderId({required String orderId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'disputes',
        filters: {'order_id': orderId},
      );

      if (results.isEmpty) return null;
      return Dispute.fromJson(results.first);
    } catch (e) {
      throw ServerException('Failed to fetch dispute: $e');
    }
  }

  @override
  Future<List<Dispute>> getMyDisputes() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.query(
        table: 'disputes',
        filters: {'raised_by': currentUser.id},
      );

      return results.map((e) => Dispute.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch my disputes: $e');
    }
  }

  @override
  Future<void> cancelDispute({required String disputeId}) async {
    try {
      await _supabaseService.update(
        table: 'disputes',
        id: disputeId,
        data: {
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ServerException('Failed to cancel dispute: $e');
    }
  }
}

final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return DisputeRepositoryImpl(supabaseService);
});
