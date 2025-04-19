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
      drawer: const LandingPageDrawer(),
      body: Center(
        child: Padding(
          padding: pageSpacing,
          child: Row(
            spacing: spaceCard,
            children: [
              Expanded(
                child: LandingPageOption(
                  label: 'Player Sign In',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      ),
                ),
              ),
              Expanded(
                child: LandingPageOption(
                  label: 'Make Game',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameMakerPage(),
                        ),
                      ),
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
  final VoidCallback? onTap;

  const LandingPageOption({
    super.key,
    this.child,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Card.filled(
          color: Theme.of(context).colorScheme.primary,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingPageDrawer extends StatelessWidget {
  const LandingPageDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final width = MediaQuery.sizeOf(context).width * 0.5;
    return Drawer(
      width: width,
      child: Column(
        children: [
          AboutListTile(
            applicationName: appName,
            aboutBoxChildren: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'https://github.com/nhanhuynh296',
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
