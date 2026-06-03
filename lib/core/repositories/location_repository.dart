import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../services/supabase_service.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository(ref.watch(supabaseServiceProvider)));

class LocationRepository {

  LocationRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<AppLocation>> getLocations() async {
    final response = await _supabase.query(
      table: 'locations',
      filters: {'is_active': true},
    );
    return response.map(AppLocation.fromJson).toList();
  }
}

final locationsProvider = FutureProvider<List<AppLocation>>((ref) async => ref.watch(locationRepositoryProvider).getLocations());

final provincesProvider = FutureProvider<List<String>>((ref) async {
  final locations = await ref.watch(locationsProvider.future);
  return locations.map((e) => e.province).toSet().toList()..sort();
});
