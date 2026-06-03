import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository(ref.watch(supabaseServiceProvider)));

class CategoryRepository {

  CategoryRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<JobCategory>> getCategories() async {
    final response = await _supabase.query(
      table: 'categories',
      filters: {'is_active': true},
    );
    return response.map(JobCategory.fromJson).toList();
  }
}

final allCategoriesProvider = FutureProvider<List<JobCategory>>((ref) async => ref.watch(categoryRepositoryProvider).getCategories());

final digitalCategoriesProvider = FutureProvider<List<JobCategory>>((ref) async {
  final all = await ref.watch(allCategoriesProvider.future);
  return all.where((c) => c.type == 'digital' || c.type == 'both').toList();
});

final physicalCategoriesProvider = FutureProvider<List<JobCategory>>((ref) async {
  final all = await ref.watch(allCategoriesProvider.future);
  return all.where((c) => c.type == 'physical' || c.type == 'both').toList();
});
