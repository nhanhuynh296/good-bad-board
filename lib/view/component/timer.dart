import 'package:flutter/material.dart';
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
    _controller = AnimationController(
      vsync: this,
      duration: timerData.duration,
    );
    _controller.addStatusListener((status) {
      if (status.isCompleted) widget.onExpired?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      type: ButtonType.outlined,
      onPressed: () {
        if (!_controller.isAnimating) {
          _controller.repeat();
        } else {
          _controller.stop(canceled: false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spaceComponent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spaceComponent,
          children: [
            Text(
              'Time Remaining',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                final timeElapsed =
                    _controller.duration! * (1 - _controller.value);
                return Text(
                  timeElapsed.toDisplayString(),
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
