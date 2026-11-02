import 'package:flutter/material.dart';

/// SearchBar fournit son propre contour. Ne pas lui imposer les contraintes
/// et le remplissage des champs de formulaire via InputDecorationTheme.
class KiboSearchFieldTheme extends StatelessWidget {
  const KiboSearchFieldTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationThemeData(
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        constraints: BoxConstraints(),
      ),
    ),
    child: child,
  );
}
