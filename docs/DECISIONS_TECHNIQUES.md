# Décisions techniques — KIBO

| Sujet | Décision |
|---|---|
| Application | Flutter / Dart |
| Backend | Supabase + PostgreSQL |
| Authentification | Supabase Auth |
| Stockage | Supabase Storage |
| Temps réel | Supabase Realtime |
| Sécurité des données | PostgreSQL RLS |
| Marché initial | Brazzaville, République du Congo |
| Plateforme initiale | Android, puis iOS |
| Langue initiale | Français |
| Monnaie | XAF |
| Contact | WhatsApp + appel + chat intégré |
| Commentaires | Publics, avec réponses et modération |
| Publication | Immédiate après validation des champs, modération après publication |
| Photos | Maximum 8 par annonce |
| Visiteurs | Consultation publique sans compte |
| Auth | Téléphone OTP, Google OAuth, email/mot de passe |
| Paiement et livraison | Hors V1 |
| Thème | Clair au lancement |

## Points non encore validés
Fournisseur SMS et fonctionnement au Congo ; identifiant Android définitif ; schéma PostgreSQL et politiques RLS ; stratégie de visibilité Storage ; technologie de l'administration web ; exigences légales et processus de modération.

Toute nouvelle décision importante doit être ajoutée ici avec date, contexte et conséquences.

## 2026-10-30 — Initialisation Supabase (KIBO-002)

Configuration publique par `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), centralisée sans fichier de secrets ni valeur réelle versionnée. Les formats publishable et JWT anon sont acceptés ; le contrôle local ne vérifie pas la signature ni la joignabilité et ne remplace pas RLS.

Un service injectable, créé au démarrage, mémorise l’initialisation et expose le client après réussite. Configuration manquante/invalide ou erreur SDK : écran explicite sans crash ni affichage de l’exception. Pas de retry implicite : correction et relancement nécessaires. Persistance de session, rafraîchissement et liens d’authentification désactivés jusqu’à la tâche dédiée. Cette décision prépare l’accès SDK sans implémenter de fonctionnalité métier.

## 2026-10-31 — Manrope locale et thème clair (KIBO-003)

Polices statiques officielles 400/600/800 embarquées, sans package de chargement distant. Licence SIL OFL 1.1 conservée et enregistrée dans `LicenseRegistry`. Provenance et empreintes : [UI_THEME.md](UI_THEME.md).

Palette et typographie centralisées dans `core/theme/`. L’accueil garde sa structure et ses interactions ; la grille adapte colonnes et hauteur à la largeur et au texte agrandi. Les styles ne nécessitent aucune modification de la configuration ou du service Supabase. La teinte claire de sélection et les fonds illustratifs existants sont préservés ; la navigation conserve les règles de mise à l’échelle de Flutter Material.
