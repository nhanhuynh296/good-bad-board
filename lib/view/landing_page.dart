import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/setting.dart';
import 'package:intersperse/intersperse.dart';

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
      LandingPageOption(
        label: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(color: context.colorScheme.onPrimary),
          textAlign: TextAlign.center,
        ),
        backgroundColor: context.colorScheme.primaryContainer,
        child: Icon(
          Icons.settings,
          color: context.colorScheme.onPrimary,
          size: 175,
        ),
        onTap: () => context.go('/settings'),
      ),
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
      appBar: Header(context),
      drawer: const LandingPageDrawer(),
      bottomNavigationBar: const BottomBar(
        children: [Spacer(), QuitBottomBarButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: space32,
          vertical: spacePageY,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (context.breakpoint.largerThan('xl'))
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (context.breakpoint.largerThan('xl'))
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
                    Expanded(
                      child: SvgPicture.asset("asset/image/landing.svg"),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: 3,
              child: GridView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: space32,
                  vertical: spacePageY,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.breakpoint.smallerOrEqualTo('sm')
                      ? 1
                      : sqrt(children.length).ceil(),
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

class Header extends AppBar {
  static String getTitle(BuildContext context) =>
      GoRouter.of(context).routeInformationProvider.value.uri.path;

  static TextStyle? getHeaderButtonTextStyle(BuildContext context) =>
      context.textTheme.headlineMedium?.copyWith();

  Header(
    BuildContext context, {
    super.key,
    super.leading,
    super.backgroundColor,
    Widget? title,
    List<Widget>? actions,
  }) : super(
         shape: const ContinuousRectangleBorder(side: outlinedBorderSide),
         titleTextStyle: context.textTheme.headlineLarge,
         title: title ?? Text(getTitle(context)),
         actions:
             [
                   ...?actions,
                   if (actions == null)
                     Container(
                       constraints: BottomBar.buttonConstraint,
                       color: backgroundColor != null
                           ? context.colorScheme.onPrimary
                           : context.colorScheme.primary,
                       alignment: Alignment.center,
                       child: Text(
                         DateTime.now().year.toString(),
                         style: getHeaderButtonTextStyle(context),
                       ),
                     ),
                 ]
                 .map(
                   (e) =>
                       Container(
                             constraints: BottomBar.buttonConstraint,
                             child: e,
                           )
                           as Widget,
                 )
                 .intersperseOuter(
                   VerticalDivider(
                     thickness: BottomBar.border.width,
                     width: BottomBar.border.width,
                   ),
                 )
                 .toUnmodifiableList(),
         toolbarHeight: BottomBar.headerHeight,
       );
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
              if (widget.child != null &&
                  context.breakpoint.largerOrEqualTo('xl'))
                Flexible(child: widget.child!),
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

class BottomBar extends StatelessWidget {
  final Iterable<Widget> children;
  final Color? backgroundColor;
  const BottomBar({super.key, this.children = const [], this.backgroundColor});

  static const headerHeight = 100.0;
  static const buttonConstraint = BoxConstraints.expand(
    width: 300,
    height: headerHeight,
  );
  static const border = BorderSide(width: 3);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        border: const BoxBorder.fromBorderSide(border),
        color: backgroundColor,
      ),
      child: Row(
        children: children
            .intersperseOuter(
              VerticalDivider(thickness: border.width, width: border.width),
            )
            .toUnmodifiableList(),
      ),
    );
  }
}

class QuitBottomBarButton extends StatelessWidget {
  const QuitBottomBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BottomBar.buttonConstraint,
      child: Button(
        onPressed: () =>
            SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
        rounded: false,
        icon: const Icon(Icons.logout),
        textStyle: Header.getHeaderButtonTextStyle(context),
        child: const Text("Quit"),
      ),
    );
  }
}

class BackButtonBottomBar extends StatelessWidget {
  const BackButtonBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BottomBar.buttonConstraint,
      child: Button(
        backgroundColor: context.colorScheme.onPrimary,
        onPressed: () {
          Navigator.of(context).pop();
        },
        rounded: false,
        icon: const Icon(Icons.chevron_left),
        textStyle: Header.getHeaderButtonTextStyle(
          context,
        )?.copyWith(fontWeight: FontWeight.bold),
        child: Text("Back", style: context.textTheme.titleLarge),
      ),
    );
  }
}
