import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/focus_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Swipe-left edit/delete for focus record rows.
class SwipeFocusRecord extends ConsumerStatefulWidget {
  const SwipeFocusRecord({
    super.key,
    required this.recordId,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  final int recordId;
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<SwipeFocusRecord> createState() => _SwipeFocusRecordState();
}

class _SwipeFocusRecordState extends ConsumerState<SwipeFocusRecord> {
  static const _actionExtent = 108.0;
  double _offset = 0;
  bool _dragging = false;

  bool get _isOpen => _offset > _actionExtent * 0.4;

  @override
  Widget build(BuildContext context) {
    final openId = ref.watch(focusRecordSwipeOpenProvider);
    if (openId != null && openId != widget.recordId && _offset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _offset = 0);
      });
    }

    final l10n = AppLocalizations.of(context);
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: l10n.edit,
                  icon: Icons.edit_outlined,
                  color: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                  onTap: () {
                    _close();
                    widget.onEdit();
                  },
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  color: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration:
                _dragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(-_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (details) {
                ref.read(focusRecordSwipeOpenProvider.notifier).state =
                    widget.recordId;
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
    ref.read(focusRecordSwipeOpenProvider.notifier).state = widget.recordId;
  }

  void _close() {
    setState(() => _offset = 0);
    if (ref.read(focusRecordSwipeOpenProvider) == widget.recordId) {
      ref.read(focusRecordSwipeOpenProvider.notifier).state = null;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 50,
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
