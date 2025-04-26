import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/dialog/edit_player.dart';
import 'package:provider/provider.dart';

class _PlayerComponent extends StatelessWidget {
  final Player data;

  const _PlayerComponent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${data.name.toUpperCase()} (${data.elo.name.toUpperCase()})',
      textAlign: TextAlign.center,
    );
  }
}

class ClickablePlayerComponent extends _PlayerComponent {
  final bool filled;
  final VoidCallback? onTap;
  final bool disabled;

  const ClickablePlayerComponent({
    super.key,
    required super.data,
    this.filled = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    void onSecondaryAction() {
      debugPrint("Pressed ${data.name}");
      showAdaptiveDialog(
        context: context,
        builder:
            (_) => EditPlayerDialog(
              player: data,
              onSubmit: (newPlayer) {
                Provider.of<GameData>(
                  context,
                  listen: false,
                ).onUpdatePlayer(newPlayer);
                debugPrint("Updated ${newPlayer.name}");
              },
            ),
      );
    }

    final child = _PlayerComponent(data: data);
    return Button(
      type: filled ? ButtonType.filled : ButtonType.outlined,
      onPressed: onTap,
      onLongPress: onSecondaryAction,
      disabled: disabled,
      child: child,
    );
  }
}

class DraggablePlayerComponent extends _PlayerComponent {
  final DragTargetAccept<Player>? onDragToTarget;
  final DragTargetWillAccept<Player>? shouldAcceptIncomingDragPlayer;

  const DraggablePlayerComponent({
    super.key,
    required super.data,
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
            child: ClickablePlayerComponent(
              data: data,
              filled: true,
              disabled: isInvalidDragHovering,
            ),
          ),
        );
      },
    );
  }
}

class _DraggingPlayerComponent extends _PlayerComponent {
  const _DraggingPlayerComponent({required super.data});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: null, child: _PlayerComponent(data: data));
  }
}
