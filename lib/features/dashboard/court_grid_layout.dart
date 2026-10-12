import 'dart:math';

/// The column count and court size for the dashboard court grid.
class CourtGridLayout {
  const CourtGridLayout({
    required this.columns,
    required this.courtHeight,
    required this.scrolls,
  });

  final int columns;
  final double courtHeight;

  /// True when the courts cannot all fit in the given height, so the grid
  /// must scroll.
  final bool scrolls;
}

/// Finds the column count that gives the largest court that still fits in
/// [width] x [height] (same approach as the court grid on main).
///
/// A court is never narrower than [minCourtWidth] and never flatter than
/// [minAspectRatio] (width / height). When the courts fit, each row grows to
/// fill the height, but a court never becomes taller than it is wide. When
/// no column count fits, the grid uses the most columns at the minimum
/// proportion and scrolls.
CourtGridLayout courtGridLayout({
  required double width,
  required double height,
  required int courtCount,
  double gap = 16,
  double minCourtWidth = 320,
  double minAspectRatio = 1.6,
}) {
  final count = max(1, courtCount);
  final maxColumns = min(count, max(1, (width + gap) ~/ (minCourtWidth + gap)));

  double courtWidth(int columns) => (width - gap * (columns - 1)) / columns;

  CourtGridLayout? best;
  var bestArea = 0.0;
  for (var columns = 1; columns <= maxColumns; columns++) {
    final rows = (count / columns).ceil();
    final w = courtWidth(columns);
    final rowHeight = (height - gap * (rows - 1)) / rows;
    if (rowHeight < w / minAspectRatio) continue;
    final h = min(rowHeight, w);
    if (w * h > bestArea) {
      bestArea = w * h;
      best = CourtGridLayout(columns: columns, courtHeight: h, scrolls: false);
    }
  }

  return best ??
      CourtGridLayout(
        columns: maxColumns,
        courtHeight: courtWidth(maxColumns) / minAspectRatio,
        scrolls: true,
      );
}
