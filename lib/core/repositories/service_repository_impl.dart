import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of ServiceRepository using Supabase
class ServiceRepositoryImpl implements ServiceRepository {
  final SupabaseService _supabaseService;

  ServiceRepositoryImpl(this._supabaseService);

  @override
  Future<Service> createService({required Map<String, dynamic> data}) async {
    try {
      final response = await _supabaseService.insert(
        table: 'services',
        data: data,
      );
      return Service.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create service: $e');
    }
  }

  @override
  Future<String> uploadServiceImage({required List<int> bytes}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser.id}/$fileName';
      
      return await _supabaseService.uploadFile(
        bucket: 'service-images',
        path: path,
        bytes: bytes,
      );
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to upload service image: $e');
    }
  }

  @override
  Future<List<Service>> getServices({String? category, String? sortBy}) async {
    try {
      final filters = category != null ? {'category': category} : null;
      final results = await _supabaseService.query(
        table: 'services',
        filters: filters,
      );
      return results.map((e) => Service.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch services: $e');
    }
  }

  @override
  Future<Service> getServiceById({required String serviceId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'services',
        filters: {'id': serviceId},
      );

      if (results.isEmpty) {
        throw ServerException('Service not found');
      }

      print('Service data from Supabase: ${results.first}');
      return Service.fromJson(results.first);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch service: $e');
    }
  }

  @override
  Future<void> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabaseService.update(
        table: 'services',
        id: serviceId,
        data: data,
      );
    } catch (e) {
      throw ServerException('Failed to update service: $e');
    }
  }

  @override
  Future<void> deleteService({required String serviceId}) async {
    try {
      await _supabaseService.delete(
        table: 'services',
        id: serviceId,
      );
    } catch (e) {
      throw ServerException('Failed to delete service: $e');
    }
  }

  @override
  Future<List<Service>> searchServices({
    required String query,
    String? category,
    String? location,
  }) async {
    try {
      final filters = category != null ? {'category': category} : null;
      
      final results = await _supabaseService.query(
        table: 'services',
        filters: filters,
        searchFilters: {'title': query},
      );
      
      return results.map((e) => Service.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Search failed: $e');
    }
  }

  @override
  Future<List<Service>> getMyServices() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final results = await _supabaseService.query(
        table: 'services',
        filters: {'user_id': currentUser.id},
      );
      return results.map((e) => Service.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch your services: $e');
    }
  }
}

/// Provider for ServiceRepository
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ServiceRepositoryImpl(supabaseService);
});
