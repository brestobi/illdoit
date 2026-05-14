import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return SkillRepository(ref.watch(supabaseServiceProvider));
});

class SkillRepository {
  final SupabaseService _supabase;

  SkillRepository(this._supabase);

  Future<List<String>> getSkills() async {
    final response = await _supabase.query(
      table: 'skills',
      filters: {'is_active': true},
    );
    return response.map((e) => e['name'] as String).toList()..sort();
  }
}

final skillsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(skillRepositoryProvider).getSkills();
});
