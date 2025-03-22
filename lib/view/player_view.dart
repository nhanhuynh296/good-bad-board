import 'package:flutter/material.dart';
import 'package:good_bad_board/model/Player.dart';

class _PlayerView extends StatelessWidget {
  final Player data;

  const _PlayerView({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Text(
        '${data.name} (${data.elo.name.toUpperCase()})',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class DraggablePlayerView extends StatelessWidget {
  final Player data;
  final DragTargetAccept<Player>? onDragToTarget;
  final DragTargetWillAccept<Player>? shouldAcceptIncomingDragPlayer;

  const DraggablePlayerView({
    super.key,
    required this.data,
    this.onDragToTarget,
    this.shouldAcceptIncomingDragPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Player>(
      onWillAcceptWithDetails:
          (detail) =>
              detail.data != data &&
              (shouldAcceptIncomingDragPlayer?.call(detail.data) ?? true),
      onAcceptWithDetails: (detail) => onDragToTarget?.call(detail.data),
      builder: (context, candidateItems, rejectedItems) {
        final bool isValidDragHovering = candidateItems.isNotEmpty;
        final bool isInvalidDragHovering = rejectedItems.isNotEmpty;
        return Draggable<Player>(
          data: data,
          // delay: Durations.short1,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _DraggingPlayerView(data: data),
          child: Transform.scale(
            scale: isValidDragHovering ? 1.2 : 1.0,
            child: FilledButton(
              onPressed:
                  isInvalidDragHovering
                      ? null
                      : () {
                        print("Pressed ${data.name}");
                      },
              child: _PlayerView(data: data),
            ),
          ),
        );
      },
    );
  }
}

class _DraggingPlayerView extends StatelessWidget {
  final Player data;

  const _DraggingPlayerView({required this.data});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: null, child: _PlayerView(data: data));
  }
}
