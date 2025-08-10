import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/setting.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final children = [
      LandingPageOption(
        label: AppLocalizations.of(context)!.playerRegister,
        onTap: () => context.go('/register'),
      ),
      LandingPageOption(
        label: AppLocalizations.of(context)!.makeGame,
        onTap: () => context.go('/game'),
      ),
      LandingPageOption(
        label: AppLocalizations.of(context)!.playerStatistic,
        onTap: () => context.go('/stats'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.app_name)),
      drawer: const LandingPageDrawer(),
      body: GridView(
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
    return Drawer(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingPage()));
            },
            trailing: Icon(Icons.adaptive.arrow_forward),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.about),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationVersion: "VERSION: $version",
                applicationName: appName,
                children: [
                  const ListTile(
                    title: Text("Author"),
                    subtitle: Text("NATHAN HUYNH"),
                  ),
                  const ListTile(
                    title: Text("Contact"),
                    subtitle: Text("nhanhuynh296@gmail.com"),
                  ),
                ],
              );
            },
            trailing: Icon(Icons.adaptive.arrow_forward),
          ),
        ],
      ),
    );
  }
}
