import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../providers/batch_providers.dart';
import '../providers/l10n_providers.dart';

/// Swipe-left quick actions that stay open until dismissed (iOS-style).
class SwipeEventActions extends ConsumerStatefulWidget {
  const SwipeEventActions({
    super.key,
    required this.event,
    required this.child,
    required this.enabled,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  final Event event;
  final Widget child;
  final bool enabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  ConsumerState<SwipeEventActions> createState() => _SwipeEventActionsState();
}

class _SwipeEventActionsState extends ConsumerState<SwipeEventActions> {
  static const _actionExtent = 162.0;
  double _offset = 0;
  bool _dragging = false;

  bool get _isOpen => _offset > _actionExtent * 0.4;

  @override
  Widget build(BuildContext context) {
    final openId = ref.watch(swipeOpenProvider);
    if (openId != null && openId != widget.event.id && _offset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _offset = 0);
      });
    }

    if (!widget.enabled ||
        widget.onEdit == null ||
        widget.onDuplicate == null ||
        widget.onDelete == null) {
      return widget.child;
    }

    final l10n = ref.watch(appLocalizationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final backdrop = Theme.of(context).scaffoldBackgroundColor;

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _actionExtent,
            child: _ActionsRow(
              l10n: l10n,
              scheme: scheme,
              onEdit: () {
                _close();
                widget.onEdit!();
              },
              onDuplicate: () {
                _close();
                widget.onDuplicate!();
              },
              onDelete: () {
                _close();
                widget.onDelete!();
              },
            ),
          ),
          AnimatedContainer(
            duration: _dragging
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(-_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (details) {
                ref.read(swipeOpenProvider.notifier).state = widget.event.id;
                setState(() {
                  _offset = (_offset - details.delta.dx)
                      .clamp(0.0, _actionExtent);
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() => _dragging = false);
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200 || _offset > _actionExtent / 2) {
                  _snapOpen();
                } else {
                  _close();
                }
              },
              onHorizontalDragCancel: () => setState(() => _dragging = false),
              onTap: _isOpen ? _close : null,
              child: ColoredBox(
                color: backdrop,
                child: SizedBox(
                  width: double.infinity,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snapOpen() {
    setState(() => _offset = _actionExtent);
    ref.read(swipeOpenProvider.notifier).state = widget.event.id;
  }

  void _close() {
    setState(() => _offset = 0);
    if (ref.read(swipeOpenProvider) == widget.event.id) {
      ref.read(swipeOpenProvider.notifier).state = null;
    }
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.l10n,
    required this.scheme,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _SwipeActionButton(
          label: l10n.edit,
          icon: Icons.edit_outlined,
          color: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          onTap: onEdit,
        ),
        const SizedBox(width: 4),
        _SwipeActionButton(
          label: l10n.copy,
          icon: Icons.copy_outlined,
          color: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          onTap: onDuplicate,
        ),
        const SizedBox(width: 4),
        _SwipeActionButton(
          label: l10n.delete,
          icon: Icons.delete_outline,
          color: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;

  static const _buttonWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: _buttonWidth,
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDeleteEvent(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.confirmDeleteTitle),
      content: Text(l10n.confirmDeleteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok == true;
}
