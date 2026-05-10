import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// Provider for current user profile data
final profileProvider = FutureProvider<User>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getCurrentUserProfile();
});

/// Provider for any user profile data by ID
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(userId: userId);
});
