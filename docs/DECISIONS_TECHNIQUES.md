# Décisions techniques — KIBO

## 2026-11-01 — Favoris visiteurs locaux

Décision produit explicitement approuvée : ajout/retrait sans connexion, persistance sur l'appareil, proposition de transfert après connexion. Réutiliser flutter_secure_storage existant avec clé par projet et IDs seuls, sans snapshot de contenu. Aucun changement Supabase/RLS : lecture publique existante, puis INSERT authentifié et confirmation par relecture des IDs du compte. Jamais de synchronisation automatique, de copie des favoris du compte vers le stockage visiteur ou de transfert implicite à un autre compte. Erreurs partielles : ne retirer localement que les éléments confirmés ; reprise idempotente via le repository existant. Détails dans [GUEST_FAVORITES.md](GUEST_FAVORITES.md).

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
| Photos | Maximum 3 par annonce ; règles dans le cahier des charges |
| Visiteurs | Consultation publique sans compte |
| Auth | Téléphone OTP, Google OAuth, email/mot de passe |
| Paiement et livraison | Hors V1 |
| Thème | Clair au lancement |

## Points non encore validés
Pour les annonces/catégories/favoris, les contrats déployés ont été communiqués. Le prix obligatoire est conservé mais la publication administrative précédemment validée est remplacée par une publication immédiate au lancement. Le delta RLS reste préparé, non appliqué : [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md). Aucune modification distante autorisée par cette décision.

Fournisseur SMS et fonctionnement au Congo ; identifiant Android définitif ; schéma PostgreSQL et politiques RLS ; mécanisme d’accès au bucket privé et protocole d’upload ; technologie de l’administration web ; exigences légales et processus de modération.

Toute nouvelle décision importante doit être ajoutée ici avec date, contexte et conséquences.

## 2026-10-31 — Publication immédiate au lancement

Le propriétaire demande de remplacer la création pending par published sans modération préalable. Flutter transmet le statut et une date UTC, exige le retour published daté, puis relit le catalogue. La politique INSERT communiquée refuse ce flux ; un delta transactionnel est préparé avec horodatage serveur BEFORE INSERT et remplacement du seul WITH CHECK d’insertion. Pas de nouvelle politique permissive parallèle, de SECURITY DEFINER, de suppression de RLS ou de modification des protections UPDATE/favoris.

Les anciennes voies draft/pending et le défaut de table sont conservés pour compatibilité ; le client courant demande published explicitement. Les anciennes lignes ne sont pas promues. Le trigger normalise la date de tous les nouveaux INSERT published, y compris administratifs. Le preflight bloque des politiques ou triggers INSERT non prévus pour revue. Migration et RLS testées sur PostgreSQL 13 jetable avec fixture fictive, pas sur Supabase distant ; aucune application sans autorisation explicite. Les procédures et les limites sont centralisées dans [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md).

## 2026-10-30 — Initialisation Supabase (KIBO-002)

Configuration publique par `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), centralisée sans fichier de secrets ni valeur réelle versionnée. Les formats publishable et JWT anon sont acceptés ; le contrôle local ne vérifie pas la signature ni la joignabilité et ne remplace pas RLS.

Un service injectable, créé au démarrage, mémorise l’initialisation et expose le client après réussite. Configuration manquante/invalide ou erreur SDK : écran explicite sans crash ni affichage de l’exception. Pas de retry implicite : correction et relancement nécessaires. Persistance de session, rafraîchissement et liens d’authentification désactivés jusqu’à la tâche dédiée. Cette décision prépare l’accès SDK sans implémenter de fonctionnalité métier.

## 2026-10-31 — Manrope locale et thème clair (KIBO-003)

Polices statiques officielles 400/600/800 embarquées, sans package de chargement distant. Licence SIL OFL 1.1 conservée et enregistrée dans `LicenseRegistry`. Provenance et empreintes : [UI_THEME.md](UI_THEME.md).

Palette et typographie centralisées dans `core/theme/`. L’accueil garde sa structure et ses interactions ; la grille adapte colonnes et hauteur à la largeur et au texte agrandi. Les styles ne nécessitent aucune modification de la configuration ou du service Supabase. La teinte claire de sélection et les fonds illustratifs existants sont préservés ; la navigation conserve les règles de mise à l’échelle de Flutter Material.

## 2026-10-31 — Ajustements responsive (KIBO-003.1)

Le contrôle réel sur TECNO a révélé un libellé de navigation coupé et des illustrations dont la hauteur dépendait indirectement du texte. Les illustrations reçoivent désormais une hauteur explicite bornée ; les rangées de cartes laissent grandir le texte au lieu de réserver un excédent absorbé par l’image. Une navigation ciblée conserve les styles et les cinq destinations, mais mesure les libellés avec l’échelle système complète et répartit les cellules sur plusieurs rangées lorsque nécessaire. Cette disposition privilégie des libellés entiers et tous visibles, sans réduction du texte, défilement horizontal ni changement de parcours. Aucun nouveau package ni modification de Supabase.

## 2026-10-31 — Préparation du backend (KIBO-004)

**Statut : formalisation et audit des prérequis, aucune implémentation métier.** Les décisions fonctionnelles validées (prix facultatif en XAF et invariant `is_negotiable`, localisation, archivage/favoris et photos) sont centralisées dans le [cahier des charges](CAHIER_DES_CHARGES.md#règles-des-annonces--décisions-kibo-004). Elles remplacent notamment l’ancienne limite de huit photos par trois.

### Conséquences techniques à intégrer au futur schéma
- Contrôler côté serveur l’invariant « prix absent implique `is_negotiable` faux ».
- Séparer les informations publiques et privées ; ville requise, sans exposition automatique de l’adresse exacte ou du GPS.
- Protéger les transitions de statut et filtrer les annonces archivées dans toutes les voies de lecture publique. Conserver favoris et historique sans transformer un favori en droit d’accès ; réserver la purge physique à un processus contrôlé.
- Utiliser un bucket privé. Concevoir un protocole limitant à trois photos par annonce même en concurrence, avec ordre et photo principale cohérents.
- Combiner contraintes des métadonnées, contrôles de l’upload Storage et validation serveur du fichier. La taille réelle et le format du contenu ne doivent pas être considérés comme validés sur la seule déclaration du client ou une contrainte SQL. Les limites du bucket sont un contrôle complémentaire à vérifier par des tests d’upload.
- Prévoir le nettoyage des uploads abandonnés et fichiers orphelins sans supprimer un transfert légitime encore en cours.

### Choix encore à valider avant implémentation
- Champs exacts des profils publics/privés, droits de modération et matrice des opérations par rôle ; statuts et transitions des annonces.
- Représentation du prix, précision numérique et traitement du prix zéro ; définition exacte de « 4 Mo » en octets.
- Protocole de réservation/finalisation des photos, protection concurrente, validation serveur des fichiers et accès en lecture aux photos d’annonces publiques depuis le bucket privé.
- Durée de validité des éventuelles URL signées, conséquences du masquage/archivage, délai de nettoyage des orphelins, conservation des historiques et modalités de purge contrôlée.
- Runtime de conteneurs, mode d’installation et version figée de la CLI Supabase, ressources et ports de la pile locale isolée. L’audit et la proposition minimale sont dans [SUPABASE_SETUP.md](SUPABASE_SETUP.md#préparation-de-la-pile-locale--audit-du-2026-10-31).

Ces points sont des travaux de conception, pas des autorisations d’installation ou de déploiement. Cette intervention ne crée ni SQL ni migration, ne modifie pas Flutter et ne se connecte pas au projet Supabase distant.

## 2026-10-31 — Auth email et persistance (KIBO-005)

Le propriétaire autorise l’authentification Flutter en préservant les modifications documentaires de KIBO-004. Le SDK Supabase existant est réutilisé sans changement de version. Persistance et auto-refresh réactivés, avec `flutter_secure_storage 11.2.0` pour protéger session et vérificateurs PKCE sur Android ; protections de sauvegarde/transfert adaptées. La dépendance `http`, déjà transitive, est déclarée en développement pour simuler les requêtes du SDK dans les tests. Les nouveaux paquets transitifs du plugin et les registrants de plateformes sont résolus par Flutter ; le minimum Flutter résolu devient 3.38.4, compatible avec 3.38.5 installé.

Le trigger existant crée les profils : aucun INSERT/UPSERT client. Les informations de schéma et RLS sont fournies par le propriétaire ; aucune migration du dépôt ne contient le corps du trigger, donc aucune métadonnée additionnelle ne lui est envoyée. Le profil est relu à la connexion/restauration et sur demande, sans édition ni contournement RLS. Confirmation email sans session : message puis connexion manuelle après confirmation dans le navigateur, sans nouveau deep link ou configuration distante. La déconnexion cible cet appareil. Voir [AUTHENTICATION.md](AUTHENTICATION.md) pour détails, tests et limites. Aucun commit ni push dans cette intervention.

## 2026-10-31 — Callback de confirmation Android (KIBO-006)

Le retour localhost constaté pendant la recette KIBO-005 est remplacé côté application par `com.kibo.kibo://auth/confirm`. Ce schéma reprend l’identifiant Android courant ; si celui-ci change, aligner callback, manifeste et allowlist distante. La constante et le filtre testable sont dans `core/config/auth_callback.dart`. Le SDK existant reçoit les liens via son plugin ; le routeur Flutter natif est désactivé pour éviter un double traitement.

PKCE S256, vérificateur et session chiffrés conservés. Le filtre refuse les retours implicites à jetons ; les erreurs sont montrées sans détails bruts. Le schéma personnalisé ne prouve pas la propriété d’un domaine ; PKCE protège l’échange mais pas la livraison du lien. Pas de domaine HTTPS inventé ni de nouvel intermédiaire. La configuration distante manuelle et la recette à chaud/à froid restent nécessaires, voir [AUTHENTICATION.md](AUTHENTICATION.md). Aucun changement distant, dépendance, migration, commit ou push.

## 2026-10-31 — Nom affiché et ville du profil (KIBO-007)

Périmètre choisi par le propriétaire : nom affiché facultatif et ville obligatoire, schéma `profiles` existant. Réutiliser repository et contrôleur de session pour éviter un second client ; séparer le formulaire dans `features/profile/`. Normaliser les espaces en bordure, convertir le nom vide en null et ne pas imposer de nouvelle règle métier sur les longueurs ou les villes autorisées.

Écrire uniquement les deux champs par UPDATE filtré sur le propriétaire courant, sans INSERT/UPSERT et en exigeant le retour d’une ligne. Les contrôles de session et de réponse tardive empêchent d’appliquer un ancien résultat au nouveau compte ; RLS demeure l’autorité serveur. Aucune mise à jour distante pendant le développement, aucune migration ou dépendance ajoutée. La recette Android et les grants/RLS réels restent à vérifier séparément. [Détails du profil](PROFILE.md). KIBO-006 conserve son blocage de recette HTTP 429.
