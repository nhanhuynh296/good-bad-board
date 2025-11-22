import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/edit_player.dart';
import 'package:provider/provider.dart';

import 'button.dart';

class _PlayerComponent extends StatelessWidget {
  final Player data;
  final bool showElo;

  const _PlayerComponent({super.key, required this.data, this.showElo = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 65),
      padding: const EdgeInsets.symmetric(horizontal: space8),
      child: Row(
        spacing: space8,
        mainAxisAlignment: showElo
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          Text(
            data.name().toUpperCase(),
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          if (showElo)
            if (showElo)
              Text(
                data.elo.name.toUpperCase(),
                style: context.textTheme.titleMedium,
              ),
        ],
      ),
    );
  }
}

class ClickablePlayerComponent extends _PlayerComponent {
  final bool filled;
  final VoidCallback? onTap;
  final bool disabled;
  final bool inMatch;
  final bool shaded;

  const ClickablePlayerComponent({
    super.key,
    super.showElo = true,
    required super.data,
    this.filled = false,
    this.disabled = false,
    this.inMatch = false,
    this.shaded = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    void onSecondaryAction() {
      debugPrint("Pressed ${data.name()}");
      showAdaptiveDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => EditPlayerDialog(
          player: data,
          persistAfterInactive: !inMatch,
          onSubmit: (newPlayer) {
            Provider.of<GameData>(
              context,
              listen: false,
            ).onUpdatePlayer(newPlayer);
            debugPrint("Updated ${newPlayer.name()}");
          },
        ),
      );
    }

    return ShadedContainer(
      shaded: shaded,
      child: Button(
        type: ButtonType.text,
        onPressed: onTap,
        onLongPress: onSecondaryAction,
        disabled: disabled,
        backgroundColor: filled ? AppColors.yellow : null,
        textStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: filled ? Colors.black : null),
        child: super.build(context),
      ),
    );
  }
}

class DraggablePlayerComponent extends ClickablePlayerComponent {
  final DragTargetAccept<Player>? onDragToTarget;
  final DragTargetWillAccept<Player>? shouldAcceptIncomingDragPlayer;

  const DraggablePlayerComponent({
    super.key,
    super.showElo = true,
    super.shaded = true,
    required super.data,
    this.onDragToTarget,
    this.shouldAcceptIncomingDragPlayer,
  }) : super(inMatch: true, filled: true);

  static const matchGapColor = {
    0: Colors.green,
    1: Colors.deepOrangeAccent,
    3: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final playersHistory = gameData.getCurrentPlayersHistory();
    final matchPlayed = gameData.getCurrentPlayersHistory()[data] ?? 0;
    final maxMatchPlayed = playersHistory.values.max;
    return DragTarget<Player>(
      onWillAcceptWithDetails: (detail) =>
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
            child: Badge(
              label: Text(matchPlayed.toStringAsFixed(0)),
              backgroundColor:
                  matchGapColor[maxMatchPlayed - matchPlayed] ??
                  matchGapColor[matchGapColor.keys.max],
              child: ClickablePlayerComponent(
                showElo: showElo,
                shaded: shaded,
                inMatch: inMatch,
                key: ValueKey(data.id),
                data: data,
                filled: filled,
                disabled: isInvalidDragHovering,
              ),
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
