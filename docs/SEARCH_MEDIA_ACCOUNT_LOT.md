# Recherche, photos et suppression de compte — 2026-11-02

## Périmètre demandé

Travail local sur `main`, changements préexistants préservés et inventoriés dans `.dart_tool/lot-search-photo-delete-status.txt`. Aucun commit/push. Les propositions SQL et fonctions Edge ci-dessous ne sont pas encore déployées. Aucune suppression de compte réel n’est autorisée comme recette par cette demande.

### Recherche

`supabase/proposals/discovery_search_v2.sql` : index simple normalisé sans accents, préfixes cohérents, tolérance bornée à une ou deux erreurs selon la longueur, synonymes français explicites, suggestions issues exclusivement d’annonces publiées et soumises aux mêmes filtres, classement privilégiant le titre. Les critères de prix, ville et catégorie restent appliqués. Classement stable par date et identifiant pour départager les résultats. Les corrections ne couvrent pas toutes les fautes ni tous les synonymes : dictionnaire initial limité et vocabulaire publié.

Flutter : suggestions après 350 ms et trois caractères, choix Pertinence par défaut, chargement automatique à proximité du bas avec une seule requête simultanée, dédoublonnage et reprise explicite après erreur. Décalage serveur distinct du nombre d’annonces affichées. La pagination par décalage ne constitue pas un instantané du catalogue : des changements simultanés peuvent encore déplacer une annonce entre les pages.

### Photos après publication

`supabase/proposals/listing_media_management.sql`, nouvelle fonction `kibo-manage-listing-photos` et mise à jour de `kibo-upload-listing-photo`. L’écran Gérer les photos permet ajout, retrait, ordre et couverture, au maximum trois photos. Remplacer une photo consiste à la retirer puis à en ajouter une. Les photos en place sont conservées tant que les nouveaux fichiers ne sont pas vérifiés. Changement de métadonnées atomique, révision contre les modifications concurrentes et identifiant d’opération stable pour reprendre une réponse perdue. Les détails saisis dans l’éditeur restent présents ; leur contrôle de concurrence n’est pas remplacé silencieusement lorsqu’une autre modification de contenu est intervenue.

Les anciennes images sont retirées via Storage API, jamais en supprimant directement `storage.objects`. Le nettoyage non confirmé reste dans une file privée et est repris à l’ouverture/sauvegarde suivante de la galerie. Les préparations abandonnées expirées après 24 h sont nettoyables au prochain passage du propriétaire ; pas de promesse de purge immédiate en arrière-plan sans nouvelle ouverture. Les transferts actifs sont exclus.

Un ticket de transfert est créé avant chaque écriture Storage, y compris la publication initiale. Une interruption serveur au résultat inconnu laisse ce ticket actif et bloque une suppression de compte. **Ne pas effacer arbitrairement ces tickets ni appliquer un délai aveugle** : vérifier que le traitement est terminé et le fichier présent/absent avant réconciliation opérateur. C’est un cas de maintenance rare, pas une confirmation de succès.

### Suppression définitive

Réutilisation de `supabase/proposals/retained_history.sql` pour les archives privées, puis `account_deletion_execution.sql`, `account_deletion_expiry_cron.sql` et nouvelle fonction `kibo-delete-account`.

Parcours : Compte et données → demande → Administration → demandes de compte → examiner/passer en cours → Supprimer définitivement → saisie SUPPRIMER. Le serveur vérifie le rôle administrateur auprès d’Auth et une connexion datant de moins de dix minutes. La suppression de son propre compte administrateur ou d’un autre administrateur est refusée par ce parcours. Il faut retirer ce rôle dans une procédure distincte avant de traiter une telle demande.

Le compte est gelé, ses anciennes sessions sont bloquées par le contrôle REST préalable et les restrictions RLS. Les écritures d’échanges et transferts de photos sont coordonnées avec le gel. Les contributions des autres participants sont conservées en privé ; les messages de l’ancien compte sont remplacés par « Message anonymisé ». Les commentaires/réponses concernés quittant le catalogue sont copiés uniquement pour leur propre auteur. Le profil, les annonces, les coordonnées, les favoris et autres données rattachées sont purgés ; les notifications et signalements ciblant les éléments retirés sont supprimés pour éviter des références personnelles restantes. Les fichiers sont supprimés via Storage API, puis l’utilisateur via Auth Admin API. La fin n’est déclarée qu’après vérification de l’absence du profil, des annonces, des objets et de l’utilisateur Auth. L’opération reste reprenable dans la file Administration même après retrait du profil.

**Conservation choisie et confirmée par l’utilisateur : 15 jours.** Compte et données → Échanges conservés donne un accès en lecture seule aux copies privées. Les politiques les rendent inaccessibles à expiration ; une tâche horaire supprime physiquement les lignes expirées (retard maximal habituel d’une heure pour cette purge). Les identifiants techniques de gel et de suivi restent privés pour bloquer les anciens JWT et éviter les reprises incohérentes. Les copies déjà exportées par un destinataire et le cycle des sauvegardes du prestataire sont hors de cette purge applicative.

## Activation et ordre de déploiement

AGENTS.md impose un accord explicite avant modification distante. Après cet accord uniquement :

1. Recherche V2, puis contrat media (aucune suppression déclenchée).
2. Remplacer l’uploader existant par la version utilisant les tickets ; déployer le gestionnaire de galerie avec vérification JWT activée. Vérifier qu’aucun ancien upload n’est en cours avant d’activer l’exécution des suppressions.
3. Archives privées, contrat de suppression, fonction de suppression et tâche horaire d’expiration. Le précontrôle refuse d’écraser un autre hook PostgREST préalable.
4. Contrôles de schéma, ACL/RLS, recherche réelle anonyme et conseillers, sans supprimer un compte ni modifier une annonce comme recette.
5. Compiler/installer sans effacement avec `scripts/Launch-KiboAndroid.ps1 -ProfileMode -EnableDiscoveryV2 -EnableMediaManagement -EnableAccountDeletion`.

Les trois options sont désactivées par défaut tant que le serveur n’a pas reçu les contrats. La pagination automatique est déjà un changement client indépendant.

## Vérification

Fixtures PostgreSQL isolées via `scripts/Test-OwnerManagementSql.ps1 -Suite Media` (inclut Discovery) et `-Suite Deletion`. Transports Auth/Storage/REST simulés dans les tests Edge. Tests Flutter des contrats RPC, des reprises de galerie, de la confirmation administrative et de la pagination ; analyse stricte et suite générale avant installation.

Les résultats finaux et l’état distant seront consignés dans PROGRESS.md. Les tests locaux ne constituent pas une suppression réelle ni une recette sur deux téléphones. Toute suppression d’un compte de recette précis exige une autorisation séparée de son propriétaire.
