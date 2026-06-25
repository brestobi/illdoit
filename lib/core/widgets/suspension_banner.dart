import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// A global banner that displays when the user's account is suspended or banned.
///
/// This widget should be placed at the top of the widget stack in main.dart's
/// builder, overlaying all routes. It watches the authProvider for changes
/// to the [AuthState.suspensionMessage] and shows a dismissible banner.
class SuspensionBanner extends ConsumerStatefulWidget {
  const SuspensionBanner({super.key});

  @override
  ConsumerState<SuspensionBanner> createState() => _SuspensionBannerState();
}

class _SuspensionBannerState extends ConsumerState<SuspensionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _show() {
    _isDismissed = false;
    _animationController.forward();
  }

  void _hide() {
    _isDismissed = true;
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final suspensionMessage = authState.suspensionMessage;

    final shouldShow = suspensionMessage != null && !_isDismissed;

    if (shouldShow && _animationController.isDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }

    if (!shouldShow && _animationController.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hide());
    }

    final isBanned = suspensionMessage?.toLowerCase().contains('banned') ?? false;

    return AnimatedBuilder(
      listenable: _animationController,
      builder: (context, child) {
        if (_animationController.isDismissed && !shouldShow) {
          return const SizedBox.shrink();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child!,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isBanned
                    ? [Colors.red.shade800, Colors.red.shade700]
                    : [Colors.amber.shade800, Colors.orange.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isBanned ? Colors.red : Colors.orange)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isBanned ? Icons.gpp_bad : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBanned ? 'Account Banned' : 'Account Suspended',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suspensionMessage ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).signOut();
                      _hide();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _hide,
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AnimatedBuilder that wraps AnimatedWidget with a builder pattern.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}
