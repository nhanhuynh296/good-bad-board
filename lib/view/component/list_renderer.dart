import 'package:flutter/widgets.dart';
import 'package:good_bad_board/spacing.dart';

class ListRenderer<T> extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final double separatorExtent;
  final List<T> items;
  final EdgeInsets? padding;

  const ListRenderer({
    super.key,
    required this.itemBuilder,
    required this.items,
    this.separatorExtent = spaceDefault,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final padding =
        this.padding ??
        const EdgeInsets.symmetric(
          vertical: spaceDefault,
          horizontal: spacePageX,
        );

    return ListView.separated(
      itemCount: items.length,
      padding: padding,
      itemBuilder: itemBuilder,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: separatorExtent),
    );
  }
}
