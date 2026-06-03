import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final skillRepositoryProvider = Provider<SkillRepository>((ref) => SkillRepository(ref.watch(supabaseServiceProvider)));

class SkillRepository {

  SkillRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<String>> getSkills() async {
    final response = await _supabase.query(
      table: 'skills',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList()..sort();
  }
}

final skillsProvider = FutureProvider<List<String>>((ref) async => ref.watch(skillRepositoryProvider).getSkills());
