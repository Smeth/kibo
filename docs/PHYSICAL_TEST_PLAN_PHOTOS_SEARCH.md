# Recette physique Android — photos et recherche

Préparée le **2026-11-01**. Référence : [plan de déploiement](DEPLOYMENT_PLAN_PHOTOS_SEARCH.md). Ce document est une checklist à exécuter, pas un procès-verbal de succès. Seuls la détection, le build et l'installation dont le résultat figure en fin de document sont revendiqués. Aucun scénario manuel n'a été effectué par l'assistant.

## Périmètre autorisé aujourd'hui

- Préparer/compiler/installer l'APK local de test. Ne pas le lancer automatiquement, ne pas créer de session, annonce, réservation, objet ou favori distant.
- Le binaire de recette active `KIBO_LISTING_PHOTOS_ENABLED=true` ; cela active aussi la projection de la relation photos. Il ne configure pas le serveur et peut afficher une erreur de catalogue si la table manque. Ne pas prendre cette erreur pour une régression prouvée du rendu Android.
- **Tous les scénarios intégrés ci-dessous restent bloqués**, tant que la compatibilité réelle du backend et l'autorisation des écritures de recette ne sont pas établies. Même une connexion/refresh Auth peut écrire une session distante. Aucun test manuel connecté n'est autorisé implicitement par l'installation.
- Aucun effacement des données applicatives, aucune désinstallation et aucune modification des politiques pour provoquer une erreur. Pas de suppression automatique des données de recette en fin de test.

## Prérequis et matrice de dépendances

| Code | Précondition à faire valider avant la recette |
|---|---|
| A | Comptes de test A vendeur et B acheteur préexistants, accès saisis sur le téléphone sans partager mots de passe/liens/jetons. Autorisation explicite des écritures de recette sur un environnement identifié. Ne pas créer de compte pendant cette préparation. |
| D | Publication directe : `20261031050000_direct_listing_publication.sql` ou équivalent effectivement vérifié. Ancien INSERT draft/pending/date NULL incompatible avec le client published. Aucun déploiement effectué ici. |
| P | Photos : `20261031220517_listing_photos.sql` ou variante revue compatible avec les politiques réelles, relation `kibo_listing_photos`, PK/contraintes/grants/RLS. Le preflight original refuse toute politique Storage préexistante. |
| S | Bucket **privé** `kibo-listing-photos`, JPEG ≤4 Mio, lecture par référence et visibilité du parent, aucun upload/update/delete client direct. Chemin `<owner>/<listing>/<position>-<digest>.jpg`, positions 0..2. URLs signées 60 s. Contrat distant non vérifié par cette préparation. |
| E | Fonction `kibo-upload-listing-photo` déployée/validée séparément, JWT exigé, contrôle Auth/propriété/réservation, validation/réencodage serveur et variables réservées serveur présentes. Aucun déploiement ici ; jamais de service_role dans Flutter. |
| R | `20261031220520_catalogue_search.sql`, vecteur français, droits SELECT et index effectivement disponibles ; cache PostgREST à jour. Tri/filtres sans texte n'exigent pas le vecteur, mais cet APK exige P pour la projection photos. |
| F | Contrat favoris existant : lecture/écriture restreintes à l'utilisateur courant, annonce publiée. Persistance serveur autorisée à tester, pas seulement état local. |

Un build réussi ne valide aucun de D/P/S/E/R/F. Le schéma initial complet et le Storage distant ne sont pas contenus dans la configuration publique locale. Consulter le plan pour audit readonly, arrêt sur collision, fenêtre de verrou et retour arrière conservant les données. Ne pas exécuter ses commandes de déploiement pendant la recette préparatoire.

## Jeu fictif et preuves

Préparer sur le téléphone, uniquement avec accord, trois images synthétiques sans personne, adresse, écran privé ou GPS : **A rouge**, **B verte**, **C bleue**, noms distincts et marquages visibles. JPEG, PNG, WebP ; image portrait orientée pour contrôle du redressement. Préparer séparément un fichier source >20 Mio, une image >24 MP et un fichier corrompu. Si le sélecteur Android masque un format invalide, noter « non accessible via le sélecteur », pas « refus applicatif vérifié ».

Jeu serveur à préparer **ultérieurement et seulement après autorisation** :

| Repère | Titre | Description | Prix XAF | Ville / catégorie |
|---|---|---|---|---|
| T1 | Test KIBO 0111 mangue | Annonce fictive, mot témoin parapluie | 1000 | Brazzaville / catégorie active C1 |
| T2 | Test KIBO 0111 citron | Annonce fictive, mot témoin bicyclette | 2000 | Brazzaville / C1 |
| T3 | Test KIBO 0111 goyave | Annonce fictive, mot témoin tambour | 2000 | Pointe-Noire / autre catégorie C2 |

T1 sans photo puis une **autre annonce identifiée T4** avec les trois images : le flux ne permet pas d'éditer les photos déjà publiées. Relever ID et heure de publication serveur de chaque annonce via une lecture autorisée, sans exporter de données tierces. Pour pagination, il faut au moins **21 annonces autorisées correspondant aux mêmes critères**, dont les IDs/ordres sont connus ; ne pas créer ces lignes ici. En l'absence de jeu suffisant : scénario bloqué.

Pour chaque scénario : renseigner `NON EXÉCUTÉ / RÉUSSI / ÉCHEC / BLOQUÉ`, appareil/version Android, version et SHA-256 APK, date/heure/fuseau Africa/Lagos, compte A/B (alias uniquement), préconditions vérifiées, étapes et résultat réellement observé. Captures avant/après recadrées ; IDs d'annonces fictives et liste ordonnée des résultats ; diagnostic HTTP/code expurgé si accessible. Ne recueillir ni JWT, URL signée complète, numéro, email, galerie privée ni journal brut. Une capture de confirmation seule ne prouve pas la date serveur ni l'isolation RLS.

## Checklist dans l'ordre d'exécution futur

### 01 — Création sans photo et publication immédiate

- **Préconditions :** A, D, P (APK photos activées), réseau disponible, catégorie C1 et profil test vérifiés ; aucune annonce T1 déjà créée par la tentative.
- **Actions Android :** ouvrir KIBO, se connecter localement sous A ; onglet **Publier**. Saisir T1 ci-dessus, Type Produit, Ville Brazzaville, Quartier vide. Ne sélectionner aucune photo. Appuyer une seule fois sur **Publier l'annonce** (libellé typographique « Publier l’annonce »). Observer **Publication…** puis retour Accueil. Utiliser l'icône **Actualiser les annonces**, ouvrir la carte T1.
- **Attendu :** bouton protégé pendant la requête, confirmation **Annonce publiée.**, annonce visible immédiatement et détail correct, absence de photo gérée. Lecture autorisée : status published, published_at non NULL, imposée par serveur. Aucun repli pending ni doublon automatique. Si 42501, arrêter ce parcours et documenter le blocage D ; ne pas multiplier les essais.
- **Preuves :** capture formulaire/confirmation/carte/détail, ID T1 et lecture status/date/seller expurgée ; heure de soumission pour comparaison. **Statut : NON EXÉCUTÉ.**

### 02 — Sélection, aperçu, ordre et suppression avant publication

- **Préconditions :** A, D, P, images synthétiques disponibles, formulaire neuf T4 ; ne pas encore soumettre.
- **Actions :** **Publier → Ajouter des photos** ; choisir A rouge et B verte dans le sélecteur Android, valider. Observer **Préparation des photos** puis les deux aperçus. Appuyer flèche haut **Avancer la photo 2** : B devient principale. Appuyer **Supprimer la photo 2** : A disparaît. Ajouter C puis A, vérifier ordre B/C/A. À trois photos, vérifier que l'ajout est désactivé ; retirer puis resélectionner une même image pour contrôler l'absence de doublon. Annuler une ouverture du sélecteur sans changer les aperçus. Revenir à B/C/A pour le scénario 03.
- **Attendu :** ordre visible, première annoncée principale, flèches aux extrémités désactivées, suppression immédiate du brouillon seulement, maximum trois. Redressement correct du portrait. Pas de publication pendant la sélection. Ne pas promettre d'édition après upload.
- **Preuves :** captures avant/après ordre/suppression, nombre et marquages des images, taille/type des fichiers fictifs. **Statut : NON EXÉCUTÉ.**

### 03 — Publication avec photos et affichage catalogue/détail

- **Préconditions :** A, D, P, S, E ; scénario 02 préparé, T4 renseignée avec un titre distinct et 1500 XAF.
- **Actions :** soumettre T4 une fois ; attendre sans quitter le formulaire. Après confirmation, ouvrir Accueil, actualiser puis ouvrir T4. Faire défiler verticalement le détail pour voir toutes les photos (pas de carrousel prévu). Revenir au catalogue, puis rouvrir après plus de 60 s ; en cas d'image cassée utiliser **Recharger la photo**.
- **Attendu :** carte avec B principale ; détail B/C/A dans cet ordre, texte/prix corrects et chargements distincts ; URL privée renouvelable, pas d'URL publique. Annonce créée avant les uploads : une visibilité transitoire sans photos est possible. Une photo déjà mise en cache après 60 s ne prouve pas le renouvellement de signature ; la preuve serveur doit être expurgée.
- **Preuves :** ID T4, captures carte et trois photos, temps de chargement, metadata positions/paths et objets correspondants en lecture autorisée, sans URL signée. **Statut : NON EXÉCUTÉ.**

### 04 — Recherche par titre puis description

- **Préconditions :** P, R, T1–T3 visibles ; onglet **Recherche** et réseau disponible.
- **Actions :** **Effacer les critères**, saisir `mangue` dans **Rechercher une annonce**, toucher **Rechercher** (ou icône **Lancer la recherche**). Relever IDs ; remplacer par `parapluie` et soumettre. Puis rechercher `Test KIBO 0111`. Ne pas supposer une mise à jour à chaque frappe : soumettre explicitement.
- **Attendu :** T1 présente par mot du titre et par mot présent uniquement dans la description. Recherche serveur sur annonces publiées, chargement puis résultats ; aucun ancien résultat réaffiché par une réponse tardive. La recherche française n'est pas une recherche arbitraire de sous-chaîne ; relever le comportement réel des accents/pluriels séparément.
- **Preuves :** capture de chaque terme et liste IDs, état chargement/résultat ; inspection technique facultative expurgée. **Statut : NON EXÉCUTÉ.**

### 05 — Catégorie, ville, fourchette et combinaison

- **Préconditions :** P, jeu T1–T3 et R si texte combiné.
- **Actions :** effacer ; développer **Filtres et tri**. Choisir C1 dans **Catégorie**, Ville `Brazzaville`, **Prix minimum (XAF)** `1000`, maximum `2000`, puis **Rechercher**. Ajouter texte `citron` et rechercher. Tester min=max `2000`. Saisir ensuite min `2000` et max `1000`, puis un prix négatif ; soumettre. Comparer enfin `brazzaville` et `Brazzaville`.
- **Attendu :** critères combinés en AND, bornes inclusives, T1/T2 puis T2 seulement dans le jeu témoin. Fourchette inversée/prix invalide signalés sans recherche acceptée. Ville exacte et sensible à la casse actuellement : différence éventuelle des résultats attendue, pas de normalisation inventée. D'autres annonces peuvent correspondre : comparer le jeu témoin, pas un total supposé.
- **Preuves :** captures critères/erreurs, IDs et prix affichés, absence d'annonce hors critères. **Statut : NON EXÉCUTÉ.**

### 06 — Tri date et prix

- **Préconditions :** P ; R si texte, jeu témoin avec dates serveur distinctes et prix égaux T2/T3 ; ordre de référence relevé.
- **Actions :** effacer, appliquer le terme commun si R ; ouvrir **Filtres et tri → Trier par**, choisir successivement **Plus récentes**, **Prix croissant**, **Prix décroissant**, toucher **Rechercher** après chaque choix. Réactualiser chaque résultat.
- **Attendu :** dates décroissantes ; prix croissants puis décroissants ; égalités stables selon le tri secondaire date puis ID du repository. Ne pas déduire l'ordre de l'horloge Android. Aucun résultat non publié.
- **Preuves :** liste ordonnée IDs/prix/date serveur et captures premier/dernier éléments pour chaque tri. **Statut : NON EXÉCUTÉ.**

### 07 — Pagination, actualisation et réinitialisation

- **Préconditions :** P, R si texte ; ≥21 annonces du jeu autorisé, pas de publications concurrentes durant la mesure.
- **Actions :** appliquer des critères donnant >20 résultats et un tri déterministe. Descendre au bas, toucher **Voir plus** une fois, observer **Chargement…**, noter les nouveaux IDs. Répéter jusqu'à fin. Remonter via défilement, toucher **Actualiser les annonces**, puis changer un critère. Enfin **Effacer les critères**.
- **Attendu :** pages de 20 au plus, concaténation sans doublon/manquant sur jeu stable ; fin sans boucle. Actualiser/changer les critères revient à la première page ; effacement vide texte/catégorie/ville/prix et restaure **Plus récentes** avec catalogue complet publié. Changement concurrent des annonces peut déplacer les pages par offset : noter cette limite, ne pas garantir un snapshot.
- **Preuves :** IDs par page avant/après, capture **Voir plus** et disparition finale, critères remis à zéro. Sans ≥21 lignes : **BLOQUÉ**, jamais déclaré réussi par simple absence du bouton. **Statut : NON EXÉCUTÉ.**

### 08 — Favoris, redémarrage et isolation A/B

- **Préconditions :** A, P, S si photos, F ; T4 publiée ; écritures favoris explicitement autorisées.
- **Actions :** sous B, ouvrir T4 depuis catalogue, toucher le cœur ; ouvrir **Favoris** puis détail, vérifier la cohérence. Actualiser via le contrôle disponible. Fermer réellement KIBO depuis les apps récentes et relancer ; si Android conserve le processus, effectuer **Paramètres → Applications → KIBO → Forcer l'arrêt**, jamais **Effacer les données**. Revenir Favoris ; retirer le cœur, relancer et revérifier. Changer ensuite de compte via la déconnexion normale : A ne doit pas hériter du favori B. Avec accord, réajouter sous B puis repasser sous A pour comparaison.
- **Attendu :** favori B persistant après nouvelle lecture et redémarrage, retrait persistant, état partagé carte/détail/Favoris ; pas de fuite de la liste B à A. Ne pas présenter cette comparaison UI comme preuve d'interdiction d'UPDATE/DELETE arbitraire RLS : ces refus sont couverts localement et requièrent une recette technique autorisée distincte.
- **Preuves :** captures sous alias B avant/après relance et sous A, ID T4, lecture favorite owner expurgée si autorisée. **Statut : NON EXÉCUTÉ.**

## Erreurs et cas limites (après validation des prérequis)

### E1 — Réseau indisponible

- **Préconditions :** environnement autorisé ; accès aux réglages rapides Android, aucun autre transfert important. Pour reprise upload : D/P/S/E et formulaire photos vivant.
- **Actions :** activer mode avion et couper aussi le Wi-Fi ; actualiser catalogue, rechercher puis ouvrir un détail non caché. Rétablir le réseau et **Réessayer**. Sur une publication distincte autorisée, couper avant soumission pour refus réseau ; si panne après création/upload, garder le formulaire et choisir **Réessayer les photos** après rétablissement.
- **Attendu :** erreur lisible distincte d'un résultat vide, fin du chargement, pas de crash ni succès fictif. Après création confirmée, reprise photos avec même ID et mêmes chemins ; aucun second INSERT annonce. Pour résultat INSERT incertain, vérifier l'existence en lecture avant tout nouvel essai. Pas de reprise durable garantie si le formulaire est fermé.
- **Preuves :** captures état réseau/erreur/reprise recadrées, ID avant/après, nombre de réservations/objets en lecture autorisée ; rétablir l'état réseau initial. **Statut : NON EXÉCUTÉ.**

### E2 — Image trop volumineuse, invalide ou accès annulé

- **Préconditions :** formulaire neuf sous A, fichiers synthétiques >20 Mio, >24 MP, corrompu ; n'inclure aucun fichier privé.
- **Actions :** **Ajouter des photos**, essayer chaque fichier séparément ; annuler le sélecteur. Si un fichier n'est pas sélectionnable, noter le filtrage système. Comparer avec une source valide qui se compresse.
- **Attendu :** rejet lisible, pas de faux aperçu ni upload ; formulaire et photos antérieures conservés. Source ≤20 Mio/24 MP ; sortie JPEG ≤1600 px/4 Mio. Le client réencode : choisir une source >4 Mio n'est pas, à lui seul, un test du refus serveur >4 Mio. Les entrées serveur malformées restent un test technique distinct.
- **Preuves :** type/dimensions/taille du fichier fictif et message exact, capture absence d'ajout. **Statut : NON EXÉCUTÉ.**

### E3 — Refus Storage ou fonction indisponible

- **Préconditions :** panne déjà présente ou environnement isolé avec injection contrôlée préparée et autorisée séparément. **Ne pas modifier les politiques/bucket du projet réel pour provoquer le refus.** Sinon marquer le scénario bloqué.
- **Actions :** soumettre une annonce avec photos uniquement sur cet environnement autorisé ; relever le message. Après correction séparément autorisée, même formulaire → **Réessayer les photos**. Tester aussi **Recharger la photo** sur une lecture refusée connue.
- **Attendu :** aucune confirmation complète tant que photos incomplètes ; annonce éventuellement déjà publiée signalée, champs/ordre verrouillés après création, retry sans recréation. Refus de lecture sans fuite de fichier privé. Aucune suggestion de rendre le bucket public ou d'intégrer une clé serveur.
- **Preuves :** message UI, code HTTP expurgé et ID stable ; pas de journal contenant token/URL signée. L'ancien test Edge simulé ne prouve pas ce refus physique. **Statut : NON EXÉCUTÉ.**

### E4 — Aucun résultat

- **Préconditions :** P/R disponibles, réseau fonctionnel.
- **Actions :** ouvrir **Recherche**, saisir un mot témoin improbable `zebulonkiboabsent0111`, soumettre, puis **Effacer les critères**.
- **Attendu :** **Aucun résultat pour ces critères.**, pas de spinner permanent ni erreur réseau ; catalogue restauré après effacement. Si catalogue entier vide sans critères, message distinct **Aucune annonce publiée pour le moment.**
- **Preuves :** capture terme/état vide, catalogue après effacement. **Statut : NON EXÉCUTÉ.**

### E5 — Session expirée et visiteur

- **Préconditions :** compte fictif et environnement autorisé ; expiration réelle contrôlée sans modifier la durée JWT distante ni manipuler des secrets. Un access token arrivé à échéance peut être rafraîchi automatiquement : cela n'est pas une session irrécupérable.
- **Actions :** tester d'abord déconnexion normale puis **Publier** et cœur : connexion nécessaire, aucune écriture. Séparément, si l'expiration irrécupérable peut être reproduite sur l'environnement autorisé, revenir sur un brouillon et tenter l'action ; observer le retour Auth, puis reconnecter sous le même compte seulement après accord. Ne pas révoquer des comptes réels et ne pas changer l'heure système pour simuler ce cas.
- **Attendu :** visiteur invité à se connecter ; refus expiré sans publication/favori annoncé réussi ni fuite d'un compte à l'autre. Si refresh transparent réussi, noter « renouvellement observé », pas « refus expiré testé ». Si aucune méthode contrôlée disponible : cas expiré **BLOQUÉ**.
- **Preuves :** écran connexion/message, alias/heure, code expurgé éventuel ; jamais de jeton ni lien de connexion. **Statut : NON EXÉCUTÉ.**

### E6 — Petit écran, accessibilité et reprise Android

- **Préconditions :** images fictives, comptes de test ; pas d'écriture nécessaire pour le rendu du formulaire déjà accessible.
- **Actions :** agrandir texte Android à environ 150 %, afficher clavier dans filtres et publication, faire défiler jusqu'aux boutons ; utiliser TalkBack pour flèches, suppression, cœur et rechargement. Annuler le sélecteur, mettre l'app en arrière-plan et revenir. Reprise après destruction d'activité à tester seulement sur environnement/appareil de test préparé, sans modifier arbitrairement les options développeur du téléphone personnel.
- **Attendu :** boutons atteignables, libellés lisibles, pas de débordement ; brouillon cohérent. Une récupération native de photos ne doit jamais restituer celles du compte A sous B. La fermeture du formulaire peut perdre le brouillon/retry en mémoire : limite connue à consigner.
- **Preuves :** captures recadrées, taille texte/résolution/version Android, observations TalkBack et identité de session par alias. **Statut : NON EXÉCUTÉ.**

## Couverture automatisée examinée et limites

`test/listings/direct_publication_flow_test.dart` (A/B et favoris simulés), `publication_test.dart`, `listing_repository_test.dart`, `photo_publication_test.dart` (ordre/suppression/retry même annonce), `listing_photos_test.dart` (formats/limites), `listing_photo_widgets_test.dart`, `catalogue_search_test.dart`, `catalogue_test.dart` (pagination/vide/erreur) et les trois suites `test/favorites/`. Assertions `test/sql/` et tests Edge du précédent audit : preuves locales historiques seulement. Aucun de ces tests ne valide le sélecteur système, le téléphone, les vrais grants/URLs/JWT ou la persistance distante.

## Préparation matérielle et commandes

ADB utilisé : `C:\Users\MONSTER\AppData\Local\Android\sdk\platform-tools\adb.exe`.

```powershell
adb devices -l
adb -s H6929CK6NU012345 get-state
adb -s H6929CK6NU012345 shell getprop ro.product.model
adb -s H6929CK6NU012345 shell getprop ro.build.version.release
flutter build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true
adb -s H6929CK6NU012345 install -r C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk
```

L'installation de test est autorisée par la demande du 2026-11-01. Ne pas utiliser uninstall/clear ni démarrage automatique. Configuration locale ignorée, nature publique contrôlée sans imprimer la valeur. L'APK précédent est archivé sous `.dart_tool/kibo-verifications/` avant compilation. Le wrapper Gradle peut émettre les paramètres de compilation encodés : garder les journaux locaux et ne pas les joindre aux preuves. Les paramètres client sont publics, aucune clé serveur admise.

## Résultats réellement obtenus le 2026-11-01

| Contrôle exécuté | Résultat |
|---|---|
| `git status --short --branch`, `git remote -v`, inventaire SHA-256 des fichiers suivis et non ignorés | main ; travail local préexistant inventorié/conservé. Aucun fetch, commit ou push. |
| `git check-ignore -v config/supabase.local.json` et contrôle en mémoire de la nature de clé | Fichier ignoré, clé publique présente, aucune valeur imprimée par ce contrôle ; configuration inchangée. |
| `adb devices -l`, `get-state`, `getprop ro.product.model`, `getprop ro.build.version.release` | H6929CK6NU012345, état device, TECNO CK6n, Android 14. |
| `adb ... shell dumpsys package com.kibo.kibo` filtré | Version précédemment installée 1.0.0 (1), dernière mise à jour relevée 2026-10-31 22:11:28 ; aucun changement de package effectué. |
| Commande build ci-dessus, avec Flutter local et `FLUTTER_SUPPRESS_ANALYTICS=true`, `CI=true` | **Code 0**, assembleDebug 286,3 s, photos activées. Aucun lancement de l'app. |
| `Get-Item`, `Get-FileHash`, `aapt dump badging` filtré | APK **110 696 428 octets**, com.kibo.kibo 1.0.0 (1), debuggable, minSdk 24, targetSdk 36, arm64-v8a présent. |
| `dart format --output=none --set-exit-if-changed lib test` | Code 0, 58 fichiers, aucun changement. |
| `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true test/listings test/favorites --reporter expanded` | **Code 1 : 38 réussis, 1 échec**. `direct_publication_flow_test.dart:36`, premier pumpAndSettle, timeout. Aucun fichier modifié pour masquer l'échec. |
| `git diff --check`, inventaire final | Contrôle du diff réussi (avertissements LF/CRLF préexistants) ; aucun fichier applicatif ou migration changé, aucun fichier préexistant supprimé. |

APK : `C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk`.

SHA-256 : `775B66D245F21A8F479BD93EB3CC9929D9775687C66F23086042B8819DF330B2`.

Ancien APK conservé : `.dart_tool/kibo-verifications/app-debug-before-physical-prep-1238d3a0f7974e4c815693184ad5cc29.apk`, SHA-256 `781D42361722E8121B5A601FC75552DDA76301CF0F7AD41BE17E51DB638AF511`. Le build génère un nouvel artefact, sans supprimer cette archive ni modifier les sources.

**État historique avant correction : installation suspendue, avis utilisateur demandé.** Bien que la demande autorise l'installation de test, `docs/WORKFLOW.md` impose : « En cas de conflit, test échoué ou changement inattendu, s'arrêter et demander l'avis de l'utilisateur. » Le test avec flag activé avait échoué. L'utilisateur a ensuite choisi de diagnostiquer et corriger avant installation ; résultat actuel ci-dessous. Ne pas assimiler ce timeout à une panne Android ou RLS démontrée.

Diagnostic local auxiliaire pendant l'attente Gradle : lecture des processus/journal de daemon et `jstack.exe 16960` vers un fichier ignoré ; aucune action sur Supabase. Build finalement terminé sans modification corrective. Toutes les étapes 01–08/E1–E6 restent **NON EXÉCUTÉES**. Ne pas collecter des preuves physiques inventées à partir de la réussite du build ou des tests simulés.

### Correction du test puis installation — état actuel du 2026-11-01

Timeout reproduit en lançant seul `direct_publication_flow_test.dart` avec le flag true : code 1. Il survient au pumpAndSettle après ouverture de **Publier** (la mention antérieure « premier pumpAndSettle » ne localisait pas correctement l'ouverture). Le test injectait Auth/annonces/favoris, mais conservait le sélecteur natif par défaut. Photos activées, le formulaire déclenche la récupération Android, non simulée dans ce test widget.

Correction limitée à `test/listings/direct_publication_flow_test.dart` : injection explicite des services photo fictifs **activés**, pour la première application et sa recréation ; récupération vide immédiate enregistrée pour A puis B. Sélection/upload/lecture inattendus provoquent une erreur dans ces services. Assertions catalogue/détail/persistance/isolation/retrait conservées, vérification de la récupération et de la disponibilité de l'éditeur ajoutée. Aucun timeout augmenté, aucun skip, aucun flag désactivé. Une première assertion supplémentaire était placée avant l'ouverture du formulaire : elle a été replacée après ouverture avant la validation finale. Aucun changement au code livré ni SQL.

| Commande / contrôle de reprise | Résultat |
|---|---|
| `dart format test/listings/direct_publication_flow_test.dart` | Réussi ; dernier passage 0 changement. |
| `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true test/listings/direct_publication_flow_test.dart --reporter expanded` | Code 0, **1 test réussi** après correction. |
| `flutter analyze --no-pub --fatal-infos` | Code 0, aucune anomalie, 77,8 s. |
| `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --reporter expanded` | Code 0, **106 tests réussis**, environ 25 s. |
| `flutter test --no-pub --reporter expanded` | Code 0, **106 tests réussis**, environ 30 s. |
| `Get-FileHash` APK puis `adb -s H6929CK6NU012345 get-state` | Empreinte identique à celle ci-dessus, téléphone device. Pas de rebuild nécessaire : seul un fichier de test a changé. |
| `adb -s H6929CK6NU012345 install -r <APK exact ci-dessus>` | **Success**, code 0 ; remplacement du package sans désinstallation ni effacement demandé. |
| `adb ... shell dumpsys package com.kibo.kibo` filtré | Version 1.0.0 (1), dernière mise à jour relevée 2026-11-01 02:35:00, heure locale Africa/Lagos. |

L'arrêt après échec est levé par la correction validée ; installation effectuée dans l'autorisation de recette initiale et après le choix utilisateur de corriger d'abord. Aucun lancement via ADB ni geste dans l'app. Les préconditions backend restent non vérifiées : **tous les scénarios fonctionnels demeurent NON EXÉCUTÉS**. Aucun changement Supabase distant, commit ou push.
