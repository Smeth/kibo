import '../../core/widgets/kibo_app_bar.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kiboSupportEmail = 'kanasmeth@gmail.com';
const kiboHelpUrl = 'https://kibo-assistance-2026.stonytern8.chatgpt.site';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: KiboAppBar(context, title: const Text('Aide et confidentialité')),
    body: KiboFormListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'KIBO · Le commerce, simplement.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Besoin d’aide ou d’un recours après modération ? '
          'Écrivez au support en indiquant le contexte et, si possible, '
          'l’identifiant de l’annonce. Ne transmettez jamais votre mot de passe, '
          'un code de connexion ou un lien de confirmation.',
        ),
        const SizedBox(height: 12),
        const SelectableText(kiboSupportEmail),
        TextButton(
          onPressed: () async {
            try {
              final opened = await launchUrl(
                Uri.parse(kiboHelpUrl),
                mode: LaunchMode.externalApplication,
              );
              if (!opened) throw StateError('Browser unavailable');
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Les informations restent disponibles sur cette page.',
                    ),
                  ),
                );
              }
            }
          },
          child: const Text('Consulter les informations en ligne'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.mail_outline),
          label: const Text('Écrire au support'),
          onPressed: () async {
            var opened = false;
            try {
              opened = await launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: kiboSupportEmail,
                  queryParameters: {'subject': 'Assistance KIBO'},
                ),
              );
            } catch (_) {
              opened = false;
            }
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copiez l’adresse dans votre application email.',
                  ),
                ),
              );
            }
          },
        ),
        const Divider(),
        Text('Vos données', style: Theme.of(context).textTheme.titleMedium),
        Text(
          'Les annonces et les informations publiques du profil sont '
          'visibles sans compte. Vos coordonnées de contact ne sont partagées '
          'qu’après connexion et selon vos choix. Les favoris visiteurs restent '
          'sur le téléphone ; leur transfert vers un compte demande votre accord.',
        ),
        const SizedBox(height: 12),
        Text(
          'Messages et sécurité',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Les conversations sont réservées à leurs participants et aux '
          'administrateurs autorisés pour la sécurité et la modération. '
          'Elles ne sont pas chiffrées de bout en bout. Signalez un abus depuis '
          'le message ou le profil ; bloquer un interlocuteur empêche de nouveaux '
          'échanges, sans effacer les échanges existants.',
        ),
        const SizedBox(height: 12),
        Text(
          'Supprimer mon compte',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Depuis Profil → Compte et données, demandez la suppression. '
          'Vous pouvez aussi écrire au support depuis l’adresse liée au compte, '
          'sans envoyer de secret. La demande est vérifiée avant exécution. '
          'Après suppression, les contributions des autres participants peuvent '
          'être conservées en privé pendant 15 jours, avec anonymisation des '
          'messages du compte supprimé. Les sauvegardes du prestataire suivent '
          'leur propre cycle ; les copies déjà exportées ne peuvent être rappelées.',
        ),
        const SizedBox(height: 12),
        Text(
          'Règles de la marketplace',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Pas d’arnaque, de harcèlement, de contenu illégal ou trompeur. '
          'La publication est immédiate après validation, puis modérée. '
          'Une décision peut être contestée auprès du support. '
          'KIBO ne propose ni paiement ni livraison intégrés en V1. '
          'Ne versez pas d’acompte sans avoir vérifié le bien et le vendeur.',
        ),
        const SizedBox(height: 16),
        Text(
          'Version pilote 1.0.0+2 · Android · mise à jour du 2 novembre 2026',
        ),
      ],
    ),
  );
}
