import 'package:flutter/material.dart';
import 'package:good_bad_board/model/Player.dart';

class PlayerView extends StatelessWidget {
  final Player data;

  const PlayerView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {},
      child: SizedBox(
        width: 200,
        child: Text(
          '${data.name} (${data.elo.name.toUpperCase()})',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
