import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extention.dart';
import 'package:good_bad_board/core/duration_extention.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:provider/provider.dart';

class CountdownTimer extends StatefulWidget {
  final VoidCallback? onExpired;

  const CountdownTimer({super.key, this.onExpired});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool paused = true;

  @override
  void initState() {
    super.initState();
    final timerData = Provider.of<TimerData>(context, listen: false);
    _controller = AnimationController(vsync: this, duration: timerData.duration)
      ..value =
          timerData.elapsed.inMilliseconds / timerData.duration.inMilliseconds;
    _controller.addStatusListener((status) {
      if (status.isCompleted) widget.onExpired?.call();
    });
  }

  @override
  void deactivate() {
    context.read<TimerData>().saveTimeElapsed(timeElapsed);
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration get timeElapsed => _controller.duration! * _controller.value;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Button(
      type: ButtonType.outlined,
      onPressed: () {
        if (!_controller.isAnimating) {
          _controller.repeat();
        } else {
          _controller.stop(canceled: false);
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
    );
  }
}
