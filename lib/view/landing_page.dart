import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/reusable.dart';
import 'package:good_bad_board/view/game_maker_page.dart';
import 'package:good_bad_board/view/sign_in_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Center(
        child: Padding(
          padding: pageSpacing,
          child: Row(
            spacing: spaceCard,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                    );
                  },
                  child: const LandingPageOption(label: 'Player Sign In'),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameMakerPage(),
                        ),
                      ),
                  child: const LandingPageOption(label: 'Make Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingPageOption extends StatelessWidget {
  final Widget? child;
  final String label;

  const LandingPageOption({super.key, this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card.filled(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
      ),
    );
  }
}
