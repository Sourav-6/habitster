import 'package:flutter/material.dart';

class FluidButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double width;
  final double height;
  final Color color;

  const FluidButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width = double.infinity,
    this.height = 56.0,
    this.color = const Color(0xFFFF0066),
  });

  @override
  State<FluidButton> createState() => _FluidButtonState();
}

class _FluidButtonState extends State<FluidButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
        reverseCurve: Curves.elasticOut,
      ),
    );

    _radiusAnimation = Tween<double>(begin: 28.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : _onTapDown,
      onTapUp: isDisabled ? null : _onTapUp,
      onTapCancel: isDisabled ? null : _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: isDisabled ? widget.color.withOpacity(0.5) : widget.color,
                borderRadius: BorderRadius.circular(_radiusAnimation.value),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4 * _scaleAnimation.value),
                          blurRadius: 15 * _scaleAnimation.value,
                          spreadRadius: 2,
                          offset: Offset(0, 5 * _scaleAnimation.value),
                        ),
                      ],
              ),
              child: Center(
                child: Opacity(
                  opacity: isDisabled ? 0.7 : 1.0,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
