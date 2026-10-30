# KIBO

**Le commerce, simplement.**

KIBO est une marketplace congolaise de produits et services. Le lancement initial cible Brazzaville, avec une extension prévue vers Pointe-Noire et d'autres villes.

## État du projet
Le projet Flutter a été initialisé et testé localement sur un téléphone Android. Le socle Flutter local doit encore être publié dans GitHub via une Pull Request. Voir [l'avancement](docs/PROGRESS.md) et la [prochaine tâche](docs/NEXT_TASK.md).

## Produit V1
- Consultation publique des annonces sans compte.
- Publication et interactions réservées aux utilisateurs connectés.
- Contact par WhatsApp, appel et chat intégré.
- Jusqu'à 8 photos par annonce.
- Recherche, filtres, favoris, commentaires publics et réponses.
- Notifications et signalements.
- Publication immédiate après validation des champs, avec modération après publication.
- Authentification prévue : téléphone + OTP, Google OAuth, email + mot de passe.
- Paiement et livraison intégrés hors périmètre V1.

## Catégories initiales
1. Téléphones et informatique
2. Véhicules et motos
3. Immobilier
4. Maison et équipement
5. Mode et beauté
6. Services
7. Alimentation
8. Emploi et formation
9. Loisirs et divertissement

## Technologies
Flutter / Dart ; Supabase / PostgreSQL ; Supabase Auth, Storage, Realtime et RLS.

## Documentation et pilotage
- [Cahier des charges](docs/CAHIER_DES_CHARGES.md)
- [Charte graphique](docs/CHARTE_GRAPHIQUE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Décisions techniques](docs/DECISIONS_TECHNIQUES.md)
- [Feuille de route](docs/ROADMAP.md)
- [Avancement](docs/PROGRESS.md)
- [Prochaine tâche](docs/NEXT_TASK.md)
- [Automatisation](docs/AUTOMATION.md)
- [Instructions Codex](AGENTS.md)

## Qualité
Les Pull Requests et les pushs pertinents déclenchent GitHub Actions pour vérifier le formatage Dart, l'analyse statique et les tests Flutter lorsque le projet Flutter est présent.