import 'package:flutter/widgets.dart';
import 'package:good_bad_board/model/Player.dart';

class PlayerView extends StatelessWidget {
  final Player data;

  const PlayerView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 100,
      child: Column(children: [Text(data.name), Text(data.elo.name)]),
    );
  }
}
