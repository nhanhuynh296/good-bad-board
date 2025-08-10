import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
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
      child: Button(
        type: ButtonType.text,
        padding: EdgeInsets.zero,
        onPressed: () async {
          if (context.read<GameData>().stagingMatches.isEmpty &&
              _controller.isDismissed) {
            context.showErrorToast('Generate some games first!');
            return;
          }
          // Order of operations is important here.
          // If the controller is dismissed or completed, we animate back to 0.
          if (_controller.isDismissed || _controller.isCompleted) {
            await _controller.animateBack(0, duration: Durations.short3);
            _controller.forward();
          } else if (_controller.isAnimating) {
            // If the controller is animating, we stop it.
            _controller.stop(canceled: false);
          } else {
            // If the controller is not animating, we start it.
            _controller.forward();
          }
        },
        onLongPress: () {
          _controller.animateBack(0, duration: Durations.short3);
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _controller.value,
                    backgroundColor: Colors.transparent,
                    color: context.colorScheme.secondary,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: spaceComponent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: spaceComponent,
                children: [
                  Text(
                    'Time Remaining',
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, _) {
                      return Text(
                        (_controller.duration! - timeElapsed).toDisplayString(),
                        style: textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
