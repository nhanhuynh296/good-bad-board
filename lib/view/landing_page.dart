import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/reusable.dart';
import 'package:good_bad_board/view/component/setting.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final children = [
      LandingPageOption(
        label: Text(
          AppLocalizations.of(context)!.player_register,
          style: const TextStyle(color: AppColors.black),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.yellow,
        child: SvgPicture.asset("asset/image/landing-player.svg"),
        onTap: () => context.go('/register'),
      ),
      LandingPageOption(
        label: Text(
          AppLocalizations.of(context)!.make_game,
          style: const TextStyle(color: AppColors.white),
          textAlign: TextAlign.center,
        ),
        onTap: () => context.go('/game'),
        backgroundColor: AppColors.orange,
        child: SvgPicture.asset("asset/image/landing-make-game.svg"),
      ),
      const SizedBox.shrink(),
      LandingPageOption(
        label: Text(
          AppLocalizations.of(context)!.player_statistic,
          style: const TextStyle(color: AppColors.teal),
          textAlign: TextAlign.center,
        ),
        child: SvgPicture.asset("asset/image/landing-statistic.svg"),
        onTap: () => context.go('/stats'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.app_name)),
      drawer: const LandingPageDrawer(),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 64,
          vertical: pageSpacing.vertical,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Let's play Badminton!",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 115,
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(child: SvgPicture.asset("asset/image/landing.svg")),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: GridView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacePageX,
                  vertical: spacePageY,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: sqrt(children.length).ceil(),
                  mainAxisSpacing: space64,
                  crossAxisSpacing: space64,
                  mainAxisExtent: 300,
                  childAspectRatio: 400 / 300,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingPageOption extends StatefulWidget {
  final Widget? child;
  final Widget? label;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const LandingPageOption({
    super.key,
    this.child,
    required this.label,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<LandingPageOption> createState() => _LandingPageOptionState();
}

class _LandingPageOptionState extends State<LandingPageOption> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: isHover ? 1.15 : 1,
      child: MouseRegion(
        onEnter: (event) {
          setState(() => isHover = true);
        },
        onExit: (event) {
          setState(() => isHover = false);
        },

        child: Button(
          backgroundColor: widget.backgroundColor,
          type: ButtonType.outlined,
          textStyle: Theme.of(context).textTheme.displayMedium,
          onPressed: widget.onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (widget.label != null) Flexible(child: widget.label!),
              if (widget.child != null) Flexible(child: widget.child!),
            ],
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
