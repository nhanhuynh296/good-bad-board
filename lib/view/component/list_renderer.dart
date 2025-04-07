import 'package:flutter/widgets.dart';
import 'package:good_bad_board/spacing.dart';

class ListRenderer<T> extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final double separatorExtent;
  final List<T> items;

  const ListRenderer({
    super.key,
    required this.itemBuilder,
    required this.items,
    this.separatorExtent = spaceDefault,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(
        vertical: spaceDefault,
        horizontal: spacePageX,
      ),
      itemBuilder: itemBuilder,
      separatorBuilder:
          (BuildContext context, int index) =>
              SizedBox(height: separatorExtent),
    );
  }
}
