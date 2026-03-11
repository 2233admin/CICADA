import 'package:flutter/material.dart';

/// Subtle animated scan line overlay for tactical HUD feel.
/// Only use on hero/dashboard area, not globally.
class ScanLineOverlay extends StatefulWidget {
  const ScanLineOverlay({super.key, this.child});
  final Widget? child;

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ScanLinePainter(progress: _controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF55D0FF).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) => progress != old.progress;
}
