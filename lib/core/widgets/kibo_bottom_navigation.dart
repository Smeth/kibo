import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Garde tous les libellés visibles, sans réduire le texte demandé par Android.
class KiboBottomNavigation extends StatelessWidget {
  const KiboBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).navigationBarTheme;
    final scaler = MediaQuery.textScalerOf(context);
    return Material(
      color: theme.backgroundColor,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            var minimumWidth = 64.0;
            var labelHeight = 0.0;
            for (final destination in destinations) {
              final painter = TextPainter(
                text: TextSpan(
                  text: destination.label,
                  style: theme.labelTextStyle!.resolve({WidgetState.selected}),
                ),
                textDirection: Directionality.of(context),
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              minimumWidth = math.max(
                minimumWidth,
                painter.width.ceilToDouble() + 8,
              );
              labelHeight = math.max(
                labelHeight,
                painter.height.ceilToDouble(),
              );
              painter.dispose();
            }
            final columns = (constraints.maxWidth / minimumWidth).floor().clamp(
              1,
              destinations.length,
            );
            final itemWidth = constraints.maxWidth / columns;
            final itemHeight = math.max(72.0, 32 + 4 + labelHeight + 16);
            return Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var index = 0; index < destinations.length; index++)
                  SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: Semantics(
                      selected: index == selectedIndex,
                      button: true,
                      child: InkWell(
                        onTap: () => onDestinationSelected(index),
                        child: _destination(context, index, labelHeight),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int index, double labelHeight) {
    final theme = Theme.of(context).navigationBarTheme;
    final destination = destinations[index];
    final selected = index == selectedIndex;
    final states = <WidgetState>{if (selected) WidgetState.selected};
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? theme.indicatorColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconTheme(
            data: theme.iconTheme!.resolve(states)!,
            child: selected
                ? destination.selectedIcon ?? destination.icon
                : destination.icon,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: labelHeight,
          child: Text(
            destination.label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: theme.labelTextStyle!.resolve(states),
          ),
        ),
      ],
    );
  }
}
