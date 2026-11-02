# Configuration Supabase — KIBO-002

## Paramètres publics

`SupabaseConfig` lit `SUPABASE_URL` et `SUPABASE_ANON_KEY` avec `String.fromEnvironment`. Ils doivent être injectés à la compilation via `--dart-define` ; définir des variables système seules ne suffit pas. Aucun fichier `.env` n’est chargé et aucune clé réelle n’est stockée dans le dépôt.

- URL : racine HTTPS du projet, sans identifiant, chemin API, query ni fragment. Les domaines personnalisés HTTPS sont acceptés. Les instances locales HTTP ne sont pas prises en charge par cette configuration.
- Clé : clé publique publishable ou ancienne clé anon JWT. Le nom historique du paramètre `SUPABASE_ANON_KEY` couvre les deux formats. Le SDK la reçoit via `publishableKey`.
- Les clés secrètes et les JWT portant un rôle autre que `anon` sont refusés. La lecture locale du rôle n’est pas une vérification cryptographique ; seul le serveur valide la clé et les droits.

Une clé publique embarquée dans l’application reste extractible. Les RLS et les grants minimaux côté serveur sont indispensables avant d’exposer des données. Ne jamais injecter `service_role`, une clé secrète ou un autre identifiant privilégié dans Flutter, même avec `--dart-define`.

## Lancement Windows PowerShell

La procédure de référence est [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md#configuration-publique-durable). L'URL publique confirmée est centralisée dans `config/supabase.public.json`. La clé publique peut être conservée une seule fois dans `config/supabase.local.json`, ignoré, à partir du modèle fictif. Aucun fichier contenant une clé réelle n'est créé par cette mise en place. Vérifier les sources locales avant de demander une nouvelle saisie ; ne jamais écraser un fichier existant.

```powershell
flutter pub get
flutter devices
flutter run -d <identifiant-TECNO> --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

La même injection s'applique à `flutter build apk --debug --target-platform android-arm64`. Le mécanisme historique `--dart-define` reste pris en charge ; les fichiers JSON sont une autre entrée des mêmes constantes de compilation, sans chargement de `.env` ni changement Dart. Une modification exige un nouveau build/lancement, pas un hot reload. Ne pas afficher les valeurs ni partager les logs verbeux et les artefacts de build.

## Démarrage et tests

`main` crée un `SupabaseService` unique et l’injecte dans `KiboApp`. Son Future d’initialisation est mémorisé, y compris en cas d’erreur et d’appels concurrents. Les futurs consommateurs pourront recevoir ce même service et accéder à `client` uniquement après réussite. Les repositories métier sont injectés après réussite du démarrage, sans second initialiseur SDK.

Pendant l’initialisation, un indicateur de chargement est affiché. Configuration absente/invalide : écran explicite, aucun appel SDK. Échec SDK : message générique sans exception ni valeur de clé ; relancer après correction. Réussite : accueil existant conservé. Les logs debug SDK restent désactivés. Depuis KIBO-005, la persistance/restauration de session et le rafraîchissement des jetons sont réactivés avec stockage chiffré. Depuis KIBO-006, les callbacks Android sont détectés uniquement sur `com.kibo.kibo://auth/confirm`, avec échange PKCE et stockage chiffré conservés. La configuration manuelle des Redirect URLs, du Site URL et la recette native restante sont détaillées dans [AUTHENTICATION.md](AUTHENTICATION.md). La recette KIBO-005 sans retour natif est réussie.

Les tests de configuration, d’initialisation et de widgets utilisent un initialiseur injecté, des valeurs fictives et aucun projet réel. Une initialisation réussie ne prouve pas que le serveur est joignable ou que la clé est acceptée : aucune requête métier ni sonde de table n’est exécutée. La validation distante avec les paramètres réels reste distincte des tests locaux.

Le test réel KIBO-002 a été réussi et confirmé par le propriétaire le 2026-10-31 sur TECNO CK6n : SDK initialisé, accueil affiché, `GET /auth/v1/settings` depuis le téléphone -> HTTP 401 sans clé publique et HTTP 200 avec la clé publique. Cette sonde temporaire en mémoire n’a modifié aucun fichier source et n’est pas intégrée au démarrage de l’application. Aucune valeur de clé n’a été publiée dans le chat ou Git. Voir [PROGRESS.md](PROGRESS.md) pour les preuves et limites ; les tables, RLS et parcours d’authentification restent à valider dans leurs tâches dédiées.

Android : permission Internet dans le manifeste principal, y compris pour les builds release. iOS : aucun assouplissement ATS ni callback OAuth ajouté ; HTTPS est conservé. Les autres plateformes ne sont pas validées dans cette tâche.

Référence : [initialisation officielle du SDK Flutter Supabase](https://supabase.com/docs/reference/dart/initializing).

## Préparation de la pile locale — audit du 2026-10-31

Audit de présence et de version uniquement : aucune installation, aucun démarrage/arrêt de service, aucune connexion à une base PostgreSQL ou au projet Supabase distant. Les informations de version ne constituent pas un test de fonctionnement d’une pile Supabase locale.

| Élément | Constat local |
|---|---|
| Windows | Windows 11 Professionnel 25H2, 64 bits, build 26200.9711 ; identifié par CIM et numéro de build (le libellé historique du registre indique encore Windows 10 Pro). |
| Flutter | 3.38.5 stable, version lue dans le fichier de version du SDK installé, sans lancer de résolution de dépendances. |
| Dart | 3.10.4 stable, exécutable du SDK Flutter interrogé avec `--version`. |
| Git | 2.52.0.windows.1, disponible dans le PATH. |
| Node.js / npm | v22.13.0 / 10.9.2, disponibles dans le PATH. |
| Docker / Podman | Non détectés dans le PATH ni les emplacements usuels vérifiés ; aucun service Docker détecté. |
| CLI Supabase | Non détectée dans le PATH ni les emplacements usuels vérifiés. |
| PostgreSQL / psql | Outils 13.22 présents sous `C:\Program Files\PostgreSQL\13\bin`, hors PATH. Service `postgresql-x64-13` actif, laissé intact ; version exacte du serveur non interrogée par connexion. |
| WSL | 2.5.10.0, noyau 6.6.87.2-1 ; version par défaut 2. Aucune distribution installée, selon `wsl --list --verbose`. |
| Ressources observées | Environ 15,8 Gio de RAM physique et 41,8 Gio libres sur C: au moment de l’audit. |
| Virtualisation | Hyperviseur présent selon CIM ; les indicateurs CPU de virtualisation/SLAT remontent faux. Ces résultats ne suffisent pas à conclure à une incompatibilité ou à demander un changement BIOS ; le fonctionnement du runtime reste à vérifier après une installation autorisée. |

La première interrogation CIM sans élévation et l’inventaire WSL de l’audit précédent avaient rencontré des refus d’accès. Les lectures avec les permissions nécessaires ont ici permis de relever Windows, WSL et l’absence de distribution, sans modifier leur configuration.

### Prérequis manquants et proposition minimale, non exécutée

1. Valider puis installer un runtime compatible Docker : proposition privilégiée, Docker Desktop officiel avec backend WSL 2 et conteneurs Linux. Réutiliser WSL existant ; ne pas installer Ubuntu uniquement pour ce besoin, car Docker Desktop peut être piloté depuis Windows sans distribution utilisateur. Podman reste une alternative à valider, sans installer les deux par défaut.
2. Valider une version figée et le mode d’installation de la CLI Supabase : proposition minimale, binaire Windows officiel avec emplacement utilisateur dédié. Autre option si souhaitée : dépendance npm de développement à version figée, nécessitant alors des fichiers de gestion npm supplémentaires. Aucun changement Node/npm requis pour le prérequis Node >= 20 de cette option.
3. Valider les allocations mémoire/disque, les ports et la liaison réseau locale ; vérifier les conflits avant de démarrer la pile. Ne pas réutiliser les répertoires de données, comptes ou services du PostgreSQL existant.
4. Après autorisation distincte, préparer une pile de test isolée avec versions reproductibles, données fictives et tests SQL/RLS puis HTTP/Storage. Aucune connexion ou association à un projet distant nécessaire pour les premiers tests locaux. Ne pas afficher ni copier les sorties contenant des identifiants, même générés localement.

Le fonctionnement matériel du runtime, l’espace nécessaire aux images/volumes et la compatibilité de la version retenue restent à vérifier ; aucune pile locale n’est déclarée opérationnelle. Le client Flutter actuel refuse les URL HTTP : l’intégration Flutter avec un endpoint local devra être cadrée séparément, sans affaiblir la configuration existante pendant cette préparation.

Sources officielles consultées pour cette proposition : [CLI Supabase et prérequis](https://supabase.com/docs/guides/local-development/cli/getting-started), [backend WSL 2 de Docker Desktop](https://docs.docker.com/desktop/features/wsl/). Ces sources ne constituent pas une autorisation d’installation.
