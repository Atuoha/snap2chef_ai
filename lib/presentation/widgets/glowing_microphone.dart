import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';

class GlowingMicButton extends StatefulWidget {
  final bool isListening;

  const GlowingMicButton({super.key, required this.isListening});

  @override
  State<GlowingMicButton> createState() => _GlowingMicButtonState();
}

class _GlowingMicButtonState extends State<GlowingMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.0, end: 25.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlowingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, // Enough space for the full glow
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isListening)
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                return Container(
                  width: 60 + _animation.value,
                  height: 60 + _animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withOpacity(0.15),
                  ),
                );
              },
            ),
          CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            radius: 30,
            child: Icon(
              widget.isListening ? Iconsax.stop_circle : Iconsax.microphone,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}