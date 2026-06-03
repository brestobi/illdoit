import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// Notifier for current user profile data
class ProfileNotifier extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final userRepository = ref.watch(userRepositoryProvider);
    try {
      return await userRepository.getCurrentUserProfile();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    List<String>? skills,
    bool? isProfilePublic,
    bool? showLastSeen,
    bool? showContactInfo,
  }) async {
    final userRepository = ref.read(userRepositoryProvider);
    final updates = <String, dynamic>{};
    
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;
    if (skills != null) updates['skills'] = skills;
    if (isProfilePublic != null) updates['is_profile_public'] = isProfilePublic;
    if (showLastSeen != null) updates['show_last_seen'] = showLastSeen;
    if (showContactInfo != null) updates['show_contact_info'] = showContactInfo;

    if (updates.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await userRepository.updateUserProfile(data: updates);
      return userRepository.getCurrentUserProfile();
    });
  }
}

final profileProvider = AsyncNotifierProvider.autoDispose<ProfileNotifier, User?>(ProfileNotifier.new);

/// Provider for any user profile data by ID
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(userId: userId);
});
