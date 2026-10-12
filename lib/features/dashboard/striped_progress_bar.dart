import 'package:flutter/material.dart';

/// A pill-shaped progress bar whose filled part is striped.
///
/// Used for the pre-made next round (RND-05), so it reads differently from the
/// solid bar of the round being played.
class StripedProgressBar extends StatelessWidget {
  const StripedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 8,
  });

  /// Filled share of the bar, from 0.0 to 1.0.
  final double value;

  /// Colour of the stripes.
  final Color color;

  /// Colour of the unfilled track.
  final Color backgroundColor;

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _StripedBarPainter(
          value: value.clamp(0.0, 1.0),
          color: color,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _StripedBarPainter extends CustomPainter {
  _StripedBarPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  /// Width of one stripe, measured along the bar.
  static const double _stripeWidth = 6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final filledWidth = size.width * value;
    if (filledWidth <= 0) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, filledWidth, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, filledWidth, size.height),
      Paint()..color = color.withValues(alpha: 0.55),
    );
    // Slanted stripes: a parallelogram every two stripe widths.
    final stripe = Paint()..color = color;
    for (var x = -size.height; x < filledWidth; x += _stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + _stripeWidth, size.height)
        ..lineTo(x + _stripeWidth + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripedBarPainter old) =>
      old.value != value ||
      old.color != color ||
      old.backgroundColor != backgroundColor;
}
