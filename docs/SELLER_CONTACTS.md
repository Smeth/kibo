# Profil vendeur et contacts — MVP, 2026-11-01

Mise à jour du 2026-11-02 : boutons espacés, pictogramme WhatsApp officiel, Message direct avec écran de connexion puis chat depuis le profil vendeur et le détail. [Implémentation, tests et limites](SELLER_SEARCH_OPTIONAL_PRICE.md). Aucun changement du contrat de coordonnées privées.

Trois tâches implémentées : profil public minimal, préférences volontaires de contact et ouverture WhatsApp/appel après connexion. Aucun numéro d'authentification récupéré ou recopié.

## Profil et navigation

La fiche d'une annonce expose désormais son seller_id pour ouvrir le profil public du vendeur. C'est un identifiant de profil, jamais une coordonnée de contact. La projection des annonces exclut toujours téléphone/WhatsApp, attributs et motifs de rejet. Le profil sélectionne seulement id, full_name et city dans profiles. Les droits réels ont été vérifiés pour anon et authenticated : ces trois colonnes sont autorisées, bio ne l'est pas. La présentation n'est donc ni lue ni affichée ; aucune permission élargie pour la rendre publique. Nom vide : label « Vendeur KIBO », pas de fausse identité. L'édition nom/ville existante reste disponible.

Catalogue et Favoris transmettent le repository et le lanceur au détail. « Voir le vendeur et le contacter » conserve AuthScope. Profil ouvre « Mes coordonnées de contact » pour le compte courant. Le formulaire est définitivement invalidé lors d'un changement A/B/A ; un listener de session direct évite les événements coalescés entre deux rendus.

## Coordonnées privées et consentement

Les deux numéros de contact sont distincts des identifiants Auth et peuvent différer. Appels et WhatsApp sont désactivés par défaut, même si un numéro est saisi. L'activation explique que les membres connectés pourront voir le numéro dans l'application ouverte. Désactivation : arrêt des futures lectures du canal ; une coordonnée déjà obtenue ou copiée par un membre ne peut pas être rappelée.

Normalisation espaces/parenthèses/tirets puis syntaxe internationale + et 2–15 chiffres, premier chiffre non nul. Il s'agit d'une validation de format E.164, pas de l'existence du numéro, de son pays ou de sa propriété. Aucun SMS de vérification, badge de vendeur vérifié ou paiement.

Lecture privée owner_id courant ; INSERT nouveau ou UPDATE sur owner_id et updated_at précédemment lus, pas d'upsert écrasant un conflit. Champs envoyés limités aux deux numéros et aux deux consentements. L'INSERT ajoute le seul propriétaire issu de la session ; dates gérées par le serveur. Erreur de lecture : sauvegarde bloquée ; erreur de sauvegarde : texte conservé, pas de faux succès ni retry automatique. Doubles envois et retour pendant sauvegarde bloqués.

## Contrat SQL et déploiement réel

Proposition locale `supabase/proposals/seller_contacts.sql`, testée sur un nouveau PostgreSQL isolé avec `scripts/Test-OwnerManagementSql.ps1 -Suite Contacts -Port 55482`, code 0, cluster arrêté. Dossier conservé : `.dart_tool/owner-sql-1874a6c3c70c4e4f96044908a62abbe6`. Fixtures fictives exclusivement ; aucun appel/message.

Après présentation du fichier et des résultats, l'utilisateur autorise explicitement « Oui, appliquer ce contrat testé ». Migration **20261101044111 / kibo_seller_contacts** appliquée via MCP, success=true, sur KIBO PostgreSQL 17.11. Aucun numéro ni réglage existant modifié. Table créée vide ; contrôle post-déploiement : 0 ligne à cet instant.

Table publique kibo_seller_contacts, RLS active, SELECT/INSERT/UPDATE pour le propriétaire uniquement ; droits issus des defaults neutralisés puis droits de colonnes limités. owner_id et updated_at non modifiables par le client, aucun DELETE client. Numéros et indicateurs contraints côté serveur.

Le schéma kibo_contact_private porte la lecture privilégiée (SECURITY DEFINER, search_path vide), exigeant auth.uid non nul, listing_id exact, annonce published et canal activé. Aucun vendeur libre en argument. La fonction publique kibo_listing_seller_contact est SECURITY INVOKER, appelle ce helper et n'est exécutable que par authenticated. Aucun EXECUTE PUBLIC/anon sur ces lectures, aucun numéro dans profiles. Contrôles distants : RLS=true, anon SELECT=false/RPC=false, authenticated RPC=true, UPDATE owner/date=false, definer public=false. Conseiller sécurité après déploiement : seul avertissement préexistant sur protection des mots de passe compromis ; Auth non modifié. Ce résultat n'est pas un audit exhaustif.

Le fichier SQL est conservé comme source de cette migration, en-tête historique « proposition » compris. Ne pas le rejouer : son preflight refuse de remplacer un contrat existant. Aucune suppression de table/données ni retour arrière automatique. Une désactivation d'urgence privilégierait la révocation des deux EXECUTE de lecture, avec autorisation opérateur distincte, en conservant les coordonnées privées.

## Applications externes

Chaque clic authentifié relit les canaux via la fonction par annonce ; aucun numéro persistant ni journalisé dans Flutter. Session vérifiée avant/après lecture et avant ouverture, réponse tardive ignorée après changement de compte. Appel : tel:+… ; WhatsApp : https://wa.me/chiffres, sans message envoyé automatiquement. Une application compatible s'ouvre en mode externe ; HTTPS peut être pris en charge par le navigateur. Absence/échec : message français, aucun faux succès.

url_launcher 6.3.2 déjà présent transitivement est déclaré directement, version conservée ; pub get --offline réutilise le cache. Aucun téléchargement requis, aucune nouvelle permission Android d'appel, pas de canLaunchUrl ni de requête de visibilité ajoutée. Recette physique Android/iOS encore nécessaire ; aucun contact réel, APK ou installation pendant ce lot.

## Tests et limites

Inventaire du lot : nouveaux `lib/features/seller/seller_repository.dart`, `seller_page.dart`, `contact_preferences_page.dart` ; intégration dans `lib/main.dart`, `lib/features/auth/profile_page.dart`, `lib/features/listings/listing_models.dart`, `listing_repository.dart`, `listing_feed.dart`, `listing_detail_page.dart` et `lib/features/favorites/favorites_page.dart`. Dépendance directe dans `pubspec.yaml`/`pubspec.lock`. SQL `supabase/proposals/seller_contacts.sql`, assertions `test/sql/seller_contacts_assertions.sql`, lanceur `scripts/Test-OwnerManagementSql.ps1`. Tests `test/seller/seller_repository_test.dart`, `seller_widgets_test.dart` et adaptation `test/listings/listing_repository_test.dart`. Documentation : README, SELLER_CONTACTS, MVP_STATUS, PROGRESS et NEXT_TASK. Les autres changements préexistants sont conservés.

Commandes de validation : `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --no-pub --fatal-infos`, `flutter test --no-pub --reporter expanded`, variante avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true`, `git diff --check` et lanceur SQL Contacts ci-dessus. Flutter exécuté via le snapshot du SDK local pour contourner le wrapper Windows.

Tests HTTP fictifs : projection publique, lecture propre, refus de session/B, champs d'INSERT/UPDATE et conflit, RPC limitée à l'annonce, formats et refus d'URL injectée. Widgets : visiteur sans lecture de numéro, clics explicites, application absente, changement de compte pendant RPC, consentements initiaux désactivés, validation, erreurs/saisies, A/B/A, double sauvegarde/retour, navigation détail et 320 px/texte 150 %. Contrôles supplémentaires du chargement en erreur et de l'absence de consentement. Résultats finaux consignés dans PROGRESS.

Assertions SQL : aucun canal sans consentement, seuls canaux activés retournés ; lecture/modification/usurpation A/B refusées, visiteur et identité absente refusés, annonce non publiée masquée, numéro invalide rejeté, propriétaire/date protégés, consentement retiré et RLS/ACL vérifiés. Aucun compte réel de recette ni appel serveur authentifié avec coordonnées réelles effectué.
