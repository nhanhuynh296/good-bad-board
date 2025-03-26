import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/view/game_maker_page.dart';
import 'package:good_bad_board/view/sign_in_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: gutter,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
            child: const Card.outlined(
              child: LandingPageOption(child: Text('Player Sign In')),
            ),
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameMakerPage(),
                  ),
                ),
            child: const Card(
              child: LandingPageOption(child: Text('Make Game')),
            ),
          ),
        ),
      ],
    );
  }
}

class LandingPageOption extends StatelessWidget {
  final Widget? child;

  const LandingPageOption({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: MediaQuery.of(context).size.shortestSide / 2.5,
      child: Center(child: child),
    );
  }
}
