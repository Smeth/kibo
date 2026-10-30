# Configuration Supabase — KIBO-002

## Paramètres publics

`SupabaseConfig` lit `SUPABASE_URL` et `SUPABASE_ANON_KEY` avec `String.fromEnvironment`. Ils doivent être injectés à la compilation via `--dart-define` ; définir des variables système seules ne suffit pas. Aucun fichier `.env` n’est chargé et aucune clé réelle n’est stockée dans le dépôt.

- URL : racine HTTPS du projet, sans identifiant, chemin API, query ni fragment. Les domaines personnalisés HTTPS sont acceptés. Les instances locales HTTP ne sont pas prises en charge par cette configuration.
- Clé : clé publique publishable ou ancienne clé anon JWT. Le nom historique du paramètre `SUPABASE_ANON_KEY` couvre les deux formats. Le SDK la reçoit via `publishableKey`.
- Les clés secrètes et les JWT portant un rôle autre que `anon` sont refusés. La lecture locale du rôle n’est pas une vérification cryptographique ; seul le serveur valide la clé et les droits.

Une clé publique embarquée dans l’application reste extractible. Les RLS et les grants minimaux côté serveur sont indispensables avant d’exposer des données. Ne jamais injecter `service_role`, une clé secrète ou un autre identifiant privilégié dans Flutter, même avec `--dart-define`.

## Lancement Windows PowerShell

Depuis le dépôt, saisir uniquement les valeurs publiques du projet dans les invites, sans les écrire dans un script ou un fichier versionné :

```powershell
flutter pub get
flutter devices
$deviceId = Read-Host 'Identifiant de l’appareil affiché par flutter devices'
$env:SUPABASE_URL = Read-Host 'URL HTTPS du projet Supabase'
$env:SUPABASE_ANON_KEY = Read-Host 'Clé publique publishable ou anon (jamais une clé privilégiée)'
flutter run -d $deviceId --dart-define="SUPABASE_URL=$env:SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY"
Remove-Item Env:SUPABASE_URL, Env:SUPABASE_ANON_KEY
```

La même injection s’applique à `flutter build apk`. Une modification des paramètres nécessite un nouveau lancement/build, pas un simple hot reload. Ne pas copier les paramètres effectifs dans des logs, tickets ou captures. `Read-Host` évite d’inscrire une valeur littérale dans l’historique des commandes ; les arguments de processus restent des paramètres publics visibles localement.

## Démarrage et tests

`main` crée un `SupabaseService` unique et l’injecte dans `KiboApp`. Son Future d’initialisation est mémorisé, y compris en cas d’erreur et d’appels concurrents. Les futurs consommateurs pourront recevoir ce même service et accéder à `client` uniquement après réussite. Aucun repository métier n’est créé.

Pendant l’initialisation, un indicateur de chargement est affiché. Configuration absente/invalide : écran explicite, aucun appel SDK. Échec SDK : message générique sans exception ni valeur de clé ; relancer après correction. Réussite : accueil existant conservé. Les logs debug SDK sont désactivés. La persistance/restauration de session, le rafraîchissement des jetons et la détection de liens d’authentification sont désactivés pour cette étape ; ils devront être revus dans une tâche d’authentification dédiée.

Les tests de configuration, d’initialisation et de widgets utilisent un initialiseur injecté, des valeurs fictives et aucun projet réel. Une initialisation réussie ne prouve pas que le serveur est joignable ou que la clé est acceptée : aucune requête métier ni sonde de table n’est exécutée. La validation distante avec les paramètres réels reste distincte des tests locaux.

Android : permission Internet dans le manifeste principal, y compris pour les builds release. iOS : aucun assouplissement ATS ni callback OAuth ajouté ; HTTPS est conservé. Les autres plateformes ne sont pas validées dans cette tâche.

Référence : [initialisation officielle du SDK Flutter Supabase](https://supabase.com/docs/reference/dart/initializing).
