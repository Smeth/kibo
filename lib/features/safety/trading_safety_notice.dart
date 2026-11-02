import 'package:flutter/material.dart';

class TradingSafetyNotice extends StatelessWidget {
  const TradingSafetyNotice({super.key});
  @override
  Widget build(BuildContext context) => const ExpansionTile(
    title: Text('Acheter et vendre prudemment'),
    leading: Icon(Icons.shield_outlined),
    children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Ne partagez jamais de code de connexion ni de lien de confirmation. Vérifiez le produit et l’identité de votre interlocuteur avant de conclure. Méfiez-vous des frais demandés pour débloquer une vente ou un gain. KIBO ne propose aucun paiement intégré en V1. Utilisez Signaler en cas de contenu suspect.',
        ),
      ),
    ],
  );
}
