import 'package:flutter/material.dart';
import '../theme/kibo_tokens.dart';

class KiboSection extends StatelessWidget {
  const KiboSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.child,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (child != null) ...[const SizedBox(height: 12), child!],
      ],
    ),
  );
}

/// Menu de profil : même action, cible tactile et lecture cohérentes.
class KiboMenuAction extends StatelessWidget {
  const KiboMenuAction({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KiboTokens.gutter,
        vertical: 4,
      ),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
