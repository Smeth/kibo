import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Le titre conserve sa place avec une grande police et les actions à droite.
class KiboAppBar extends AppBar {
  KiboAppBar(
    BuildContext context, {
    super.key,
    required Widget title,
    super.actions,
  }) : super(
         toolbarHeight: _stacked(context, title, actions?.length ?? 0)
             ? kToolbarHeight
             : _height(context, title, actions?.length ?? 0),
         title: _stacked(context, title, actions?.length ?? 0)
             ? null
             : _title(context, title),
         bottom: _stacked(context, title, actions?.length ?? 0)
             ? PreferredSize(
                 preferredSize: Size.fromHeight(
                   _height(context, title, 0, fullWidth: true),
                 ),
                 child: Padding(
                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                   child: Align(
                     alignment: Alignment.centerLeft,
                     child: _title(context, title),
                   ),
                 ),
               )
             : null,
       );

  static Widget _title(BuildContext context, Widget title) =>
      title is Text && title.data != null
      ? Text(
          title.data!,
          style:
              title.style ??
              Theme.of(context).appBarTheme.titleTextStyle ??
              Theme.of(context).textTheme.titleLarge,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        )
      : title;

  static bool _stacked(BuildContext context, Widget title, int actions) =>
      MediaQuery.textScalerOf(context).scale(20) > 28 &&
      _height(context, title, actions) > kToolbarHeight;

  static double _height(
    BuildContext context,
    Widget title,
    int actions, {
    bool fullWidth = false,
  }) {
    if (title is! Text || title.data == null) return kToolbarHeight;
    final painter =
        TextPainter(
          text: TextSpan(
            text: title.data,
            style:
                title.style ??
                Theme.of(context).appBarTheme.titleTextStyle ??
                Theme.of(context).textTheme.titleLarge,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 3,
          ellipsis: '…',
        )..layout(
          maxWidth: math.max(
            48,
            MediaQuery.sizeOf(context).width -
                (fullWidth ? 32 : 88 + actions * 48),
          ),
        );
    final height = math.max(kToolbarHeight, painter.height + 16);
    painter.dispose();
    return height;
  }
}
