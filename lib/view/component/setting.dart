import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static TextStyle getSettingHeaderTextStyle(BuildContext context) {
    return context.textTheme.displayMedium!;
  }

  // static const children = <Widget>[
  //   LanguageSetting(),
  //   TimerSetting(),
  //   GameTypeSetting(),
  //   CourtSetting(),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(context, backgroundColor: context.colorScheme.primary),
      bottomNavigationBar: BottomBar(
        backgroundColor: context.colorScheme.primary,
        children: const [BackButtonBottomBar()],
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: space64, vertical: space32),
        child: Row(
          spacing: space32,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: LanguageSetting()),
                  Flexible(child: GameTypeSetting()),
                  Flexible(child: TimerSetting()),
                ],
              ),
            ),
            Expanded(child: CourtSetting()),
          ],
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
    return Button(
      shaded: false,
      type: ButtonType.outlined,
      backgroundColor: selected ? context.colorScheme.secondary : null,
      onPressed: onPressed,
      child: child,
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
      Widget child = SettingMultipleChoice(
        onPressed: () => setState(() {
          chosen = choice;
          PersistentSetting.instance.setCourtBackground(choice);
        }),
        selected: choice == chosen,
        child: Padding(
          padding: const EdgeInsets.all(spaceDefault),
          child: Image.asset(choice),
        ),
      );

      return Flexible(child: child);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceDefault,
      children: [
        Text(
          AppLocalizations.of(context)!.court_background,
          style: SettingPage.getSettingHeaderTextStyle(context),
        ),
        Flexible(
          child: ShadedContainer(
            padding: const EdgeInsets.all(space32),
            child: Column(
              spacing: space32,
              mainAxisSize: MainAxisSize.min,
              children: children.toUnmodifiableList(),
            ),
          ),
        ),
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
        ShadedContainer(
          child: SizedBox(
            width: 4 * textStyle!.fontSize!,
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
                onSubmitted: (_) => _onLosingFocus(),
                onTapOutside: (_) => _onLosingFocus(),
                onChanged: (_) => _onChange(),
              ),
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
      spacing: space32,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceCard,
      children: [
        Text(
          AppLocalizations.of(context)!.game_duration,
          style: SettingPage.getSettingHeaderTextStyle(context),
        ),
        TimePicker(
          initialDuration: PersistentSetting.instance.getGameDuration(),
          onChanged: (duration) {
            PersistentSetting.instance.setGameDuration(duration);
          },
        ),
      ],
    );
  }
}

class GameTypeSetting extends StatefulWidget {
  const GameTypeSetting({super.key});

  @override
  State<GameTypeSetting> createState() => _GameTypeSettingState();
}

class _GameTypeSettingState extends State<GameTypeSetting> {
  GameType chosen = PersistentSetting.instance.getGameType();

  Future<void> onGameTypeSelected(GameType selected) async {
    setState(() {
      chosen = selected;
      PersistentSetting.instance.setGameType(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceCard,
      children: [
        Text(
          AppLocalizations.of(context)!.game_type,
          style: SettingPage.getSettingHeaderTextStyle(context),
        ),
        ShadedContainer(
          child: Container(
            height: space128,
            padding: const EdgeInsets.all(space32),
            alignment: Alignment.center,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                final gameType = GameType.values[index];
                return SettingMultipleChoice(
                  onPressed: () {
                    onGameTypeSelected(gameType);
                  },
                  selected: chosen == gameType,
                  child: Text(
                    gameType.toDisplayString(context),
                    style: TextStyle(
                      color: context.colorScheme.onSecondaryContainer,
                    ),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: spaceCard),
              itemCount: GameType.values.length,
            ),
          ),
        ),
      ],
    );
  }
}

class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<PersistentSetting>().getLanguage();
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spaceCard,
      children: [
        Text(
          AppLocalizations.of(context)!.language,
          style: SettingPage.getSettingHeaderTextStyle(context),
        ),
        ShadedContainer(
          child: Container(
            height: space128,
            padding: const EdgeInsets.all(space32),
            alignment: Alignment.center,
            child: Center(
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, _) => const SizedBox(width: spaceCard),

                itemBuilder: (BuildContext context, int index) {
                  final locale = AppLocalizations.supportedLocales[index];
                  return SettingMultipleChoice(
                    onPressed: () {
                      PersistentSetting.instance.setLanguage(locale);
                    },
                    selected: currentLocale == locale,
                    child: Localizations.override(
                      locale: locale,
                      context: context,
                      child: Builder(
                        builder: (context) {
                          return Text(
                            AppLocalizations.of(context)!.language_name,
                          );
                        },
                      ),
                    ),
                  );
                },
                itemCount: AppLocalizations.supportedLocales.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
