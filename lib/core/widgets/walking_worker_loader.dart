import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WalkingWorkerLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? label;

  const WalkingWorkerLoader({
    super.key,
    this.size = 50,
    this.color,
    this.label,
  });

  @override
  State<WalkingWorkerLoader> createState() => _WalkingWorkerLoaderState();
}

class _WalkingWorkerLoaderState extends State<WalkingWorkerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _frameIndex = 0;

  // Terminal-style walking animation frames
  final List<String> _frames = [
    "  O  \n /|\\ \n / \\ ", // Standing/Mid-walk
    "  O  \n /|\\ \n  |\\ ", // Right leg forward
    "  O  \n /|\\ \n / \\ ", // Standing/Mid-walk
    "  O  \n /|\\ \n /|  ", // Left leg forward
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        final newFrame = (_controller.value * _frames.length).floor();
        if (newFrame != _frameIndex && newFrame < _frames.length) {
          setState(() {
            _frameIndex = newFrame;
          });
        }
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _frames[_frameIndex],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: widget.size / 2.5,
            color: widget.color ?? AppColors.primary,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
