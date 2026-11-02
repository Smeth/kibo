import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Surface commune aux aperçus, choix et menus contextuels.
Future<T?> showKiboModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  showDragHandle: false,
  builder: (context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(10, 0, 10, media.viewInsets.bottom + 10),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: math.max(
                0,
                media.size.height -
                    media.viewInsets.bottom -
                    media.padding.vertical -
                    32,
              ),
            ),
            child: Material(
              color: colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: .65),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const SizedBox(width: 36, height: 4),
                    ),
                  ),
                  Flexible(child: builder(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  },
);

class KiboSheet extends StatelessWidget {
  const KiboSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  Widget _title(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
  Widget _close(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Fermer',
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    ),
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.close_rounded, size: 20),
  );
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.textScalerOf(context).scale(20) > 28) ...[
          Align(alignment: Alignment.centerRight, child: _close(context)),
          const SizedBox(height: 8),
          _title(context),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _title(context),
                ),
              ),
              const SizedBox(width: 12),
              _close(context),
            ],
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        child,
        if (footer != null) ...[const SizedBox(height: 24), footer!],
      ],
    ),
  );
}

/// Action de feuille : une ligne entière, sans succession de boutons disparates.
class KiboSheetAction extends StatelessWidget {
  const KiboSheetAction({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = onTap == null
        ? colors.onSurface.withValues(alpha: .38)
        : destructive
        ? colors.error
        : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          enabled: onTap != null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          trailing: MediaQuery.textScalerOf(context).scale(16) > 24
              ? null
              : Icon(Icons.chevron_right_rounded, color: color, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Confirmation et saisie : largeur contenue, lecture verticale et actions nettes.
class KiboDialog extends StatelessWidget {
  const KiboDialog({
    super.key,
    this.title,
    this.icon,
    this.content,
    this.actions = const [],
    this.destructive = false,
  });
  final Widget? title, icon, content;
  final List<Widget> actions;
  final bool destructive;
  Widget _body(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: destructive
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: destructive
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.primary,
                ),
                child: icon!,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (title != null) ...[
          Semantics(
            header: true,
            child: DefaultTextStyle(
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
              child: title!,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ?content,
      ],
    ),
  );

  Widget _footer(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions.reversed) ...[
          FilledButtonTheme(
            data: FilledButtonThemeData(
              style: destructive
                  ? (Theme.of(context).filledButtonTheme.style ??
                            const ButtonStyle())
                        .copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.disabled)
                                ? null
                                : Theme.of(context).colorScheme.error,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.disabled)
                                ? null
                                : Theme.of(context).colorScheme.onError,
                          ),
                        )
                  : Theme.of(context).filledButtonTheme.style,
            ),
            child: action,
          ),
          const SizedBox(height: 8),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    constraints: const BoxConstraints(maxWidth: 440),
    clipBehavior: Clip.antiAlias,
    elevation: 12,
    shadowColor: Colors.black.withValues(alpha: .12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 260) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _body(context),
                if (actions.isNotEmpty) _footer(context),
              ],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: _body(context),
              ),
            ),
            if (actions.isNotEmpty) _footer(context),
          ],
        );
      },
    ),
  );
}
