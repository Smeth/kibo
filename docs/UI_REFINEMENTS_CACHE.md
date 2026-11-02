# Détails UI, rafraîchissement et photos — 2026-11-02

## Formulaires et recherche

Récupération email : 24 px entre texte/champ et champ/action, espace explicite pour le message de résultat. Même revue pour changement de mot de passe, confirmation de demande de compte, précisions au demandeur, note opérateur, modération et commentaires. Les formulaires profil, connexion, téléphone, contacts, publication/modification et les dialogues de chat ont également été inspectés ; leurs espacements existants sont conservés lorsqu’ils séparent déjà les contrôles. Aucun changement de validation ou d’écriture métier.

Les deux SearchBar (annonces et sélecteur de villes) sont enveloppées dans `KiboSearchFieldTheme`. Le thème global imposait une hauteur minimum/remplissage de champ formulaire à leur TextField interne, malgré le padding nul fourni par SearchBar. La surcharge locale retire cette contrainte et le remplissage ; les champs classiques gardent leur thème. Le centrage du curseur est vérifié par mesure du rectangle du caret face à la loupe, après saisie et avec texte ×1/×2.

## Tirer pour actualiser

`ListingFeed` utilise `RefreshIndicator` et `AlwaysScrollableScrollPhysics` : tirer vers le bas depuis le haut actualise les annonces même avec zéro résultat ou un catalogue plus court que l’écran. Les filtres courants sont conservés. Les demandes concurrentes sont ignorées pendant le chargement/la pagination ; les annonces existantes restent visibles en cas d’erreur. Le bouton Actualiser reste disponible. Cela n’ajoute pas de défilement infini : la pagination « Voir plus » est conservée.

## Villes

Le fichier de référence était déjà un extrait **CG uniquement** de GeoNames, regroupant 5 778 enregistrements en 4 538 noms de villes/localités. Le loader refuse désormais un catalogue dont le pays n’est pas CG. Il ne s’agit pas d’un mélange de pays ; certains noms de localités peuvent ressembler à ceux d’autres pays.

Dans les filtres, le champ est en lecture seule et ouvre le sélecteur CG ; la saisie libre d’une ville étrangère est supprimée. Accueil utilise déjà ce sélecteur. « Toutes les villes » désigne les villes du catalogue Congo-Brazzaville. La saisie libre dans les formulaires vendeur/profil reste conservée pour les valeurs historiques/localités, conformément au périmètre des filtres demandé. Aucune donnée d’annonce existante déplacée ou modifiée.

## Pourquoi les photos rechargeaient

Le changement d’onglet reconstruit le catalogue ; chaque nouveau `ListingPhotoView` demandait sa propre URL signée (60 secondes). Pendant cette demande, le widget affichait un indicateur. La signature renouvelée et les tailles de décodage différentes pouvaient aussi créer d’autres clés dans le cache mémoire d’images Flutter : un fichier déjà vu pouvait être téléchargé de nouveau.

Pour le repository de production, le chemin principal passe maintenant par `Storage.download`, sous la session Supabase courante et les politiques SELECT existantes. Aucun bucket public, prolongation de signature, politique ou privilège serveur ajouté. `signedUrl` reste disponible pour compatibilité et les repositories injectés sans capacité de cache gardent le parcours historique.

Le nouveau `ListingPhotoCache` partage **les mêmes octets** entre carte, détail et remontage des widgets, quelle que soit la taille de décodage. Une lecture chaude renvoie une `SynchronousFuture` pour éviter le spinner de résolution. Les lectures concurrentes du même fichier partagent leur requête ; une erreur n’est pas mémorisée et le bouton de reprise force une nouvelle lecture. Le cache de décodage Flutter reste actif et `cacheWidth` reste borné à 1 600 pixels et adapté aux contraintes.

Limites : mémoire uniquement, **24 Mio / 100 entrées**, éviction des moins récemment consultées, réutilisation **45 secondes maximum à partir de la demande**, donc inférieure à la validité de l’ancienne signature de 60 secondes. Les nouvelles lectures après expiration retéléchargent le fichier ; les images déjà affichées ne sont pas retirées par un minuteur. Le jeton de session sert seulement de frontière interne, jamais de clé de widget ni de contenu journalisé ; son changement invalide le cache et un ancien résultat réseau en vol est refusé. Les widgets dépendent aussi de la session pour relire les photos au changement de compte/déconnexion.

Ce n’est pas un cache disque persistant ni une garantie de mode hors ligne après arrêt de l’application. Le catalogue lui-même continue sa lecture réseau après changement d’onglet. Aucun benchmark FPS, profilage GPU, CDN ou compression supplémentaire n’a été réalisé : la réduction des requêtes est vérifiée en simulation, la fluidité réelle doit être mesurée sur l’appareil en mode profile/release. Ne pas déduire une performance identique à Facebook à partir d’une compilation debug.

## Vérification

Tests de géométrie des espacements, geste réel de refresh sur catalogue rempli/vide et erreur avec filtres, caret centré, choix CG sans Kinshasa, cache concurrent/expiration/reprise/erreur/budget mémoire, ancien résultat privé refusé après changement de session, GET Storage simulé unique pour deux lectures, remount à autre taille sans téléchargement/spinner et relire après connexion/déconnexion. Aucun message, annonce ou compte de recette réel créé. Les tests HTTP ne valident pas la politique Storage distante par exécution réelle.

Références : [cache d’images Flutter](https://api.flutter.dev/flutter/painting/ImageCache-class.html), [download Storage Dart et droit SELECT](https://supabase.com/docs/reference/dart/storage-from-download).
