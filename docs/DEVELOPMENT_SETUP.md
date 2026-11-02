# Développement et reprise KIBO

## Source de vérité et reprise

Travailler dans le dépôt existant `C:\Users\MONSTER\Documents\WORKSPACE\KIBO`, branche attendue `main`. Lire `AGENTS.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md`, puis les documents du domaine : `ARCHITECTURE.md`, `DECISIONS_TECHNIQUES.md`, `AUTHENTICATION.md`, `PROFILE.md`, `LISTINGS.md` et `DIRECT_PUBLICATION.md` selon la tâche. Les historiques ChatGPT/Codex ne sont pas partagés automatiquement.

Commencer par `git status --short --branch`, `git branch --show-current` et `git log -1 --oneline`. Inventorier le diff et les fichiers non suivis sans afficher de valeurs sensibles. Préserver les changements existants ; ne pas réinitialiser, nettoyer ou déplacer le travail. Direct Main ne signifie pas publication automatique : aucun commit ni push sans demande explicite.

État au 2026-10-31 : KIBO-005/007 ont une recette physique réussie ; KIBO-006 attend encore la recette native après HTTP 429. Les annonces/favoris et la publication directe sont implémentés localement. Le delta SQL de publication directe n'est **pas appliqué à Supabase** : ne pas annoncer la publication réelle fonctionnelle avant audit, autorisation et recette. Le suivi détaillé reste dans PROGRESS/NEXT_TASK, sans le dupliquer ici.

## Prérequis constatés

- Windows PowerShell, Git ; Flutter 3.38.5 et Dart 3.10.4 (`C:\flutter\bin` sur ce poste).
- Android SDK et JDK Android Studio existants. ADB : `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`.
- TECNO CK6n Android 14 avec débogage USB autorisé ; choisir son identifiant courant dans `flutter devices`, ne pas présumer qu'un appareil est connecté.
- Pas de nouvelle dépendance ou installation nécessaire pour ces commandes. La pile Supabase locale complète n'est pas déclarée disponible ; voir l'audit dans [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

```powershell
flutter --version
flutter pub get
flutter devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

## Configuration publique durable

Le mécanisme Flutter existant est conservé : `SupabaseConfig.fromEnvironment()` lit les constantes de compilation `SUPABASE_URL` et `SUPABASE_ANON_KEY`. `SupabaseService` reste l'unique initialiseur. Les variables Windows seules et les fichiers `.env` ne sont pas chargés par Dart.

Sources, sans clé réelle versionnée :

| Information | Emplacement / usage |
|---|---|
| URL publique réelle | `config/supabase.public.json`, versionné. URL du projet confirmée dans les observations précédentes du propriétaire ; pas une URL inventée ni une nouvelle configuration distante. |
| Clé publique publishable ou anon | Fournie auparavant dans les invites locales puis via `--dart-define` aux builds de recette. Aucun emplacement durable détecté dans l'environnement Windows Process/User/Machine ni fichier `.env`/launch local à la vérification de cette tâche. Aucune clé extraite des caches ou APK. |
| Option durable sur ce poste | `config/supabase.local.json`, ignoré par Git, contenant uniquement `SUPABASE_ANON_KEY`. Aucun fichier avec valeur réelle n'a été créé pendant cette tâche. |
| Modèle sans valeur réelle | `config/supabase.local.example.json`, versionné, à copier une seule fois si la configuration locale manque. |

Avant toute nouvelle saisie, vérifier seulement la présence de ce fichier et des variables existantes, sans imprimer leur contenu. Si un mécanisme local fonctionne déjà, le réutiliser. Ne jamais recopier une clé dans le chat, un rapport, un script versionné ou une commande littérale dans l'historique.

### Préparation locale unique si nécessaire

1. Vérifier avec `Test-Path config/supabase.local.json`. **S'il existe, le conserver**, ne pas le remplacer.
2. S'il manque, copier le modèle avec la garde suivante :

```powershell
if (-not (Test-Path config/supabase.local.json)) {
    Copy-Item config/supabase.local.example.json config/supabase.local.json
}
git check-ignore config/supabase.local.json
```

3. Ouvrir ce fichier local dans VS Code et remplacer le texte fictif par la seule clé publique publishable/anon déjà utilisée pour KIBO, directement sur le poste. Ne pas ajouter l'URL (elle est centralisée), de jeton utilisateur, mot de passe ou clé privilégiée. Ne pas partager le contenu ni l'afficher dans un terminal. Enregistrer localement, jamais dans Git. Un fichier ignoré reste un fichier en clair : le protéger comme les autres configurations du poste ; ne pas l'envoyer avec une archive du projet.

Ne jamais saisir `service_role` ou `sb_secret_…`. Le client refuse les formats privilégiés, mais cela ne dispense pas de vérifier la nature de la clé avant de la placer dans un fichier. Les paramètres publics restent extractibles des binaires Flutter ; RLS et droits serveur assurent la protection des données.

### Lancement et build réutilisables

Depuis la racine, après la préparation unique et en remplaçant l'identifiant d'appareil :

```powershell
flutter run -d <identifiant-TECNO> --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

Les deux JSON fournissent des noms distincts ; ne pas mettre `SUPABASE_URL` dans le fichier local. `--dart-define` reste compatible pour un environnement qui possède déjà les paramètres, sans obligation de migration. Les valeurs entrent au build : redémarrage/build requis après changement, hot reload insuffisant. Sans clé valide, l'écran de configuration reste attendu ; ne pas fabriquer de valeur pour lancer l'application.

Les options ci-dessus évitent les valeurs dans les arguments de commande et leur ressaisie à chaque recette. Les fichiers locaux, les métadonnées et binaires générés sous `.dart_tool/` et `build/` restent hors Git. Éviter les journaux verbeux, dumps de configuration et captures contenant des paramètres ou liens d'authentification.

## Validation et niveaux de preuve

```powershell
dart format lib test
flutter analyze --fatal-infos
flutter test
git diff --check
```

Pour vérifier sans réécrire le format : `dart format --output=none --set-exit-if-changed lib test`. Relire les différences et les nouveaux fichiers. Examiner les noms de fichiers suivis avec `git ls-files` et vérifier les exclusions avec `git check-ignore` ; ne pas utiliser `git add -f` pour une configuration locale. Une recherche de motifs sans afficher les valeurs aide à détecter des erreurs, mais ne constitue pas une garantie absolue d'absence de secret.

- **Tests Flutter locaux** : valeurs fictives et services injectés ; pas de validation du backend réel.
- **Tests SQL locaux** : seulement sur la fixture isolée décrite dans DIRECT_PUBLICATION, jamais sur un service existant ou distant par défaut.
- **Recette TECNO** : build configuré, installation, puis scénarios du document de fonctionnalité ; distinguer observation utilisateur et automatisation. Ne pas effacer les données de l'application entre inscription PKCE et confirmation.
- **Actions distantes** : aucun SQL, migration, modification Auth/Storage/RLS, donnée de test ou requête d'écriture sans autorisation explicite. Aucun test réel pendant cette mise en place documentaire.

Rapporter les commandes et résultats réels, les scénarios non exécutés et les blocages. Ne pas assimiler les tests locaux réussis à une recette physique ou à une CI distante. Aucun commit/push par défaut.
