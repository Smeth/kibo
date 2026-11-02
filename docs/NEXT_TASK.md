## Consolidation et reprise — 2026-11-02

Le propriétaire a autorisé commit et push sur origin/main. Travail local complet préparé pour conservation, commit distant 2a3b4fb intégré sans conflit. CI enrichie : couverture des assets/outils/contrats serveur, variantes Flutter photos et tests Node du worker. État de référence : [MVP_STATUS.md](MVP_STATUS.md). La présence de propositions SQL et fonctions dans Git ne signifie pas déploiement ; aucune activation distante dans ce lot.

Contrôles locaux finaux : 447 tests standard, 447 avec photos, 19 tests Node, analyse stricte et format réussis. CI GitHub à distinguer de ces preuves locales.

Prochain lot fonctionnel : (1) finaliser la recherche française, (2) finaliser le cycle des photos publiées, (3) réaliser la recette deux appareils/réseau dégradé. Examiner les propositions et tests déjà présents avant toute nouvelle implémentation. Aucun téléphone connecté à la consolidation. Les autorisations de migration, suppression, signature et écritures métier restent distinctes. Ne pas nettoyer les fixtures automatiquement.

## Audit global terminé — 2026-11-02

[Bilan complet à lire](AUDIT_ETAT_ACTUEL_2026_11_02.md), avec preuves locales/distantes et priorités. Analyse/format/diff conformes, **443 tests standard relancés et réussis**. Produit et données non modifiés ; dernière installation demeure le processus 20344 du lot précédent.

Défaut à prioriser : préfixes français tél/télé sans résultat alors que téléphone en trouve 132 ; iph fonctionne (44). Ne pas présenter la recherche progressive comme entièrement corrigée. Prochain lot fonctionnel recommandé après choix de priorités : normalisation recherche + gestion complète des photos publiées + recette réelle à deux appareils/réseau dégradé. Conservation du code, suppression effective de compte, signature/support/confidentialité et séparation des fixtures sont des préalables à la diffusion publique. Badge Équipe KIBO discuté, **non implémenté**. Aucun commit/push, changement distant ou nettoyage de fixtures autorisé par déduction.

## Vendeur, sélection et style admin — 2026-11-02

Version finale avec garde de hauteur clavier installée/relancée en mode profile, processus 20344 et premier plan confirmés, sans effacement. **443 tests standard + 443 photos activées réussis**.

Trois ajustements implémentés : Message direct au-dessus de WhatsApp avec état propre vendeur expliqué, cartes de Mes annonces sélectionnables et actions groupées persistantes, entrée Administration uniforme. Analyse/diff conformes et captures de vrais widgets inspectées. [Périmètre](SELLER_SELECTION_ADMIN_UI.md). Prochaine recette humaine : vendeur tiers/invité et propre vendeur, sélection au toucher et barre persistante, profil admin. Une suppression réelle d’annonces précises demande son autorisation ; aucun commit/push autorisé.

## Profil vendeur, recherche et prix facultatif validés — 2026-11-02

Version normale installée et relancée en mode profile sur TECNO, processus 16509 et premier plan confirmés, sans effacement.

Espacements/logo WhatsApp/message direct après connexion intégrés. Recherche progressive titre/description dès trois caractères avec préfixes ; API visiteur réelle « iph » : 20/44 résultats, HTTP 206. Prix facultatif activé en Supabase après accord explicite (migration 20261102021424), annonces/prix/droits existants conservés. **435 tests standard + 435 photos réussis**, analyse/diff conformes. [Bilan](SELLER_SEARCH_OPTIONAL_PRICE.md).

Suite physique : vendeur tiers → Message direct invité → annuler puis se connecter, vérifier recherche pendant saisie/clavier et filtres, publier/modifier sans prix sur une annonce dédiée uniquement après autorisation de cette écriture. Pas de message réel envoyé ni annonce métier créée par la recette actuelle. Recette Google/OTP et admin physique restent distinctes. Aucun commit/push.

## Revue UI 2 et import massif validés — 2026-11-02

KIBO normal installé/relancé en mode profile sur TECNO, processus 13433 et premier plan confirmés ; capture physique des nouvelles photos vérifiée, sans effacement. Lanceur d’import remplacé par l’application normale.

Corrections UI/gestes/photos/actions groupées et accueil Administration implémentés ; 426 tests standard et analyse stricte réussis. `kanasmeth@gmail.com` promu admin sur instruction explicite, rôle vérifié ; reconnexion nécessaire. [Périmètre](UI_REVIEW_2_ADMIN_STRESS.md).

Lot `kibo-stress-20261102-v1` terminé et contrôlé : **1 080 annonces/1 080 JPEG/4 320 commentaires**, 120 annonces par catégorie, premier lot intact, total 1 188 annonces et 4 752 commentaires. 426 tests standard + 426 photos réussis, puis 42 tests ciblés après les dernières retouches. Suite humaine : se reconnecter sous kanasmeth pour vérifier Profil → Administration, tester gestes/photos/sélection sur le téléphone et mesurer la fluidité en mode profile. Les décisions de modération sur des données précises doivent être explicitement autorisées ; aucun signalement/sanction fictif ajouté ici. Aucun commit/push autorisé. Les fixtures ne prouvent pas une recette admin réelle ni une mesure FPS.

# Prochaine tâche — KIBO

## Jeu de données autorisé sur base connectée — 2026-11-02

**Import distant achevé et contrôlé : 108 annonces publiées + 108 photos JPEG + 432 commentaires/réponses**, 12 annonces par catégorie ; 432 notifications normales créées vers les comptes dédiés. Les deux comptes sont restés non administrateurs, RLS active. Lecture réelle d’une photo en visiteur : HTTP 200. **409 tests standard + 409 photos activées réussis**, analyse/format/diff conformes. Application normale réinstallée/relancée sans effacement, processus 23507 et premier plan confirmés. [Procédure et état réel](TEST_CATALOGUE.md). Ne pas rejouer l’import ni attribuer un rôle admin par déduction.

L’administrateur dispose déjà de Profil → Modération et du suivi opérateur des demandes de compte ; pas de rôle moderator distinct ni de console web dédiée. [État réel et discussion à poursuivre](ADMIN_MODERATOR_STATUS.md). Une attribution de rôle exige une instruction distincte. Aucun commit/push autorisé.

## Détails UI et cache photos — 2026-11-02

Espacements formulaires, refresh par tirage, filtres CG non libres, centrage des SearchBar et cache mémoire des photos implémentés. **402 tests standard + 402 photos activées réussis**, analyse/format/diff conformes. Version installée, processus 5803 confirmé sur TECNO, sans effacement. Premier plan non confirmé car verrouillage système affiché ; aucune tentative de déverrouillage. [Rapport et limites](UI_REFINEMENTS_CACHE.md). Pas de cache disque ni de benchmark FPS revendiqué. Aucun changement serveur ou donnée métier distante ; aucun commit/push.

Suite physique : vérifier les espacements avec clavier/texte système, tirer depuis le haut de l’accueil vide/rempli, choisir les villes et comparer la navigation carte/détail/onglets avant/après expiration du cache. Mesurer ensuite en mode profile si une lenteur subsiste ; la compilation debug seule ne certifie pas une fluidité de production. OTP reste désactivé en attente du prestataire et Google reste à valider réellement.

## Logo Google et téléphone OTP préparés — 2026-11-02

Logo officiel ajouté au bouton Google. Parcours téléphone +242/code SMS/renvoi/correction et API Supabase préparés ; affichage du numéro dans le profil personnel sans email. **Désactivé par défaut** en attendant un prestataire compatible et sa configuration autorisée. [Activation et recette](PHONE_AUTH.md) ; option locale `-EnablePhoneAuth` après configuration. **389 tests standard + 389 photos activées réussis**, analyse/format/diff conformes. Version installée/relancée sur TECNO sans effacement, processus 4771 et premier plan confirmés. Aucun réglage serveur modifié ni SMS réel envoyé.

Suite : choisir/configurer un prestataire SMS Supabase compatible avec +242, limites/expiration et protection anti-abus, compiler avec activation puis recette sur numéros contrôlés explicitement autorisée. Un prestataire non compatible nécessite un hook serveur distinct. Tester Google réel, OTP reçu/erroné/expiré/rejoué/renvoyé, profil sans email et session persistante. Aucun commit/push autorisé.

## Google implémenté localement — 2026-11-02

Bouton connexion/inscription et profil intégré, OAuth externe et callback PKCE existant branchés. Fournisseur Google réellement constaté activé en lecture seule ; aucune configuration distante modifiée. **379 tests standard + 379 photos activées réussis**, analyse/format/diff conformes. Version réellement installée/relancée sur TECNO sans effacement, processus 31974 et premier plan confirmés. [Contrat, configuration et recette](GOOGLE_AUTH.md). Prochaine étape humaine : choix du compte et retour à chaud/froid, annulation/refus, session persistante/déconnexion et adresse déjà utilisée en email. Ne pas confondre fournisseur activé et parcours réel validé. Aucun commit/push autorisé ; téléphone sans preuve de possession non implémenté.

## Correction demandée : cartes égales et appui long — 2026-11-01

Accueil : les cartes réservent les mêmes espaces pour titre/prix/ville/date, y compris entre rangées et sans date/photo ; dimensions adaptées au texte système. Les titres longs sont limités visuellement à deux lignes et restent complets dans le détail. Chat : appui long sur ses messages modifiables ouvre le panneau Material Modifier/Supprimer/Copier ; menu ⋯ conservé. Les confirmations, contrôles de session, droits d’auteur et contrat serveur existants sont réutilisés. Aucun changement Supabase.

Suite métier inchangée : recette à deux comptes lorsqu’elle sera autorisée, puis gestion avancée des photos et préparation de la connexion Google. Voir les résultats du lot dans PROGRESS. Diagnostics différés, aucun commit/push autorisé.

## Priorité actuelle : gestion Material des annonces/messages — 2026-11-01

Mes annonces avec photos/statuts, galerie de modification, ajout sur annonce sans photo et retrait explicite du catalogue par archivage implémentés. Bulles Material et parcours modifier/supprimer ses messages intégrés. [Bilan et fichiers](MANAGEMENT_MATERIAL3.md). Le contrat `supabase/proposals/chat_message_actions.sql`, testé sur PostgreSQL local et audité à distance, a été appliqué après accord explicite ; colonnes, RPC, RLS et privilèges contrôlés. Les menus restent conditionnés à la capacité serveur, à l’auteur et à l’état de la conversation.

Suite : recette physique des mutations sur comptes dédiés avec écritures autorisées ; configuration OAuth Google et bouton « Continuer avec Google » après préparation/revue des réglages. Remplacement/retrait/réordonnancement des photos existantes : lot distinct, non pris en charge par les réservations immuables actuelles. Aucun effacement définitif d’annonce introduit. Avertissement Auth sur les mots de passe compromis documenté dans le bilan, réglage non modifié. Préserver le travail local ; aucun commit/push autorisé. Diagnostics et recette à deux comptes toujours différés.

## Priorité actuelle : finition de la référence, villes et dates — 2026-11-01

Accueil compact, catégories à icônes, recherche/favoris en listes, sélecteur hors ligne de villes/localités CG et ancienneté des annonces intégrés. [Périmètre, fichiers et limites](REFERENCE_CITIES_DATES.md). Les 68 références de 34 écrans/panneaux clair/sombre remplacent les 66 rendus du lot précédent ; [galerie](../maquette/index.html).

Suite proposée : affiner les étapes de publication et l’aperçu final, puis les bulles/actions de conversation et les états de chargement/erreur, avec comparaison des références clair/sombre. Préserver la saisie des villes existantes et les contrats métier ; la normalisation des anciennes valeurs demanderait un lot distinct. Le profilage et la recette à deux comptes restent différés. Aucun commit/push ou changement distant autorisé.

## Priorité utilisateur actuelle : détails visuels et fonctionnalités — 2026-11-01

Les diagnostics sont **différés à la demande de l’utilisateur**. Ne pas reprendre la priorité historique de profilage ci-dessous à la place de son choix actuel. Connexion directement dans Profil, correction des messages vides, détail rapproché de la référence et thèmes clair/sombre implémentés ; [bilan](VISUAL_PERSONALIZATION.md). Les 66 références de 33 écrans/panneaux sont dans [`maquette/`](../maquette/README.md), avec galerie HTML et catalogue.

Après les validations et la relance consignées dans PROGRESS : poursuivre l’affinage UI à partir de ces références, notamment le parcours Publier, les vues compactes de recherche/favoris et les actions de conversation. Préserver les règles du MVP, les trois photos, les sessions et permissions existantes. La recette à deux comptes reste différée selon le choix précédent ; ne pas créer des données réelles pour la contourner. Aucun commit/push ou changement distant autorisé.

## Priorité actuelle : refonte Material 3 — 2026-11-01

Maquette locale confirmée, refonte intégrée et application normale restaurée/relancée sur TECNO, photos et navigation inspectées. **339 tests standard + 339 photos réussis**, analyse/format/diff conformes ; [rapport, fichiers, séries profile et limites](MATERIAL3_REDESIGN.md). Le banc fictif n’est plus l’application installée. Aucun backend ou modèle modifié, aucune donnée réelle créée, aucun commit/push.

**Prochaine tâche : diagnostiquer la fluidité avant diffusion.** Le cache baisse de 77,7 %, mais la troisième mesure finale atteint 30,369 ms en construction p95 contre 24,802 ms avant. Capturer des profils CPU/GPU et analyser le diagnostic Vulkan commun aux versions, avec charges, températures et ordre des versions contrôlés. Conserver les mesures défavorables ; ne pas attribuer leur cause à la chauffe ou au moteur sans preuve et ne pas déclarer la performance validée. Les commentaires/modération n’ont pas de mesure séparée sous forte charge.

Ensuite : revue visuelle sur téléphone des parcours existants ; contrôle prolongé des photos sur réseau mobile ; recette à deux comptes dédiés lorsque l’utilisateur les aura préparés. La disponibilité de ces comptes a déjà été différée : poursuivre localement, sans nouvelle demande répétée ni création de données réelles. Ne pas reprendre les changements backend/suppression à la place de la priorité UI. Aucun commit, push ou déploiement distant autorisé.

## Priorité utilisateur : UI/UX — 2026-11-01

L’utilisateur a choisi de se reconcentrer sur l’UI/UX avant de reprendre le worker de suppression. Lot terminé : accueil/recherche/cartes ; détail/photos/publication ; accessibilité/états/identité visuelle. **334 tests standard + 334 photos réussis**, analyse/format/diff conformes ; version et icône Android KIBO installées sur TECNO sans effacement, processus confirmé, accueil inspecté. [Bilan et limites](UIUX_MARKETPLACE.md). Les propositions d’historique et de suppression restent locales, non déployées ; ne pas reprendre leur activation à la place de cette priorité. Aucune donnée de recette réelle créée.

Suite UI/UX proposée après validation : Profil/connexion/récupération ; Messages/Notifications ; Favoris/Mes annonces. Conserver les cinq destinations et tous les contrats métier. Relancer la version validée sur le TECNO connecté sans effacement, puis rendre compte des fichiers/tests et limites. Aucun commit/push autorisé.

## Après prototype d’historique et worker local — 2026-11-01

[Prototype, fichiers et limites](RETAINED_HISTORY_PROTOTYPE.md) : SQL d’historique privé testé en fixture, Flutter compatible avec auteur supprimé, noyau d’orchestration testé sans réseau. **327 tests standard + 327 photos activées, 19 tests Node et SQL History réussis**, analyse/format/diff conformes ; version réellement installée/lancée sur TECNO sans effacement, processus confirmé. Aucun déploiement ni vraie suppression. La recette réelle reste différée selon la réponse utilisateur : pas encore de deux comptes/appareils dédiés, poursuivre localement. Ne pas redemander immédiatement la même disponibilité et ne pas créer des comptes pour la contourner.

Suite locale : préparer le ledger transactionnel/fencing et les guards du compte gelé ; branchement contrôlé des historiques privés avec pagination et anciennes notifications, sans fusion dans les commentaires publics ; adaptateurs Storage/Auth et politique de rétention à tester en staging identifié et autorisé avant toute activation. Le projet de production est volontairement refusé par le prototype. Toute suppression réelle et nouveau déploiement nécessitent un accord précis après revue des contrats. Ne pas annoncer le worker comme un service opérationnel ni les tests en mémoire comme une recette réelle. Réutiliser Launch-KiboAndroid après validation, sans effacement. Aucun commit/push autorisé.

## Préparation du pilote validée localement — 2026-11-01

Recette à deux comptes préparée dans [RECETTE_MVP_DEUX_COMPTES.md](RECETTE_MVP_DEUX_COMPTES.md) ; exécution humaine non revendiquée, comptes dédiés et écritures à autoriser selon ce plan. Choix de conservation reçu pour [ACCOUNT_DELETION_RUNBOOK.md](ACCOUNT_DELETION_RUNBOOK.md), pas de worker destructif déployé : adapter le modèle d’historique/RLS, fixer les durées et tester en staging avant toute activation. [Signature et lancement Android](ANDROID_PILOT.md) : release sans clé refusée ; debug sans clé accepté. Nouveau lanceur `scripts/Launch-KiboAndroid.ps1` à utiliser après validation pour éviter de répéter tous les tests lors d’une simple reconnexion du téléphone. **321 tests standard + 321 photos réussis**, analyse/format/diff conformes ; nouvelle version réellement installée/lancée sur TECNO sans effacement, processus confirmé. [Bilan et limites](PILOT_PREPARATION_RECAP.md). Aucun commit/push autorisé.

Prochain lot proposé : modèle d’historique anonymisé et tests locaux de conservation/isolation ; préparation du worker de suppression idempotent en staging après définition des règles ; recette humaine avec comptes dédiés puis validation signature/support/distribution. Aucune suppression réelle ni nouveau déploiement destructif autorisé par cette préparation.

## Après notifications, comptes et reprise des photos — 2026-11-01

Trois chantiers implémentés ; contrat spécifique autorisé et réellement appliqué **20261101092315 kibo_engagement_workflows**, contrôles RLS/ACL conformes. Ne pas le réappliquer. [Fonctionnalités, inventaire et limites](ENGAGEMENT_ACCOUNT_WORKFLOWS.md). **316 tests standard + 316 photos activées réussis**, analyse/format/diff conformes. ADB ne détecte aucun téléphone après deux contrôles : aucune nouvelle installation ni exécution physique pour ce lot. Reconnecter le TECNO et lancer la version validée sans effacement avant la recette humaine.

Prochain lot proposé : (1) recette humaine à deux comptes des messages/non lus, préférences, blocages et contacts ; (2) formalisation puis implémentation contrôlée de la suppression réelle par l’opérateur, après définition de l’identité et de la conservation, sans exposer service_role dans Flutter ; (3) revue UI/UX physique/accessibilité et préparation du pilote Android avec signature/distribution/support. Les préférences n’ajoutent aucun push système. Les photos locales ne sont pas synchronisées entre appareils. Aucun vrai compte de test, rôle, message ni effacement à créer sans accord approprié. Relancer sur le téléphone reconnecté après contrôles, sans effacer ses données. Aucun commit/push autorisé.

Les sections suivantes sont historiques.

## MAINTAIN public/postgres réglé — 2026-11-01

Delta dédié autorisé explicitement et appliqué : **20261101090123**, neuf tables et defaults postgres/public, vérifications conformes. [Contrôle réel](CLIENT_MAINTAIN_DEPLOYED.md). Ne pas redemander l'accord ni rejouer ce delta ; le fichier global refusé reste non appliqué. Storage et defaults supabase_admin ne sont pas couverts. Suite immédiate : recette humaine à deux comptes, liens PKCE et procédure opérateur de suppression, puis préparation du pilote Android.

## Après exécution autonome jusqu'au lot 8

Voir [MVP_AUTONOMOUS_RECAP.md](MVP_AUTONOMOUS_RECAP.md) et PROGRESS pour les preuves finales. Fonctionnalités et améliorations des lots 2–8 implémentées ; **293 tests standard + 293 photos réussis**, analyse/format/diff conformes, dernière version installée/lancée sur TECNO code 0. Prochaine étape : recette humaine à deux comptes et revue visuelle, réception réelle du lien PKCE, processus opérateur de suppression ; puis lot 9 de préparation du pilote Android (signature/distribution/support). Ne pas déclarer la publication production prête à partir des tests locaux.

Le fichier global MAINTAIN a été refusé par auto-review et reste non appliqué ; ne pas rejouer `mvp_final_hardening.sql`. Le delta séparé neuf tables/defaults postgres public est désormais appliqué après accord spécifique, comme indiqué ci-dessus. Les contrats MVP déjà appliqués ne doivent pas être rejoués. Aucun commit/push effectué.

## Après notifications/signalements/modération — 2026-11-01

Les trois parcours sont implémentés ; contrat autorisé et appliqué (20261101051653). 25 nouveaux tests ciblés et SQL isolé réussis ; résultats globaux et lancement téléphone dans PROGRESS. [Contrat et fichiers](NOTIFICATIONS_MODERATION.md).

Prochain lot de trois tâches : préparer/exécuter la recette acheteur-vendeur à deux comptes autorisés (chat et notifications) ; valider le cycle annonce/photos/vente/archivage ; valider favoris visiteurs/transfert et contacts volontaires. Aucune donnée réelle de test ni compte/rôle administrateur à créer sans accord spécifique. Poursuivre les améliorations UI/UX indépendantes si la recette attend l'utilisateur : navigation Messages/Notifications, cartes et états vide/erreur, petits écrans/clavier/texte agrandi. Après chaque lot validé, relancer sur le téléphone connecté sans effacement.

Les sections suivantes sont historiques.

## Après le lot chat — 2026-11-01

Les trois parcours chat sont implémentés ; Realtime autorisé et appliqué (20261101050420), RLS maintenue. 20 tests nouveaux et SQL local réussis. Voir [CHAT.md](CHAT.md), résultats globaux et lancement appareil dans PROGRESS. La consigne utilisateur impose désormais de relancer sur le téléphone après chaque lot validé, sans effacement ; aucune autorisation de commit/push déduite.

Prochain groupe : centre de notifications personnelles et lecture des états serveur existants ; signalement d'annonce/commentaire authentifié ; parcours de modération et traçabilité selon les permissions réelles. Auditer d'abord schéma/RLS/guards, ne pas fabriquer de droits administrateur ni modifier de données réelles pendant les tests. En parallèle de la recette manuelle à deux comptes du chat, avancer les tâches indépendantes.

Les sections suivantes décrivent les lots historiques.

## MVP — contacts implémentés, puis chat intégré

Profil public, préférences volontaires et boutons WhatsApp/appel implémentés. Contrat contacts testé en SQL local, autorisé explicitement puis réellement déployé (20261101044111), sans coordonnées réelles créées. Validation finale : 227 tests standard + 227 photos réussis, analyse stricte, format et diff conformes. Recette physique à effectuer. [Contrat et inventaire](SELLER_CONTACTS.md).

Prochain groupe proposé : liste des conversations authentifiées ; écran de conversation avec envoi/réception persistants ; actualisation Realtime et états vide/erreur avec isolation A/B. Auditer d'abord les tables conversations/messages et leurs triggers/RLS, réutiliser le client et la session existants, ne pas envoyer de messages réels à d'autres personnes pendant les tests. Notifications puis signalements/modération restent ensuite à compléter. Pas de commit/push ni de génération d'exécutable par défaut.

## MVP — commentaires/réponses puis contacts vendeur

2026-11-01 : quatre deltas propriétaire/privilèges réellement appliqués et contrôlés sur PG17.11 avec autorisation utilisateur. Default ACL supabase_admin différée faute de rôle, non bloquante pour les fonctionnalités. Ne pas réappliquer ces deltas ni utiliser un db push global. [Déploiement réel](OWNER_MANAGEMENT_DEPLOYED_20261101.md).

Commentaires publics, publication et réponses terminés localement : **208 tests standard + 208 photos activées réussis**, analyse/format/diff conformes. La priorité utilisateur est désormais d'avancer vers le MVP par lots cohérents, sans arrêt systématique pour des incidents de tests/style/outillage. Prochain groupe immédiatement proposé : profil public vendeur minimal ; configuration volontaire des moyens de contact ; boutons WhatsApp/appel authentifiés avec tests et gestion des applications absentes. Examiner d'abord les contrats publics/privés existants avant toute nouvelle colonne ou exposition de téléphone. Chat, notifications et signalements/modération restent ensuite à terminer. Voir [MVP_STATUS.md](MVP_STATUS.md).

Les demandes historiques d'avis après un test échoué et les paragraphes « aucun déploiement autorisé » ci-dessous ne s'appliquent pas aux opérations exactes déjà autorisées et réalisées dans ce lot. Aucun accord de commit/push ou de création d'exécutable déduit de cette priorité.

## Prochain lot après propositions SQL validées

2026-11-01 : les trois tâches SQL sont terminées localement. Exécution finale code 0, cluster 55479 arrêté, refus de réapplication et retours arrière vérifiés. Lire [OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md](OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md) : ordre des fichiers, baseline, privilèges ciblés et différence PG13 testé/PG17.11 distant. Les sections « en cours » ci-dessous sont historiques.

Suite proposée en trois étapes :

1. Revue opérateur des fichiers exacts, compatibilité PG17 et droit d'agir sur les default ACL de supabase_admin ; prévoir une vérification distincte de MAINTAIN et des surfaces hors périmètre.
2. Après autorisation explicite des fichiers concernés, application ciblée des deux phases propriétaire et des trois propositions de privilèges, sans db push global ni retour arrière automatique.
3. Vérification distante en lecture seule, puis recette propriétaire/favoris visiteurs sur comptes/données de test expressément autorisés ; distinguer états publics, isolation et persistance Android.

Aucun déploiement, écriture réelle ou génération/installation d'exécutable n'est autorisé par la seule préparation terminée. Ne pas réappliquer les réparations photos antérieures.

## Lot SQL en cours — 2026-11-01

Accord reçu pour correction et fin du lot ; exécution isolée complète réussie sur 55478. Derniers contrôles de refus de réapplication et de rollback ACL en cours sur un nouveau cluster. Ne pas lire la suspension historique ci-dessous comme une nouvelle demande d'avis. Aucun déploiement autorisé.

Propositions propriétaire/privilèges préparées, audit readonly réel terminé, tests SQL isolés suspendus sur le lanceur Windows avant toute assertion. Avis utilisateur demandé pour correction ExitCode et validation complète. Lire [OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md](OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md). Aucun déploiement autorisé, aucune donnée réelle ou exécutable. Les tâches du lot visiteurs ci-dessous sont terminées.

## Après le lot visiteurs — prochain groupe de trois tâches

Favoris sans connexion, persistance locale et transfert explicite implémentés. **191 tests standard + 191 photos activées réussis**, analyse stricte, format et diff check conformes. Contrat : [GUEST_FAVORITES.md](GUEST_FAVORITES.md). Aucune recette physique ni transfert Supabase réel réalisé. La section « lot actif » ci-dessous est historique et n'indique plus une tâche inachevée.

Prochain groupe proposé, sans génération d'exécutable ni écriture réelle par défaut :

1. Préparer le delta local vente/archivage à partir des deux guards réellement audités et de l'ajout sold, en préservant les voies administratives et les protections.
2. Reproduire et tester ce contrat dans une fixture PostgreSQL isolée : A/B/visiteur/admin, concurrence, photos/favoris et transitions interdites.
3. Préparer le durcissement distinct des privilèges clients excessifs après audit de leur provenance, avec SQL exact et plan de retour pour revue.

L'application distante des deltas et la recette Android réelle des favoris visiteurs exigent leurs autorisations explicites. Le protocole devra distinguer persistance des IDs et disponibilité réseau des fiches, puis transfert accepté/refusé/partiel et changement de compte. Ne pas réinstaller par défaut.

## Lot actif prioritaire — favoris visiteurs, 2026-11-01

Tâche 3 terminée localement : transfert explicite, déduplication/confirmation et isolation de session ; 34 tests ciblés réussis après correction autorisée des timeouts navigation. Trois tâches implémentées, validation globale finale en cours. Lire [GUEST_FAVORITES.md](GUEST_FAVORITES.md).

L'utilisateur approuve les favoris sans connexion, leur persistance locale et le transfert proposé vers un compte. Tâches 1/2 implémentées, tests initiaux favoris 21 réussis. Terminer confirmation UI, isolation de compte, transfert partiel et validation complète ; aucune donnée distante réelle à créer. Le précédent lot serveur proposé ci-dessous est différé, sans autorisation d'application.

## Prochain lot de trois tâches — après recherche/filtres/confirmation

Rythme demandé par l'utilisateur : enchaîner au moins trois tâches cohérentes par lot, rendre compte à la fin et proposer immédiatement le lot suivant. Cela n'autorise ni commit/push, ni changement distant ou création d'exécutable par défaut.

2026-11-01 : les trois tâches locales sont terminées, **173 tests standard et 173 avec photos activées réussis**, analyse stricte et format conformes, diff check code 0. Le lot comprend confirmation du retour UPDATE, filtres par statut et recherche propriétaire combinée/paginée. L'audit distant readonly est terminé : [OWNER_LISTING_SERVER_AUDIT.md](OWNER_LISTING_SERVER_AUDIT.md).

Enchaînement proposé :

1. Préparer un delta local adapté aux deux guards réels et à l'ajout sold, sans changer les voies admin ni supprimer les protections ; expliciter l'ancien chemin draft/rejected → pending avant de l'élargir.
2. Reproduire les deux guards dans une fixture isolée et tester transitions A/B/visiteur/admin, concurrence et conservation photos/favoris.
3. Préparer une correction distincte des privilèges clients TRUNCATE/REFERENCES/TRIGGER, après audit de provenance et des autres tables exposées ; fournir SQL exact et plan de retour pour revue.

Aucune application distante sans autorisation explicite du delta exact. Aucune recette sur données réelles ni compilation/installation par défaut. Les sections « lot en cours » et « vérification serveur » ci-dessous sont historiques ; l'audit n'est plus à redemander ni à déclarer indisponible.

## Lot en cours — 2026-11-01

Tâche 2/3 terminée : filtres serveur par statut, 36 tests ciblés réussis. Enchaîner recherche combinée, tests de pagination/réponses tardives et validation finale.

Tâche 1/3 terminée : confirmation du résultat UPDATE, 17 tests repository réussis. Enchaîner filtres par statut puis recherche propriétaire, avec pagination et tests. Audit distant en lecture seule confirme sold absent et deux guards bloquants ; aucun déploiement autorisé. Examiner séparément les droits TRUNCATE anon/authenticated relevés.

## Gestion des annonces : vérification serveur avant recette réelle

2026-11-01 : lot choisi par l'utilisateur, socle local préexistant revu et complété. Profil → Mes annonces, édition, vente et archivage couverts par **23 tests ciblés**, suite standard **152 réussis**, analyse et format conformes. Voir [OWNER_LISTING_MANAGEMENT.md](OWNER_LISTING_MANAGEMENT.md). L'ancien « prochain lot à choisir » ci-dessous est désormais historique.

Prochaine étape : vérifier en lecture seule le contrat distant avec accès opérateur autorisé (statut sold, contraintes, grants, RLS et tous les guards UPDATE). Le candidat SQL préexistant n'est pas une migration prête à appliquer ; aucune application autorisée par cette reprise. Préparer et tester un delta adapté seulement après ces preuves. Puis demander l'autorisation du delta exact et de la recette sur comptes/données de test. Aucun build ni installation par défaut ; aucune nouvelle correction photos/catalogue à rejouer.

## Priorité à choisir — après confirmation de recette utilisateur

2026-11-01 : l'utilisateur confirme que tout fonctionne désormais sur le TECNO après réparation Supabase. Le blocage photos/catalogue est clos sur la base de son retour. Les instructions de nouvelle tentative ci-dessous sont conservées comme historique et ne sont plus la prochaine tâche à répéter. Aucun scénario de sécurité détaillé supplémentaire n'est certifié par ce retour global.

Prochain lot à choisir avec l'utilisateur : gestion de ses annonces (modification, vente, archivage), commentaires/réponses ou contacts vendeur. Suggestion : gestion des annonces pour compléter le parcours vendeur prévu par la feuille de route. Avant implémentation, vérifier le contrat propriétaire et les transitions de statut existantes, préserver photos et favoris, puis couvrir les accès A/B et les erreurs. Ne pas déduire du feu vert précédent une autorisation de commit/push ou de suppression de données.

## État actuel — serveur réparé, reprendre la recette sur l'annonce existante

2026-11-01 : autorisation explicite distante reçue et utilisée via la session Dashboard KIBO déjà ouverte. **Supabase corrigé** : EXECUTE public sur is_admin rétabli après lecture de son corps sûr ; variante photos avec ancien Storage conservé appliquée ; vecteur/index recherche appliqués ; validateur Edge kibo-upload-listing-photo déployé avec auth exigée. Lecture catalogue/photos/vecteur **200**, OPTIONS **200**, refus sans credentials/faux jeton/clé publique seule **401**. Aucun secret extrait. Résultats vérifiés et SQL dans [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md).

**Ne plus demander d'autorisation pour ces corrections déjà autorisées et terminées ; ne pas les réappliquer.** Six annonces conservées, anciennes policies Storage hash identique, bucket historique intact ; nouveau bucket privé, RLS et quatre gardes restrictives, champs owner/path protégés, index valides. Versions20261101022728 et20261031220520 enregistrées avec source ; ne pas exécuter l'ancienne proposition photos ni un db push/reset global sans réconciliation des versions historiques.

Prochain geste utilisateur : formulaire de l'annonce existante encore ouvert avec aperçus → **Réessayer les photos une seule fois**, attendre le résultat puis vérifier carte/détail. Ne pas recréer l'annonce, redémarrer ou réinstaller avant cette reprise en mémoire. Si déjà Accueil, actualiser pour vérifier le catalogue ; un brouillon détruit n'est pas restauré par ce correctif. Le backend réparé fonctionne avec l'APK photos déjà installé ; aucun nouvel APK imposé. Binaire corrigé FC17FAEE… disponible localement, non installé.

Restent à observer sur appareil : upload authentifié réel, URLs signées, recherche/filtres/tri/pagination, favoris/persistance et isolation A/B. Ces scénarios ne sont pas déclarés réussis. Aucun test distant n'a créé de données métier ; aucun commit/push, suppression ou installation Android effectué pendant l'intervention. Tests locaux spécifiques Storage tous réussis et4Edge réussis ; validations Flutter129+129 du lot précédent conservées.

## Historique désormais résolu — rétablir le contrat serveur avec accès opérateur

2026-11-01 : causes distantes désormais prouvées par GET limit=0/OPTIONS : **42501 permission denied for function is_admin**, relation photos **PGRST200**, table API **PGRST205**, vecteur **42703**, fonction upload **404/NOT_FOUND**. Lire [CATALOGUE_PHOTOS_FIX.md](CATALOGUE_PHOTOS_FIX.md) avant les historiques ci-dessous. Ne plus traiter ce lot comme une simple panne réseau inconnue ; le statut de l'ancienne tentative d'upload précise reste non capturé.

Code local corrigé : catalogue/détail/favoris compatibles avec relation photos optionnelle absente, erreurs de droits conservées, recherche serveur transitoire sans vecteur, préflight avant nouvelle création avec photos et reprise de l'annonce existante préservée. **129 tests avec photos, 129 standard**, analyse stricte, 4 Edge et assertions SQL fixture réussis. Aucun contournement RLS ; pas de modifications des migrations originales.

**Prochain geste nécessaire :** accès SQL Supabase opérateur pour exécuter `supabase/audits/catalogue_compatibility_readonly.sql` et vérifier qualification/corps/ACL is_admin ainsi que Storage réel. La connexion est installée mais ses outils SQL ne sont pas exposés dans cette session ; pas de clé/mot de passe dans le chat et pas de réinstallation automatique du plugin. Après cette lecture et validation : candidat `supabase/proposals/restore_listing_read_execute.sql` (GRANT EXECUTE ciblé), puis contrat photos approprié, vecteur/index et fonction Edge selon DEPLOYMENT_PLAN. Ne pas copier le GRANT sans vérifier que la fonction est bien private.is_admin() et sûre. Pas de db push/reset global, politique permissive ou désactivation JWT.

APK corrigé **compilé, non installé** : `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256 `FC17FAEE2E8C22E77896AF006A5907FDA10ADEAB4C422DEE288E5E11938CB93C`, ancien APK archivé. Ne pas réinstaller/redémarrer si les seules photos en attente sont dans le formulaire actuel. Aucun transfert sûr de cet état validé. Après backend rétabli et autorisation de recette, retenter les photos sur le même ID, vérifier catalogue/détail/recherche/favoris/isolation ; aucun scénario physique déjà déclaré réussi.

Aucun changement distant, nouvelle annonce, suppression, clic de reprise, commit/push ou déploiement exécuté. Le fonctionnement complet reste bloqué côté serveur, même avec le nouvel APK.

## Priorité — activer le diagnostic sans perdre la reprise existante

2026-11-01 : instrumentation locale terminée et validée (**118 tests Flutter photos activées**, analyse stricte et format réussis). Étape, véritable statut HTTP quand observable, code Supabase filtré, attempt local et sb-request-id éventuel ; aucune donnée privée ni erreur brute. Collecteur `scripts/Collect-PhotoUploadLogs.ps1` prêt et testé sur fixture, protocole exact dans [PHOTO_UPLOAD_DIAGNOSTIC.md](PHOTO_UPLOAD_DIAGNOSTIC.md).

**Blocage concret : l'APK TECNO courant n'a pas cette instrumentation et le formulaire en échec garde seul ses photos/ID en mémoire.** Ne pas installer/restart/forcer l'arrêt/quitter le formulaire pour obtenir les logs. Aucune activation sûre en mémoire validée ici ; un simple hot reload ne réinitialise pas forcément le client HTTP SDK. Aucun attach/hot reload, build/install ni tentative réseau effectué. La journalisation du dépôt ne permet pas de revendiquer une erreur réelle ou un statut sur la tentative actuelle.

Prochaine étape : soit valider séparément une activation qui conserve l'état existant et rend les observations possibles, soit recueillir les logs distants existants en lecture seule. Après activation sûre seulement, lancer le collecteur puis une seule action Réessayer les photos sur le même formulaire, dans une tentative explicitement autorisée, sans republier. Relier failure/attempt/stage/http_status/code et sb-request-id/heure aux vérifications distantes du diagnostic ; statut null = inconnu, 502/storage ne donne pas le statut amont. Ne pas créer de nouvelle annonce pour lever ce blocage.

Code/migrations Edge inchangés, aucune modification Supabase distante, suppression/recréation d'annonce, commit ou push. Travail local préexistant conservé.

## Priorité — identifier l'étape photo distante en échec, sans republier

2026-11-01 : utilisateur a observé l'annonce publiée avec photos incomplètes. **Garder le formulaire ouvert** : reprise par ID/photos en mémoire, pas de restauration persistante au redémarrage. Ne pas réinstaller, supprimer/recréer l'annonce, changer ses réservations ou cliquer automatiquement sur Réessayer. Détails dans [PHOTO_UPLOAD_DIAGNOSTIC.md](PHOTO_UPLOAD_DIAGNOSTIC.md).

Le code crée l'annonce avant d'envoyer les photos ; ce message signifie échec post-création, pas nécessairement refus Storage. Logs ADB disponibles : 32 lignes du PID 13411, aucune exception ni statut HTTP exploitable. **Cause exacte distante et statut encore indéterminés.** Aucun accès Supabase actif exposé ; contrat local bucket/table/path/RLS/Edge cohérent mais déploiement réel non certifié.

Prochain geste en lecture seule avec l'opérateur autorisé : rapprocher heure/ID annonce et logs REST/Edge/Storage, lire réservations et objets de cette seule annonce, vérifier présence du bucket privé/limites, ACL/RLS et fonction/version/JWT/configuration serveur sans afficher de secrets. Script listing_photos_readonly.sql et vérifications complémentaires listés dans le diagnostic. 502/storage ne donne pas le statut Storage amont ; pas de règles permissives ni désactivation JWT comme dépannage. Préparer une correction locale uniquement après preuve de l'étape fautive ; aucune permission de modification distante accordée.

Tests de diagnostic prêts : **113 Flutter avec photos activées**, analyse stricte sans anomalie et **4 Edge réussis** ; 7 nouveaux cas SDK et assertions UI/Edge de reprise sans recréation. Runtime et migrations inchangés, pas de nouvel APK nécessaire pour ces seuls tests. Les observations utilisateur ne valident pas encore l'affichage/recherche/favoris du parcours complet. Aucun commit/push/déploiement ni donnée distante modifiée par l'assistant.

## État actuel — correctif validé, APK installé, recette intégrée bloquée

2026-11-01 : choix utilisateur « diagnostiquer et corriger avant installation » exécuté. Test de parcours corrigé par injection des services photo fictifs activés et vérification de récupération A/B, sans modifier le code livré ni désactiver les photos. Analyse stricte réussie, **106 tests passent avec photos activées et 106 en configuration standard**. Test ciblé et format réussis. Détails et commandes dans PROGRESS et [PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md](PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md).

APK de SHA-256 `775B66D245F21A8F479BD93EB3CC9929D9775687C66F23086042B8819DF330B2` inchangé et installé avec succès via `adb install -r` sur TECNO CK6n H6929CK6NU012345. **Ne pas réinstaller par défaut.** Aucune désinstallation/effacement, aucun lancement ou scénario physique fonctionnel. L'ancien blocage test/installation ci-dessous est historique et résolu.

Prochaine étape : valider les préconditions backend D/P/S/E/R/F en lecture seule et les décisions du plan de déploiement ; aucune permission d'appliquer une migration ou déployer n'est accordée ici. Autorisation distincte des comptes/données fictives et écritures avant recette intégrée 01–08/E1–E6. Ne pas lancer le client photos activées comme preuve d'intégration sur un backend non validé. Aucun changement Supabase distant, commit ou push effectué.

## Recette préparée — avis requis après test échoué, 2026-11-01

Lire [PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md](PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md). TECNO CK6n H6929CK6NU012345 détecté, Android 14 ; APK photos activées compilé avec succès (286,3 s), vérifié sous `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256 `775B66D245F21A8F479BD93EB3CC9929D9775687C66F23086042B8819DF330B2`. Ancien APK archivé, aucun changement applicatif ou SQL.

**Arrêt avant installation :** tests annonces/photos/recherche/favoris avec flag true : 38 passent, 1 timeout `direct_publication_flow_test.dart:36`. WORKFLOW exige un avis après test échoué. Choix utilisateur demandé : diagnostiquer/corriger avant installation, ou installer explicitement malgré cet échec sans lancer l'app. Ne pas modifier/ignorer le test pour annoncer une validation. Aucun adb install ni scénario physique fonctionnel effectué pendant cette préparation.

Après résolution de ce choix seulement, commande d'installation préparée : `adb -s H6929CK6NU012345 install -r C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk`. Ne pas désinstaller/effacer les données. L'autorisation d'installation ne permet pas de créer des annonces, objets ou favoris distants. Les scénarios intégrés restent bloqués par validation effective des migrations/RLS/Storage/Edge et autorisation distincte des comptes/données fictives de recette. Aucun déploiement demandé dans cette tâche.

## Priorité après audit pré-déploiement — 2026-10-31

Lire [DEPLOYMENT_PLAN_PHOTOS_SEARCH.md](DEPLOYMENT_PLAN_PHOTOS_SEARCH.md) et [PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md](PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md). **Ne rien déployer sans autorisation distincte.** Audit local terminé : 106 tests Flutter, 3 tests Edge existants et 1 nouveau test de limite réussis ; analyse stricte sans anomalie ; assertions SQL locales et tests de garde/verrou/réexécution réussis. Migrations originales conservées, cluster isolé arrêté. Aucune vérification Storage distante ni recette physique effectuée pendant cet audit.

Prochaine étape : obtenir avec les accès autorisés les définitions Storage/ACL et fonctions dépendantes réelles en lecture seule, sans répéter l'audit INSERT déjà confirmé par l'utilisateur. Exécuter `supabase/audits/listing_photos_readonly.sql` seulement avec cet accès et comparer au contrat proposé. Si des politiques Storage existent, la migration originale s'arrête volontairement : préparer et tester séparément une variante complète qui conserve les autres buckets, jamais supprimer une politique pour passer.

Avant application : faire valider l'ordre exact et l'historique des trois deltas, les droits sur le vecteur, les triggers UPDATE et une fenêtre SQL tenant compte de la réécriture de listings. Puis valider configuration/bundle/lockfile et démarrage Edge avec JWT, sans désactiver l'authentification. Les extraits de correction restent des propositions non appliquées. Toute écriture SQL/Storage, déploiement Edge, installation/diffusion Flutter ou donnée de recette requiert ensuite son autorisation ; le plan fournit les commandes proposées et les conditions d'arrêt.

Conserver les objets et données en cas de repli ; pas de DROP, purge, reset ou restauration globale par défaut. Photos désactivées par défaut ; recherche textuelle dépend du vecteur distant. La reprise d'upload ne persiste pas au-delà du formulaire vivant. Les instructions historiques ci-dessous doivent être interprétées avec ces résultats plus récents.

## Prochaine étape — photos/recherche locales testées, backend non déployé

Lot terminé localement dans l'ordre demandé : parcours vendeur A/acheteur B et persistance simulée des favoris ; sélection/compression/ordre et upload photos avec validateur Edge proposé ; recherche/filtres/tri paginés côté serveur. **106 tests Flutter**, **9 tests supplémentaires avec projection photos activée**, **3 tests Edge simulés** réussis ; analyse stricte sans anomalie, format de 58 fichiers conforme et assertions SQL sur cluster jetable réussies (cluster arrêté). Résultats et incidents réels dans PROGRESS ; contrat, activation et inventaire des fichiers dans LISTING_PHOTOS_SEARCH.md.

Aucun contrat Storage existant trouvé dans le dépôt ; l'utilisateur a confirmé autoriser une proposition locale. Aucun audit Storage distant possible dans cette session, aucun changement distant. Deux migrations locales générées : 20261031220517_listing_photos.sql et 20261031220520_catalogue_search.sql. Fonction locale : supabase/functions/kibo-upload-listing-photo/. Le delta RLS de publication directe est inchangé et non appliqué par l'agent.

Prochain geste exécutable : réaliser l'audit distant autorisé en lecture seule de supabase/audits/listing_photos_readonly.sql, comparer tout contrat existant à la proposition (bucket privé, table, policies et périmètres). Le preflight photos refuse toute politique Storage existante : l'adapter seulement après revue, sans supprimer ni affaiblir les règles. Ne pas appliquer un reset/push global de migrations. Les photos restent désactivées par défaut ; la recherche textuelle nécessite son vecteur/index côté serveur. Filtres/tri sans texte utilisent les colonnes existantes.

Après revue : obtenir des autorisations distinctes pour les migrations exactes, le déploiement du validateur, puis les écritures de recette. Alors seulement activer KIBO_LISTING_PHOTOS_ENABLED au build et prévoir appareil Android : photos, interruption/reprise, catalogue/détail/Favoris, relance et isolation A/B. Pas d'installation/build ni test physique effectué pendant ce lot. Ne pas annoncer le flux distant fonctionnel à partir des tests simulés/fixture locale. Reprise photos en mémoire limitée au formulaire vivant ; cache natif/expiration réelle/quotas/concurrence Storage restent à vérifier.

Aucun commit, push, déploiement, migration distante ou donnée distante créé. Travail local préexistant conservé ; détails des fichiers dans la documentation du lot.

## Publication directe — cause distante confirmée et SQL final proposé

Les faits audités distants fournis par l'utilisateur remplacent le blocage historique d'accès ci-dessous : listings_insert_own autorise draft/pending seulement, published_at doit être NULL, authenticated possède INSERT et les triggers existants relevés sont BEFORE UPDATE. Le tuple published/date du client échoue donc au prédicat RLS INSERT ; cause identifiée sur la base de cet audit confirmé, sans réauditer ni inventer un export SQL complet.

Migration relue et **compatible avec les faits confirmés** : conserver sans modification supabase/migrations/20261031050000_direct_listing_publication.sql, SHA-256 3976C7FF2D33E3CB1998AC7146E6CCB4DE60259C7CA2220F0CA403E6E8E80969. Effet minimal : trigger BEFORE INSERT d'horodatage serveur et adaptation de la politique INSERT existante, propriétaire courant/vues 0/rejet NULL conservés ; aucune nouvelle politique OR, aucun élargissement de grant, aucun changement des triggers UPDATE/lecture/favoris ou des annonces existantes. Preflight transactionnel conservé, refus d'écart/collision à respecter.

Assertions de publication/propriété/champs protégés/favoris/ancien prédicat relues et couverture confirmée. Pas de nouvelle exécution : aucune donnée de test créée, même localement. Les réussites PostgreSQL précédentes restent historiques. Détails et limites de provenance dans RLS_PUBLICATION_AUDIT.md, section État courant ; trois documents de suivi uniquement modifiés, sources/tests/SQL préservés.

Étape suivante : autorisation distincte d'appliquer ce seul fichier complet avec son preflight, puis vérification des objets modifiés et recette distante séparément autorisée : publication A → heure serveur → catalogue → détail → favoris → isolation B. Pas d'audit distant répété, migration appliquée, annonce créée, commit ou push pendant cette revue. git diff --check exécuté ; pas de tests Flutter relancés pour cette revue documentaire.

## Nouvelle demande GitHub/Supabase — 2026-10-31 : connexions non exposées

Contrôle frais du registre des intégrations demandé par l'utilisateur : **GitHub et Supabase ont installed=false**, malgré leur statut de disponibilité ENABLED/AVAILABLE. Aucun outil GitHub/Supabase dans les outils actifs de cette session. Une suggestion Supabase existe déjà ; elle ne vaut pas connexion. Pas de nouvelle proposition identique ni d'installation automatique.

Contrôles locaux complémentaires sans valeurs : aucune variable Supabase/PG/DATABASE_URL dans Process/User/Machine ; config utilisateur MCP sans mention GitHub/Supabase ; pgpass zéro entrée ; CLI gh et Supabase absentes. Le remote Git origin Smeth/kibo existe, mais ne constitue ni une connexion GitHub authentifiée vérifiée ni un accès aux catalogues Supabase. Changements préexistants conservés.

Résultat : projet fcfmfpywpurrvppxdltm non interrogé ; **aucune définition SQL distante observée**, aucune exécution distante du script readonly et aucune cause exacte du 42501 démontrée. Compatibilité migration/distant **encore indéterminée**. Le conflit draft/pending/date NULL reste démontré uniquement sur la fixture locale et décrit dans le contrat historique.

Prochaine étape : terminer l'installation et l'authentification de Supabase dans la même session/application, puis vérifier l'apparition de ses outils et l'accès au projet avant de relancer l'audit readonly. Authentification uniquement dans le flux de connexion, sans clé dans le chat. Autre voie déjà préparée : connexion MCP officielle restreinte au projet en read_only=true, ou audit par l'opérateur dans Dashboard ; détails dans RLS_PUBLICATION_AUDIT.md. La connexion GitHub pourra permettre la lecture du dépôt, mais ne remplace pas l'accès SQL Supabase.

Seuls PROGRESS.md et NEXT_TASK.md actualisés. Migration, script d'audit, code et configuration inchangés ; git diff --check exécuté. Aucun SQL distant, donnée de test, commit ou push.

## Accès audit distant — 2026-10-31 : encore indéterminé

Nouvelle inspection Git/consignes, migration et script readonly effectuée. Aucun outil Supabase actif. Recherche d'intégrations : Supabase existe mais non installé/non connecté ; proposition présentée, aucune installation/connexion confirmée. Variables Supabase/PG/DATABASE_URL absentes de Process/User/Machine ; pgpass existant sans entrée non commentée, aucun pg_service, token CLI ou projet lié détecté. psql 13 disponible au chemin connu ; aucun accès distant configuré. Configurations MCP projet absentes ; config utilisateur sans mention Supabase (contenu non affiché). Aucun secret copié/affiché et aucune session extraite.

**Définitions SQL distantes observées : aucune. Script readonly non exécuté à distance. Compatibilité migration/distant : encore indéterminée.** Les clauses draft/pending/date NULL restent un contrat historique et une preuve sur fixture, pas des métadonnées distantes fraîchement vérifiées. Pas de nouvelle comparaison distante possible.

Action nécessaire : installer/connecter Supabase avec authentification utilisateur hors chat et vérifier les outils exposés ; pour restriction serveur explicite, connexion MCP officielle limitée au projet avec read_only=true et features=database (URL sans secret et étapes dans RLS_PUBLICATION_AUDIT.md). Alternative immédiate : opérateur déjà autorisé dans Dashboard KIBO > SQL Editor, exécuter uniquement supabase/audits/direct_publication_readonly.sql et récupérer tous les résultats des catalogues. Conserver BEGIN READ ONLY/ROLLBACK ; ne pas lancer la migration. Ne partager aucune clé, mot de passe ni URL de connexion avec secret. Revoir les corps de fonctions avant partage des résultats.

Docs RLS_PUBLICATION_AUDIT/PROGRESS/NEXT_TASK complétées ; code, migration et script SQL inchangés. Aucun appel Supabase distant, SQL appliqué, annonce distante, commit ou push. git diff --check contrôlé ; tests non relancés pour cette documentation et cet inventaire d'accès.

## Audit du refus 42501 — 2026-10-31 : preuve distante manquante

Compte A connecté confirmé par l'utilisateur. Code, migration et assertions relus. Le client envoie published et une date non NULL ; les clauses anciennes `status IN (draft,pending)` et `published_at IS NULL` refusent ce tuple sur la fixture. **Cause exacte distante non démontrée**, faute d'accès aux métadonnées : aucun outil Supabase connecté, aucune variable PG/Supabase administrative, aucune entrée pgpass exploitable ni token/projet CLI configuré détecté ; hôte navigateur indisponible et accès Chrome expiré sur l'autorisation. Aucune clé secrète demandée/affichée, aucun appel distant effectué.

Livrables : docs/RLS_PUBLICATION_AUDIT.md (preuves, hypothèses, accès, delta minimal conditionnel), supabase/audits/direct_publication_readonly.sql (catalogues uniquement, BEGIN READ ONLY/ROLLBACK), test/sql/direct_publication_ownership_assertions.sql (isolation UPDATE/INSERT, champs protégés et favoris). Migration et code existants inchangés. Le delta existant reste proposé seulement si l'audit exact confirme son contrat ; aucun grant large ni relâchement RLS ajouté.

Exécution réelle : pg_ctl démarre le seul cluster jetable connu sur 127.0.0.1:55459 ; pg_isready confirme sa disponibilité ; psql -X -v ON_ERROR_STOP=1 exécute assertions existantes, nouvelles assertions ownership, legacy_policy et audit readonly, tous code 0. Transactions de test annulées, pg_ctl stop -m fast réussi. Ancien prédicat refuse published ; B ne peut modifier/publier A, champs privilégiés verrouillés et favoris isolés. Tests exclusivement locaux, pas un audit du serveur réel.

Prochaine étape obligatoire : rendre disponible un accès de métadonnées autorisé ou faire exécuter le script readonly par l'opérateur déjà autorisé, puis comparer politiques/grants/triggers exacts et leurs fonctions dépendantes au delta. Ne pas appliquer la migration ni tester d'écritures distantes avant autorisation distincte. Aucun reset, commit, push, modification distante ou nouvelle annonce de test distante.

## Recette TECNO : refus de publication signalé — 2026-10-31

Observation utilisateur : connexion initialement nécessaire ; ensuite, au clic sur « Publier l'annonce », message « Publication refusée. Reconnectez-vous ou contactez l'assistance. ». L'utilisateur a donc atteint le formulaire et tenté une soumission ; identité A et état exact de session non vérifiés indépendamment.

Revue locale : listing_repository.dart transforme un PostgrestException code 42501 (droits insuffisants) en ListingPublicationDenied ; publish_listing_page.dart affiche précisément ce message. Il s'agit donc d'un refus d'autorisation signalé par le backend, sans preuve de la politique ou du trigger exact responsable. Hypothèse principale cohérente avec le contrat documenté : client INSERT published alors que l'ancienne politique n'accepte que draft/pending et delta non appliqué par l'agent. Les grants, triggers et identité peuvent également intervenir ; aucune conclusion distante définitive.

Commandes : git status --short --branch ; recherche rg du message/42501 ; adb shell pidof et logcat -d --pid=<processus> -v brief -t 300 filtré : aucun diagnostic correspondant PostgREST/42501/crash/exception Flutter dans cet extrait. L'erreur est gérée par l'application ; absence de log ne signifie pas absence du refus.

Recette arrêtée à la publication : catalogue de la nouvelle annonce, détail, favoris, relance fonctionnelle et isolation A/B non validés. Ne pas multiplier les soumissions ni changer RLS pour contourner le refus. Prochaine étape : audit en lecture seule des définitions exactes de politiques/grants/triggers et comparaison avec le delta préparé ; application uniquement après autorisation distincte. Aucune modification Supabase distante, migration appliquée, modification du code, commit ou push pendant ce diagnostic. Seuls PROGRESS.md/NEXT_TASK.md complétés, changements existants conservés.

## Installation TECNO et démarrage — 2026-10-31

Installation explicitement autorisée de l'APK debug déjà compilé, sans relancer les contrôles de compilation/configuration/présence ADB. État Git et consignes relus ; changements locaux conservés. Commandes exécutées avec le chemin ADB du SDK local et `-s H6929CK6NU012345` :

1. `install -r C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk` : **Success**, code 0. Aucune désinstallation ou suppression de données.
2. `shell am start -W -n com.kibo.kibo/.MainActivity` : **Status ok**, démarrage COLD, TotalTime 5405 ms. `shell pidof com.kibo.kibo` : processus 31269 au premier contrôle. `shell dumpsys activity activities` : MainActivity au premier plan.
3. `logcat -d --pid=<processus> -v brief -t 200` puis nouvel extrait de 300 lignes : aucun FATAL EXCEPTION, Unhandled Exception ou E/flutter observé. Avertissements OEM Transsion/ClassNotFound et erreurs de négociation de formats OpenGL/gralloc/AHardwareBuffer présents ; application toujours active. Cela ne prouve pas le rendu visuel, la connexion Supabase ou le succès fonctionnel. Les sorties utiles ont été filtrées sans clé/JWT/URL ; aucun journal brut versionné.

Recette physique guidée, **en attente d'observations utilisateur** : préparer sous A une annonce sans photo, titre Test KIBO 31-10, description fictive, 1000 XAF, catégorie active et Brazzaville. Après soumission unique : relever exactement confirmation ou erreur, puis si succès vérifier carte catalogue, détail, ajout/retrait synchronisés et persistance après relance, puis isolation de B. Ne pas multiplier les soumissions après erreur réseau non confirmée. Aucun de ces résultats fonctionnels n'est encore constaté ; installation et démarrage seuls réussis.

Le suivi indique un delta de publication directe non appliqué au serveur par l'agent et un audit RLS distant restant. Aucun changement distant SQL/RLS/configuration effectué pour contourner un refus éventuel. Aucun INSERT/DELETE distant exécuté par l'agent, aucun commit ni push. La prochaine étape est le retour utilisateur sur le formulaire et, si la recette est effectuée, son résultat exact ; ne pas marquer création/catalogue/détail/favoris/isolation comme validés sans observation.

## APK debug configuré compilé — 2026-10-31

Cette vérification remplace le blocage historique de fichier absent ci-dessous. config/supabase.local.json est présent, ignoré par `/config/*.local.json` et non suivi. Ses champs SUPABASE_ANON_KEY et supabaseAnonKey contiennent la même clé reconnue comme publique ; son URL dupliquée est identique à config/supabase.public.json. Aucun contenu sensible affiché et aucune configuration modifiée. Le premier contrôle exigeant un champ unique a été arrêté ; après inspection des seuls noms de champs et vérification de leurs valeurs en mémoire, ces doublons bénins ont été conservés. Recherche indicative des fichiers suivis/non ignorés : aucune copie des clés locales, clé sb_secret réelle, JWT service_role ou clé privée détectée ; ce contrôle ne constitue pas une garantie exhaustive.

Inventaire : main, HEAD bca1aa2, origin Smeth/kibo, index vide ; 25 fichiers suivis modifiés et 48 non suivis préexistants conservés. Empreintes avant/après compilation, configuration locale comprise : aucun changement. Seuls PROGRESS/NEXT_TASK complétés pour cette tâche ; sorties build ignorées.

Commande exécutée avec les dépendances existantes et accès autorisé aux caches locaux :

```powershell
& 'C:\flutter\bin\flutter.bat' build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

Résultat : **code 0**, assembleDebug 69,5 s. APK confirmé par Get-Item/Get-FileHash :
- Chemin : C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk
- Taille : 110695992 octets.
- SHA-256 : 781D42361722E8121B5A601FC75552DDA76301CF0F7AD41BE17E51DB638AF511.
- `aapt dump badging` : com.kibo.kibo, version 1.0.0 (1), application-debuggable, min SDK 24, cible 36, arm64-v8a présent (l'APK debug contient aussi des bibliothèques armeabi-v7a/x86_64).

`git check-ignore -v`, `git ls-files`, recherche locale sans valeurs, inventaire/empreintes, `git diff --check`, `adb devices -l`, `get-state` et `getprop ro.product.model` effectués : exclusion correcte, diff check réussi (avertissements LF/CRLF préexistants), TECNO CK6n H6929CK6NU012345 en état device, encore détecté après compilation. Les tests/analyse de la précédente session ne sont pas présentés comme relancés ici. Aucun appel Supabase ou changement distant ; compilation seule ne valide ni connexion réelle ni publication directe.

Prochaine action : attendre la confirmation explicite d'installation, puis utiliser uniquement :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s H6929CK6NU012345 install -r 'C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk'
```

Aucune installation, désinstallation, ouverture de l'application, modification Supabase distante, migration, commit ou push effectué. La recette réelle de publication reste soumise aux prérequis RLS et autorisations distinctes déjà documentés.

## Préparation APK configuré — 2026-10-31 : bloquée avant compilation

Nouvelle inspection sur main : 25 fichiers suivis modifiés, 48 non suivis, index vide, remote origin Smeth/kibo. Empreintes comparées avant cette note : aucun fichier préexistant modifié/supprimé. Aucun nettoyage ou remplacement.

`git check-ignore -v config/supabase.local.json` confirme la règle `/config/*.local.json` ; `git ls-files --error-unmatch` confirme que ce chemin n'est pas suivi. Cependant **le fichier config/supabase.local.json est absent du dépôt local accessible**, malgré l'annonce de sa saisie. Inventaire de config/ : uniquement supabase.public.json et supabase.local.example.json. Variables SUPABASE_URL/SUPABASE_ANON_KEY absentes dans Process/User/Machine. Le contrôle initial du JSON a donc échoué avant toute compilation ; aucun build lancé ni APK courant certifié. Aucun secret créé, remplacé, extrait ou affiché.

Recherche indicative dans les fichiers suivis/non ignorés : aucun candidat réel sb_secret, JWT service_role ou clé privée. Seul candidat sb_secret détecté dans test/core/supabase_config_test.dart : valeur explicitement fictive du test de rejet des clés privilégiées, relue et confirmée. Ce contrôle ne certifie pas tout secret possible ni le contenu du fichier absent.

`adb devices -l`, `adb -s H6929CK6NU012345 get-state` et `shell getprop ro.product.model` confirment TECNO CK6n, état device. Aucune installation ou lancement de l'application. Aucun changement Supabase distant, commit ou push.

Prochaine étape : enregistrer le fichier local au chemin exact C:\Users\MONSTER\Documents\WORKSPACE\KIBO\config\supabase.local.json, uniquement avec SUPABASE_ANON_KEY publique, selon DEVELOPMENT_SETUP ; ne pas transmettre sa valeur dans le chat. Après vérification locale, commande de compilation prévue, non exécutée :

```powershell
& 'C:\flutter\bin\flutter.bat' build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

APK attendu après succès, non certifié par cette tentative : C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk. Installation uniquement après confirmation explicite et compilation réussie :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s H6929CK6NU012345 install -r 'C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk'
```

## Résultat le plus récent — 2026-10-31, Android disponible

Cette section actualise les constats historiques ci-dessous : ADB confirme **TECNO CK6n / Android 14 / arm64-v8a**, état `device`, identifiant H6929CK6NU012345. Aucune installation exécutée. Format conforme (50 fichiers), analyse stricte réussie, **95 tests Flutter + 1 parcours simulé complet avec retrait du favori réussis**. Migration rejouée sur une nouvelle fixture PostgreSQL isolée : assertions et refus de l'ancien prédicat réussis ; cluster arrêté. Détails, commandes et incidents de lancement dans la dernière vérification de PROGRESS.md.

Blocages restants : clé publique locale absente ; métadonnées RLS distantes non auditées, delta non appliqué par l'agent. Préparer localement la clé selon DEVELOPMENT_SETUP, compiler avec les deux JSON puis obtenir confirmation avant `adb install -r`. Aucun lancement automatique de `flutter run` (il installerait l'application). Après autorisations distinctes du delta distant et des écritures de test : recette création sans photo → publication immédiate/date serveur → catalogue → détail → ajout/retrait favoris → relance et isolation A/B/visiteur. Aucun commit, push ou changement distant autorisé ici.

## Dernière reprise locale — 2026-10-31

KIBO-008/009/010 et publication directe : code et migration relus, format vérifié (50 fichiers, aucun changement), analyse stricte sans anomalie et **95 tests Flutter réussis**. Assertions PostgreSQL sur la fixture locale déjà migrée et contrôle de refus de l'ancienne politique relancés avec succès ; transactions annulées et cluster jetable arrêté. Aucun SQL distant, modification de code, commit ou push. Résultats et limites dans [PROGRESS.md](PROGRESS.md#reprise-des-vérifications-locales-kibo-008009010-et-publication-directe).

Blocages réels : aucun Android détecté par Flutter/ADB ; clé publique absente du fichier local et des environnements vérifiés ; delta distant non appliqué et définitions complètes distantes non relues. Ne pas présenter la publication réelle comme validée. Le preflight de migration ne vérifie pas le texte complet du prédicat existant : audit exact nécessaire, pas seulement le nom de la politique.

Prochain geste manuel : connecter le TECNO, activer/autoriser le débogage USB, puis contrôler son modèle/état. Préparer la configuration locale selon DEVELOPMENT_SETUP et reconstruire avant recette ; **installation uniquement après confirmation**. Commande de build préparée, non exécutée pendant cette reprise :

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

Une fois le delta revu et appliqué avec autorisation distincte, recette sur données de test : publication sans photo -> carte du catalogue -> détail relu -> ajout/retrait favori -> redémarrage et isolation A/B. Aucun reset, push global de migrations ou modification de données pour contourner les blocages. Voir [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md) et [LISTINGS.md](LISTINGS.md).

## Continuité du développement

Lire [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) avant la reprise. URL publique centralisée dans `config/supabase.public.json`, modèle de clé fictive séparé et configuration réelle locale ignorée ; pas de modification du démarrage Flutter. La clé réelle n'a pas été enregistrée pendant cette préparation. Réutiliser la configuration existante avant toute nouvelle saisie. Aucun commit, push ou changement distant sans autorisation explicite. La prochaine étape fonctionnelle reste l'audit et l'autorisation du delta de publication directe ci-dessous.

## Lot courant — KIBO-008/009/010
**Objectif courant : publication immédiate sans modération préalable.** Prix obligatoire XAF conservé, catalogue published uniquement, sans négociabilité/images. L’ancien flux pending est remplacé dans Flutter ; le delta RLS/horodatage serveur est préparé mais non appliqué au projet distant. Détails : [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md).

Prochaine étape requise : auditer les politiques/grants/triggers réellement déployés puis obtenir l’autorisation explicite d’appliquer uniquement `supabase/migrations/20261031050000_direct_listing_publication.sql`. Aucun SQL distant, commit ou push exécuté. Le schéma initial n’est pas versionné : ne pas utiliser un reset ou un push global pour reconstituer la base.

Contrôles courants : formatage 50 fichiers, analyse stricte sans anomalie, **95 tests Flutter réussis** et diff check réussi. Delta exécuté avec succès sur PostgreSQL 13 temporaire et fixture fictive, assertions RLS/horodatage/isolation positives ; ancienne politique refuse published comme attendu. Instance temporaire arrêtée. Ces résultats ne valident pas Supabase distant.

Recette précédente : création unique pending vérifiée, vendeur correct et 1000 XAF, absence du catalogue, erreur réseau puis reprise/état vide réussis. Pas de publication administrative disponible. Le contrôle REST du compte présumé A renvoie zéro ligne, identité propriétaire non confirmée ; B non testé. Détail publié, favoris et archivage distants restent non exécutés. Le nouveau flux nécessite une nouvelle recette après migration autorisée ; aucune ancienne annonce n’est publiée par le delta.

### Historique des validations initiales du lot (flux pending)

- KIBO-008 : implémentée localement, 74 tests réussis, formatage/analyse/diff check réussis ; recette réelle non effectuée.
- KIBO-009 : implémentée localement, 80 tests réussis, formatage/analyse/diff check réussis ; recette publique réelle non effectuée.
- KIBO-010 : implémentée localement, favoris partagés, isolation/expiration de session et refus RLS simulés testés ; suite intégrée de 91 tests réussie, analyse stricte et diff conformes. Une couverture responsive de publication a également été ajoutée.

Les trois lots initiaux ont été validés localement avec 91 tests avant le changement de flux. Les validations courantes de publication directe et les limites SQL locales sont consignées dans [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md) et [PROGRESS.md](PROGRESS.md). Aucun package ajouté, aucune publication distante effectuée par l’agent.

Travail séquentiel sur main sans déplacer les modifications locales ; aucune modification Supabase distante, dépendance, commit ou push. KIBO-006 conserve son blocage HTTP 429 de recette ; KIBO-007 conserve sa recette réussie documentée.

## KIBO-001 — Socle Flutter
**Statut : terminée et vérifiée sur `main`.**

Commit du socle : [4d7ccd38a98c0868737cb801bc5f79a2fcb1e283](https://github.com/Smeth/kibo/commit/4d7ccd38a98c0868737cb801bc5f79a2fcb1e283).

Commit de clôture documentaire communiqué : [7f9782d55abb84879896bf42d512ff2cf459652d](https://github.com/Smeth/kibo/commit/7f9782d55abb84879896bf42d512ff2cf459652d).

- Dépôt propre, `main` synchronisée avec `origin/main`, selon le compte rendu de clôture.
- `flutter pub get`, formatage Dart, `flutter analyze --fatal-infos`, `flutter test` et `git diff --check` : réussis.
- CI GitHub : [exécution 41129735329 réussie](https://github.com/Smeth/kibo/actions/runs/41129735329).
- Aucun projet recréé, aucune suppression, branche, PR ou force-push.
- Issue : https://github.com/Smeth/kibo/issues/1 (clôturée).

## Workflow applicable
Le propriétaire a choisi Direct Main le 2026-10-30. Pour les tâches courantes : travailler sur `main`, préserver les modifications locales, tester avant commit et push, ne jamais faire de force-push. En cas de diff inattendu ou de test échoué, ne pas pousser.

## KIBO-002 — Connexion Supabase
**Statut : terminée, test réel inclus, confirmé par le propriétaire le 2026-10-31.**

Issue de référence : https://github.com/Smeth/kibo/issues/2. Implémentation : [`ed1d4fc`](https://github.com/Smeth/kibo/commit/ed1d4fc2997aa914a06e8a78cf4ecf6e1db3e988).

Sur TECNO CK6n / Android 14 : SDK Supabase initialisé, accueil KIBO affiché, requête HTTPS en lecture seule depuis le téléphone -> HTTP 401 sans clé publique et HTTP 200 avec la clé publique. Aucune valeur de clé publiée dans le chat ou Git ; aucun fichier source modifié, commit ou push pendant le test réel. Les détails, la CI réussie et les limites sont conservés dans [PROGRESS.md](PROGRESS.md).

## KIBO-003 — Socle UI Manrope / Emerald
**Statut : implémentation terminée, contrôles locaux réussis le 2026-10-31.**

Le propriétaire a validé le périmètre et autorisé l’implémentation sur `main`. Manrope 400/600/800 est embarquée localement depuis la source officielle, avec licence SIL OFL 1.1. Palette et thème clair centralisés ; accueil harmonisé sans changement fonctionnel ni modification du service ou de la configuration Supabase.

Validations réussies : `flutter pub get`, `dart format lib test`, `flutter analyze --fatal-infos`, `flutter test` (**24 tests, dont les 13 existants inchangés**), `flutter build apk --debug --target-platform android-arm64` et `git diff --check`. Tests responsive avec vraies polices et aperçus locaux inspectés ; aucun nouveau test physique TECNO ni test réseau Supabase réalisé pour cette intégration UI.

Provenance, licence et structure du thème : [UI_THEME.md](UI_THEME.md). Résultats détaillés et limites : [PROGRESS.md](PROGRESS.md). Le commit, le push et le statut CI sont fournis dans le compte rendu de livraison. Aucune issue KIBO-003 attribuée à ce stade.

## KIBO-003.1 — Corrections responsive et alignement des cartes
**Statut : terminée et publiée sur `main`.** Commit : [`bca1aa2`](https://github.com/Smeth/kibo/commit/bca1aa2b3ced41c2de3fb8f80f3d8dc88aac15a0). [CI réussie](https://github.com/Smeth/kibo/actions/runs/41149539924), 30 tests locaux et build debug ARM64 réussis. Les trois corrections ont été vérifiées sur TECNO à 100 % et 150 %, avec cinq destinations et quatre annonces accessibles ; réglage initial du texte restauré. Historique et limites dans [PROGRESS.md](PROGRESS.md).

## KIBO-004 — Préparation conservée
**Statut : décisions fonctionnelles validées, audit des prérequis réalisé ; implémentation non commencée.**

Les règles validées de prix, localisation, archivage/favoris et photos sont centralisées dans le [cahier des charges](CAHIER_DES_CHARGES.md#règles-des-annonces--décisions-kibo-004). Leurs conséquences et les choix techniques ouverts figurent dans [DECISIONS_TECHNIQUES.md](DECISIONS_TECHNIQUES.md#2026-10-31--préparation-du-backend-kibo-004). Le maximum de trois photos remplace l’ancienne limite de huit.

### Avant l’implémentation
1. Valider le runtime et le mode/version de CLI proposés dans [l’audit local](SUPABASE_SETUP.md#préparation-de-la-pile-locale--audit-du-2026-10-31), puis autoriser séparément leur installation. Docker/Podman et la CLI Supabase n’ont pas été détectés ; le PostgreSQL existant ne doit pas être modifié ou réutilisé implicitement.
2. Finaliser les champs publics/privés, contraintes de prix, statuts/transitions et matrice des opérations RLS pour profils, catégories, annonces, photos et favoris.
3. Choisir et tester le protocole serveur d’upload : nombre de photos en concurrence, taille réelle maximale, formats, photo principale, ordre et nettoyage des orphelins. Une contrainte SQL sur les métadonnées ne garantit pas la conformité du fichier Storage.
4. Définir l’accès aux photos du bucket privé, le comportement lors d’un archivage/masquage et les règles de conservation/purge contrôlée.
5. Préparer une stratégie de migrations reproductibles et de tests isolés : visiteur, utilisateurs distincts, modération, lectures interdites, archivage/favoris, uploads concurrents et fichiers non conformes. Adapter ultérieurement la CI aux chemins backend et aux tests SQL/RLS/Storage.
6. Avant toute future application distante, obtenir un inventaire autorisé des métadonnées du projet Supabase et le comparer aux migrations prévues ; aucun accès distant pendant la présente intervention.

### Limites de cette intervention
Aucune migration métier créée ou déployée à ce stade ; état des métadonnées distantes non vérifié. Modifications documentaires uniquement : aucun SQL, changement Flutter, ajout de dépendance, installation, changement de service, commit, push ou création d’issue. L’implémentation de KIBO-004 et toute installation attendent une autorisation ultérieure du propriétaire.

## KIBO-005 — Authentification
**Statut : parcours implémenté localement et recette réelle TECNO réussie, sans commit ni push.**

Inscription/connexion email-mot de passe, confirmation email sans session, état de compte réactif et déconnexion depuis Profil. Accueil public et thème conservés. Session persistante/auto-refresh avec stockage chiffré et protections de sauvegarde Android. Le profil est créé exclusivement par le trigger existant confirmé par le propriétaire puis récupéré par Flutter ; aucun INSERT/UPSERT client ni changement RLS/SQL.

Contrat, architecture, tests et procédure manuelle : [AUTHENTICATION.md](AUTHENTICATION.md). Résultats des commandes : [PROGRESS.md](PROGRESS.md). Les huit modifications documentaires préexistantes sont conservées. Aucune migration KIBO-004 créée ou déployée.

Recette confirmée par le propriétaire : inscription et email, connexion, récupération du profil existant, session après arrêt/redémarrage, déconnexion persistante et second compte. Le rafraîchissement après expiration et le hors réseau restent à vérifier physiquement. La redirection localhost est traitée par KIBO-006. Ne pas transmettre de mot de passe, lien, token ou clé. Ne modifier aucune politique distante pour faire réussir un test. Aucune publication sans demande explicite du propriétaire.

## KIBO-006 : confirmation email Android — recette en attente
**Statut : callback implémenté et installé ; recette native bloquée à l’inscription par HTTP 429. Aucun commit ni push.**

Callback dédié `com.kibo.kibo://auth/confirm`, envoyé au signup et déclaré dans Android. Réception par le SDK existant, filtrage de l’adresse et PKCE chiffré conservé ; formulaire fermé lorsque la session arrive. Aucun nouveau package, SQL ou changement RLS.

Le propriétaire confirme les réglages Redirect URLs, Site URL et template prêts, puis la compilation/installation réussies et KIBO affiché sur TECNO. Android résout le callback vers MainActivity. La nouvelle inscription est refusée par HTTP 429 ; la requête confirme le bon redirect, mais le code précis de limitation reste inconnu. Aucun échange PKCE réel de KIBO-006 n’est encore validé.

Reprendre après levée de la limitation, sans tentatives répétées : nouvel email à chaud puis à froid, erreurs de lien et persistance. Ne pas désinstaller ni effacer les données entre inscription et confirmation. Procédure et limites dans [AUTHENTICATION.md](AUTHENTICATION.md). Ne jamais partager les liens ni les jetons.

## KIBO-007 : modifier son profil — recette réussie
**Statut : implémentation locale terminée ; scénarios de recette demandés réussis sur TECNO avec deux comptes. Sans commit ni push.**

Permettre au compte connecté de modifier son nom affiché (`full_name`, facultatif) et sa ville (`city`, obligatoire). Formulaire français prérempli, validation, chargement, annulation et erreurs sans détails bruts. Mettre à jour uniquement le profil de la session courante, via UPDATE des deux champs et filtre `id`, en respectant RLS ; aucun INSERT/UPSERT, migration, nouveau package ou modification de Supabase distant.

Conserver KIBO-005 et KIBO-006, thème, accueil et stockage sécurisé. Tester les validations, mises à jour acceptées/refusées, absence de session, changements de compte et rendu avec clavier/texte agrandi. Exécuter formatage, analyse stricte, tests et diff check ; distinguer simulations et recette distante encore nécessaire.

Réalisé : formulaire et validation dans `features/profile/`, UPDATE limité et filtré, réponse serveur contrôlée, protection contre les doubles soumissions et réponses tardives, indication des champs publics et annulation sans écriture. Les 53 tests précédents sont conservés et 14 tests ajoutés. Formatage, analyse stricte et diff check réussis.

Recette physique autorisée et réalisée après l’implémentation : APK local/installé identiques par SHA-256, préremplissage, UPDATE des deux champs, session et valeurs après arrêt complet, annulation, erreur hors réseau avec saisies conservées puis reprise réussie. Second compte : profil propre et sauvegarde réussie ; premier compte reconnecté ensuite, valeurs intactes sur les deux écrans. Résultats confirmés par le propriétaire, détaillés dans [PROFILE.md](PROFILE.md). Aucun réglage Supabase ni code modifié pendant cette recette ; les UPDATE autorisés passent uniquement par l’application.

Limites restantes : refus RLS d’une requête ciblant volontairement un autre compte non testé sur le serveur ; isolation validée uniquement dans le parcours normal. Ville vide, nom effacé et rendu à 100 %/150 % non exercés physiquement pendant cette recette, malgré leur couverture automatisée. KIBO-006 reste en attente séparément ; KIBO-008/009/010 sont maintenant définies dans le lot courant en tête de document. Ne pas modifier les droits serveur pour faire réussir un test.

Contrôles après recette : `dart format lib test` (31 fichiers, 0 changement), `flutter analyze --fatal-infos` (aucune anomalie), `flutter test --reporter expanded` (67 réussis) et `git diff --check` réussis. Seuls les deux documents de recette sont actualisés ; code, paramètres Supabase et autres modifications locales conservés, aucun commit ni push.


## Vérification locale de reprise — 2026-10-31 (sans publication distante)

Les vérifications demandées KIBO-008/009/010 et publication directe sont exécutées localement : formatage sans réécriture (50 fichiers), analyse stricte conforme, **95 tests Flutter + 1 scénario temporaire complet ajout/retrait sur l'annonce créée**, assertions PostgreSQL/RLS et refus de l'ancien contrat/réapplication réussis selon les résultats attendus. Grants, autres politiques et trigger UPDATE de la fixture conservés. Les instances PostgreSQL temporaires sont arrêtées. Résultats, commandes et incident de lanceur résolu dans la dernière section de [PROGRESS.md](PROGRESS.md).

Le travail initial sur main est conservé : aucun fichier applicatif, migration, test existant ou paramètre local modifié ; seuls des ajouts dans les deux fichiers de suivi. Aucun commit, push ou changement distant.

### Prochaine action locale exécutable

1. Connecter l'Android et autoriser le débogage USB. Refaire `adb devices -l` ; s'il apparaît, relever `adb -s <identifiant> shell getprop ro.product.model` et `adb -s <identifiant> shell getprop ro.build.version.release`. À cette reprise, ADB est vide et Flutter ne liste que Windows/Chrome/Edge : ne pas présumer le TECNO connecté.
2. Vérifier la configuration selon [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md). Le fichier local de clé manque et aucune variable publique n'a été trouvée aux trois portées Windows. Réutiliser toute configuration devenue disponible avant saisie ; sinon renseigner la seule clé publique localement, sans valeur dans le chat et sans service_role. Aucun fichier existant ne doit être remplacé.
3. Compiler seulement quand configuré : `flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json`. Cette commande n'est pas exécutée pendant la vérification. Ne pas utiliser `flutter run` pour préparer : il peut installer/lancer.
4. Préparer `adb -s <identifiant-confirmé> install -r build/app/outputs/flutter-apk/app-debug.apk`, mais **ne pas l'exécuter sans confirmation explicite**. Préserver les données/PKCE, ne pas désinstaller ni effacer le stockage de l'application. Choisir une architecture compatible avec l'appareil réellement identifié.

### Recette publication directe : prérequis et premier test

L'état distant reste non vérifié et inchangé. L'ancien contrat communiqué refuse published : ne pas lancer une création réelle pour contourner ce blocage. Il faut d'abord un inventaire autorisé des politiques/grants/triggers, comparaison au delta, puis autorisation distincte de son application ciblée. Aucun reset ou push global Supabase. Le preflight local ne vérifie pas le corps exact de l'ancien prédicat et ne vaut pas audit distant.

Après audit/migration, installation confirmée et autorisation des écritures de test : sous le compte A, publier une annonce fictive à 1000 XAF avec catégorie active, vérifier sa visibilité immédiate et sa date serveur, ouvrir le détail, ajouter le favori, vérifier carte/détail/Favoris, le retirer puis vérifier les trois vues et la persistance après relance. Continuer avec B/visiteur et les tests de refus/isolation autorisés. Les tests simulés et la fixture locale ne certifient pas cette recette physique/distante.

Blocages actuels : aucun Android connecté, configuration locale de clé absente, métadonnées Supabase réelles non auditées et delta non appliqué. Aucune autorisation d'installation ou d'écriture distante déduite de la demande de vérifications locales.
