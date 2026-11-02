import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Espacement minimum commun, sans cumuler les SizedBox déjà présents.
List<Widget> _spaced(List<Widget> children, double gap) {
  final result = <Widget>[];
  var nextGap = gap;
  for (final child in children) {
    if (child is SizedBox && child.child == null && child.width == null) {
      nextGap = math.max(nextGap, child.height ?? 0);
      continue;
    }
    if (result.isNotEmpty) result.add(SizedBox(height: nextGap));
    result.add(child);
    nextGap = gap;
  }
  return result;
}

class KiboFormColumn extends StatelessWidget {
  const KiboFormColumn({super.key, required this.children, this.gap = 16});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _spaced(children, gap),
  );
}

class KiboFormListView extends StatelessWidget {
  const KiboFormListView({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(24),
    this.onRefresh,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: padding,
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: _spaced(children, 16),
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
