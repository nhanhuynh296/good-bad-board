import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';

class _PlayerComponent extends StatelessWidget {
  final Player data;

  const _PlayerComponent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${data.name} (${data.elo.name.toUpperCase()})',
      textAlign: TextAlign.center,
    );
  }
}

class DraggablePlayerComponent extends StatelessWidget {
  final Player data;
  final DragTargetAccept<Player>? onDragToTarget;
  final DragTargetWillAccept<Player>? shouldAcceptIncomingDragPlayer;

  const DraggablePlayerComponent({
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
          feedback: _DraggingPlayerComponent(data: data),
          child: Transform.scale(
            scale: isValidDragHovering ? 1.2 : 1.0,
            child: FilledButton(
              onPressed:
                  isInvalidDragHovering
                      ? null
                      : () {
                        debugPrint("Pressed ${data.name}");
                      },
              child: _PlayerComponent(data: data),
            ),
          ),
        );
      },
    );
  }
}

class _DraggingPlayerComponent extends StatelessWidget {
  final Player data;

  const _DraggingPlayerComponent({required this.data});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: null, child: _PlayerComponent(data: data));
  }
}
