import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service.dart';
import '../../../../core/repositories/abstract_repositories.dart';
import '../../../../core/repositories/service_repository_impl.dart';

/// Provider for current user's services
final myServicesProvider = FutureProvider<List<Service>>((ref) async {
  final serviceRepository = ref.watch(serviceRepositoryProvider);
  return serviceRepository.getMyServices();
});

/// Provider for a single service by ID
final serviceProvider = FutureProvider.family<Service, String>((ref, id) async {
  final serviceRepository = ref.watch(serviceRepositoryProvider);
  return serviceRepository.getServiceById(serviceId: id);
});

/// State for Service operations
class ServiceState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  ServiceState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ServiceState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ServiceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for service operations
class ServiceNotifier extends StateNotifier<ServiceState> {
  final ServiceRepository _serviceRepository;
  final Ref _ref;

  ServiceNotifier(this._serviceRepository, this._ref) : super(ServiceState());

  Future<void> createService(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _serviceRepository.createService(data: data);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myServicesProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadImage(List<int> bytes) async {
    try {
      return await _serviceRepository.uploadServiceImage(bytes: bytes);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _serviceRepository.updateService(serviceId: id, data: data);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myServicesProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteService(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _serviceRepository.deleteService(serviceId: id);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myServicesProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void reset() {
    state = ServiceState();
  }
}

/// Provider for ServiceNotifier
final serviceNotifierProvider = StateNotifierProvider<ServiceNotifier, ServiceState>((ref) {
  final serviceRepository = ref.watch(serviceRepositoryProvider);
  return ServiceNotifier(serviceRepository, ref);
});
