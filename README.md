# KIBO

**Le commerce, simplement.**

KIBO est une marketplace congolaise de produits et services. Le lancement initial cible Brazzaville, avec une extension prévue vers Pointe-Noire et d'autres villes.

## État du projet
Le projet Flutter existant et son premier accueil KIBO sont versionnés sur `main` selon le workflow Direct Main. L’accueil utilise des données de démonstration. L’initialisation Supabase est centralisée ; les paramètres publics sont fournis au build, sans clé dans le dépôt. Voir [l'avancement](docs/PROGRESS.md) et la [prochaine tâche](docs/NEXT_TASK.md).

KIBO-002 est terminée : initialisation et connexion réelle Supabase vérifiées depuis le TECNO CK6n le 2026-10-31 (HTTP 401 sans clé publique, HTTP 200 avec la clé). Le socle UI KIBO-003 intègre désormais Manrope locale et le thème clair Emerald : voir [le thème et la licence](docs/UI_THEME.md). Ces validations ne couvrent pas encore les tables, RLS ou parcours d’authentification utilisateur.

## Lancement local
Socle vérifié avec Flutter 3.38.5 / Dart 3.10.4.

```sh
flutter pub get
flutter devices
flutter run -d <identifiant-appareil>
```

Sans paramètres Supabase, l’application affiche « Configuration KIBO » et n’initialise pas le SDK. Pour accéder à l’accueil, suivre la [configuration PowerShell Supabase](docs/SUPABASE_SETUP.md).

Avant chaque commit et push :

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

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
