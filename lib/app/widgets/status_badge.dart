import 'package:flutter/material.dart';
import '../theme/cicada_colors.dart';

enum StatusType { online, offline, warning, loading }

class StatusBadge extends StatefulWidget {
  const StatusBadge({
    super.key,
    required this.type,
    required this.label,
    this.size = 10,
  });

  final StatusType type;
  final String label;
  final double size;

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  bool get _shouldAnimate =>
      widget.type == StatusType.online || widget.type == StatusType.loading;

  Color get _color => switch (widget.type) {
        StatusType.online => CicadaColors.ok,
        StatusType.offline => CicadaColors.alert,
        StatusType.warning => CicadaColors.accent,
        StatusType.loading => CicadaColors.energy,
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_shouldAnimate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _shouldAnimate
            ? AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: _pulse.value * 0.8),
                        blurRadius: 8 + _pulse.value * 6,
                        spreadRadius: _pulse.value * 2,
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
