import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/court_grid_layout.dart';

void main() {
  group('courtGridLayout', () {
    test('should_use_one_column_when_one_court_fits_best', () {
      final layout = courtGridLayout(width: 1000, height: 800, courtCount: 1);

      expect(layout.columns, 1);
    });

    test('should_pick_the_column_count_with_the_largest_court_that_fits', () {
      // 2 columns x 2 rows: 492 wide, needs 308 high per row, 2 rows fit.
      final layout = courtGridLayout(width: 1000, height: 700, courtCount: 4);

      expect(layout.columns, 2);
    });

    test('should_fill_the_height_when_the_courts_fit', () {
      final layout = courtGridLayout(
        width: 1000,
        height: 700,
        courtCount: 4,
        gap: 16,
      );

      expect(layout.courtHeight * 2 + 16, closeTo(700, 0.01));
    });

    test('should_not_make_a_court_taller_than_it_is_wide', () {
      final layout = courtGridLayout(width: 400, height: 2000, courtCount: 1);

      expect(layout.courtHeight, 400);
    });

    test('should_scroll_when_the_courts_cannot_fit', () {
      final layout = courtGridLayout(width: 1000, height: 300, courtCount: 8);

      expect(layout.scrolls, isTrue);
    });

    test('should_use_the_most_columns_when_the_courts_cannot_fit', () {
      // Minimum court width 320 + gap 16: 3 columns in 1000.
      final layout = courtGridLayout(width: 1000, height: 300, courtCount: 8);

      expect(layout.columns, 3);
    });

    test('should_keep_the_minimum_proportion_when_scrolling', () {
      final layout = courtGridLayout(width: 1000, height: 300, courtCount: 8);

      const courtWidth = (1000 - 16 * 2) / 3;
      expect(layout.courtHeight, closeTo(courtWidth / 1.6, 0.01));
    });

    test('should_use_one_column_on_a_narrow_screen', () {
      final layout = courtGridLayout(width: 350, height: 600, courtCount: 4);

      expect(layout.columns, 1);
    });

    test('should_cap_the_columns_at_maxColumnCount', () {
      final layout = courtGridLayout(
        width: 1000,
        height: 0,
        courtCount: 8,
        maxColumnCount: 2,
      );

      expect(layout.columns, 2);
    });
  });
}
