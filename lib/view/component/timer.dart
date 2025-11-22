import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:provider/provider.dart';

class CountdownTimer extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback? onExpired;

  const CountdownTimer({super.key, required this.controller, this.onExpired});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addStatusListener(statusListener);
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeStatusListener(statusListener);
      _controller = widget.controller;
      _controller.addStatusListener(statusListener);
    }
  }

  void statusListener(AnimationStatus status) {
    if (status.isCompleted) widget.onExpired?.call();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(statusListener);
    super.dispose();
  }

  Duration get timeElapsed => _controller.duration! * _controller.value;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return ShadedContainer(
      rounded: false,
      child: Container(
        height: BottomBar.headerHeight,
        decoration: BoxDecoration(color: context.colorScheme.primary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.time_remaining,
                      style: textTheme.headlineMedium?.copyWith(
                        color: context.colorScheme.onPrimary,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 2,
                    ),
                  ),
                  Flexible(
                    child: ShadedContainer(
                      bordered: false,
                      padding: const EdgeInsets.symmetric(
                        // vertical: spaceComponent,
                        horizontal: spaceDefault,
                      ),
                      rounded: false,
                      shaded: false,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, _) {
                          return Text(
                            (_controller.duration! - timeElapsed)
                                .toDisplayString(),
                            style: textTheme.displayMedium?.copyWith(
                              color: context.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              thickness: BottomBar.border.width,
              width: BottomBar.border.width,
            ),
            Flexible(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                alignment: Alignment.center,
                color: context.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: spaceComponent),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Button(
                          icon: Icon(
                            size: 40,
                            _controller.isAnimating
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () async {
                            if (context
                                    .read<GameData>()
                                    .stagingMatches
                                    .isEmpty &&
                                _controller.isDismissed) {
                              context.showErrorToast(
                                'Generate some games first!',
                              );
                              return;
                            }
                            // Order of operations is important here.
                            // If the controller is dismissed or completed, we animate back to 0.
                            if (_controller.isDismissed ||
                                _controller.isCompleted) {
                              _controller
                                ..reset()
                                ..forward();
                            } else if (_controller.isAnimating) {
                              // If the controller is animating, we stop it.
                              _controller.value = _controller.value;
                            } else {
                              // If the controller is not animating, we start it.
                              _controller.forward();
                            }
                          },
                        ),
                        Button(
                          icon: const Icon(Icons.cached, size: 40),
                          onPressed: () {
                            _controller.reset();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
