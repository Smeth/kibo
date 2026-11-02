import 'package:flutter/material.dart';

String? publicationAgeLabel(DateTime? publishedAt, {required DateTime now}) {
  if (publishedAt == null) return null;
  final age = now.toUtc().difference(publishedAt.toUtc());
  if (age.isNegative) {
    final date = publishedAt.toLocal();
    return 'Publié le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  if (age.inMinutes < 1) return 'à l’instant';
  if (age.inHours < 1) return 'il y a ${age.inMinutes} min';
  if (age.inDays < 1) return 'il y a ${age.inHours} h';
  if (age.inDays < 30) return 'il y a ${age.inDays} j';
  if (age.inDays < 365) return 'il y a ${age.inDays ~/ 30} mois';
  final years = age.inDays ~/ 365;
  return 'il y a $years ${years == 1 ? 'an' : 'ans'}';
}

class PublicationAge extends StatelessWidget {
  const PublicationAge({
    super.key,
    required this.publishedAt,
    this.detailed = false,
  });
  final DateTime? publishedAt;
  final bool detailed;
  @override
  Widget build(BuildContext context) {
    final label = publicationAgeLabel(publishedAt, now: DateTime.now());
    if (label == null) {
      return detailed
          ? const Text('Date de publication indisponible')
          : const SizedBox.shrink();
    }
    return Semantics(
      label: 'Publication : $label',
      excludeSemantics: true,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
