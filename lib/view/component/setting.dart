import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extention.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/view/component/container.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Setting", style: context.textTheme.titleLarge),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: spacePageX,
          vertical: spacePageY,
        ),
        child: const Column(children: [Flexible(child: CourtSetting())]),
      ),
    );
  }
}

class CourtSetting extends StatefulWidget {
  const CourtSetting({super.key});

  @override
  State<CourtSetting> createState() => _CourtSettingState();
}

class _CourtSettingState extends State<CourtSetting> {
  static const choices = <String>[
    "asset/image/badminton.webp",
    "asset/image/pickle_ball.webp",
  ];

  String chosen = choices.first;

  @override
  Widget build(BuildContext context) {
    final children = choices.map((choice) {
      final name = choice.split("/").last.replaceFirst('.webp', '');
      Widget child = Image.asset(choice);

      if (choice == chosen) {
        child = ShadedContainer(child: child);
      }
      child = Column(
        spacing: spaceCard,
        children: [
          GestureDetector(
            onTap:
                () => setState(() {
                  chosen = choice;
                  PersistentSetting.instance.setCourtBackground(choice);
                }),
            child: child,
          ),
          Text(name, style: context.textTheme.titleMedium),
        ],
      );
      return Flexible(child: child);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceCard,
      children: [
        Text("Court", style: context.textTheme.titleLarge),
        Row(spacing: spaceDefault, children: children.toList(growable: false)),
      ],
    );
  }
}
