import 'dart:math';

import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/game_maker_page.dart';
import 'package:good_bad_board/view/sign_in_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final children = [
      LandingPageOption(
        label: 'Register',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
            ),
      ),
      LandingPageOption(
        label: 'Make Game',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameMakerPage()),
            ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      drawer: const LandingPageDrawer(),
      body: Center(
        child: GridView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            horizontal: spacePageX,
            vertical: spacePageY,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: sqrt(children.length).ceil(),
            mainAxisSpacing: spaceCard,
            crossAxisSpacing: spaceCard,
            mainAxisExtent: 450,
          ),
          children: children,
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
    return AspectRatio(
      aspectRatio: 1,
      child: Button(
        type: ButtonType.filled,
        textStyle: Theme.of(context).textTheme.displayMedium,
        onPressed: onTap,
        child: Center(child: Text(label, textAlign: TextAlign.center)),
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
