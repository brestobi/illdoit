import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) => AppConfigRepository(ref.watch(supabaseServiceProvider)));

class AppConfigRepository {

  AppConfigRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<String>> getIdTypes() async {
    final response = await _supabase.query(
      table: 'id_types',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList();
  }

  Future<List<String>> getSupportedBanks() async {
    final response = await _supabase.query(
      table: 'supported_banks',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList()..sort();
  }

  Future<List<String>> getReportReasons() async {
    final response = await _supabase.query(
      table: 'report_reasons',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList();
  }

  Future<List<String>> getDisputeReasons() async {
    final response = await _supabase.query(
      table: 'dispute_reasons',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList();
  }
}

final idTypesProvider = FutureProvider<List<String>>((ref) async => ref.watch(appConfigRepositoryProvider).getIdTypes());

final supportedBanksProvider = FutureProvider<List<String>>((ref) async => ref.watch(appConfigRepositoryProvider).getSupportedBanks());

final reportReasonsProvider = FutureProvider<List<String>>((ref) async => ref.watch(appConfigRepositoryProvider).getReportReasons());

final disputeReasonsProvider = FutureProvider<List<String>>((ref) async => ref.watch(appConfigRepositoryProvider).getDisputeReasons());
