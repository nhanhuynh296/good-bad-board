import 'package:flutter/material.dart';
import 'package:good_bad_board/core/duration_extention.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/timer_data.dart';
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spaceComponent),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          if (_controller.isCompleted) {
            widget.onExpired?.call();
          }
          final timeElapsed = _controller.duration! * (1 - _controller.value);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Time Remaining',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (!_controller.isAnimating) {
                      _controller.repeat();
                    } else {
                      _controller.stop(canceled: false);
                    }
                  },
                  child: Text(
                    timeElapsed.toDisplayString(),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
