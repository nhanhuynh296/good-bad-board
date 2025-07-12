import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
        child: const Column(
          spacing: space32,
          children: [CourtSetting(), TimerSetting(), GameTypeSetting()],
        ),
      ),
    );
  }
}

class SettingMultipleChoice extends StatelessWidget {
  final Widget child;
  final bool selected;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  const SettingMultipleChoice({
    super.key,
    required this.child,
    this.selected = false,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: goldenRatio,
      child: ShadedContainer(
        backgroundColor: selected
            ? context.colorScheme.secondaryContainer
            : null,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(spaceCard),
            child: Center(child: child),
          ),
        ),
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
      final name = choice
          .split("/")
          .last
          .replaceFirst('.webp', '')
          .replaceAll('_', ' ')
          .toUpperCase();
      Widget child = SettingMultipleChoice(
        selected: choice == chosen,
        child: Image.asset(choice),
      );

      child = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spaceCard,
        children: [
          GestureDetector(
            onTap: () => setState(() {
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
        Text("Court Theme", style: context.textTheme.titleLarge),
        Row(spacing: spaceDefault, children: children.toList(growable: false)),
      ],
    );
  }
}

class TimePicker extends StatefulWidget {
  final Duration initialDuration;
  final void Function(Duration) onChanged;

  const TimePicker({
    super.key,
    required this.initialDuration,
    required this.onChanged,
  });

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late final TextEditingController minuteTextController;
  late final TextEditingController secondTextController;

  final numberFormat = NumberFormat('00');

  @override
  void initState() {
    super.initState();
    minuteTextController = TextEditingController(
      text: numberFormat.format(widget.initialDuration.inDisplayMinutes),
    );
    secondTextController = TextEditingController(
      text: numberFormat.format(widget.initialDuration.inDisplaySeconds),
    );
  }

  @override
  void dispose() {
    minuteTextController.dispose();
    secondTextController.dispose();
    super.dispose();
  }

  void _onChange() {
    final m = (int.tryParse(minuteTextController.text) ?? 0);
    final s = (int.tryParse(secondTextController.text) ?? 0);
    if (m > Duration.minutesPerHour) {
      minuteTextController.text = numberFormat.format(0);
    }
    if (s > Duration.secondsPerMinute) {
      secondTextController.text = numberFormat.format(0);
    }
  }

  void _onLosingFocus() {
    final m = (int.tryParse(minuteTextController.text) ?? 0);
    final s = (int.tryParse(secondTextController.text) ?? 0);
    minuteTextController.text = numberFormat.format(m);
    secondTextController.text = numberFormat.format(s);
    widget.onChanged(Duration(minutes: m, seconds: s));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
  }) {
    final textStyle = context.textTheme.displayLarge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        SizedBox(
          width: 3 * textStyle!.fontSize!,
          child: Focus(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: textStyle,
              keyboardType: TextInputType.number,

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () => controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              ),

              onTapOutside: (_) => _onLosingFocus(),
              onChanged: (_) => _onChange(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildField(controller: minuteTextController, label: "min"),
        Text(":", style: context.textTheme.displayLarge),
        _buildField(controller: secondTextController, label: "sec"),
      ],
    );
  }
}

class TimerSetting extends StatelessWidget {
  const TimerSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final timerData = context.watch<TimerData>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceCard,
      children: [
        Text("Game Duration", style: context.textTheme.titleLarge),
        TimePicker(
          initialDuration: timerData.duration,
          onChanged: (duration) {
            Provider.of<TimerData>(
              context,
              listen: false,
            ).setDuration(duration);
          },
        ),
      ],
    );
  }
}

class GameTypeSetting extends StatefulWidget {
  const GameTypeSetting({super.key});

  static const options = ["TIME BASED", "GAME BASED"];

  @override
  State<GameTypeSetting> createState() => _GameTypeSettingState();
}

class _GameTypeSettingState extends State<GameTypeSetting> {
  GameType chosen = GameType.values.first;

  Future<void> onGameTypeSelected(GameType selected) async {
    setState(() {
      chosen = selected;
      PersistentSetting.instance.setGameType(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spaceCard,
      children: [
        Text("Game Type", style: context.textTheme.titleLarge),
        Row(
          spacing: spaceCard,
          children: GameType.values
              .map(
                (gameType) => Expanded(
                  child: SettingMultipleChoice(
                    onPressed: () {
                      onGameTypeSelected(gameType);

                      if (gameType != GameType.timeBased) {
                        context.showToast(
                          "${chosen.toDisplayString()} is being developed, stay tuned!",
                        );

                        onGameTypeSelected(GameType.timeBased);
                      }
                    },
                    selected: chosen == gameType,
                    child: Text(
                      gameType.toDisplayString(),
                      style: TextStyle(
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              )
              .toUnmodifiableList(),
        ),
      ],
    );
  }
}
