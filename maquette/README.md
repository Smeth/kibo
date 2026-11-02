# KIBO — Références visuelles de l’application

Ouvrir **[index.html](index.html)** pour parcourir la galerie, ou **[CATALOGUE.md](CATALOGUE.md)** pour accéder à chaque PNG clair/sombre. Le manifeste lisible par un outil est [manifest.json](manifest.json).

## Nature des maquettes

Les rendus proviennent des **vrais widgets Flutter du projet**, à 393 × 852 points logiques, exportés en PNG à densité ×2. Ils donnent des repères cohérents avec l’implémentation : navigation inférieure sur les onglets et retour sur les écrans ouverts depuis une route.

**Annonces, profils et échanges fictifs.** Les villes/localités du sélecteur proviennent du catalogue public GeoNames, attribué sous CC BY 4.0 dans `assets/data/GEONAMES-LICENSE.txt`. L’illustration du téléphone est dessinée dans le générateur ; aucune photo de membre, adresse personnelle, clé ou session réelle n’est incluse. Aucun appel à Supabase, service de connexion, messagerie ou application téléphonique réelle n’est utilisé pour ces exports. Les boutons et états représentés restent ceux de l’application, alimentés par des repositories de test.

Les écrans longs défilent dans l’application ; un PNG représente leur premier viewport, pas la totalité du formulaire. Les dialogues et états transitoires possibles ne sont pas tous des écrans distincts. Les variantes retenues couvrent les pages de l’application et les principaux panneaux : filtres, photos, aperçu de publication, apparence et erreur du catalogue.

## Repères à conserver

- Vert KIBO et Manrope ; XAF, Brazzaville et trois photos maximum.
- Photo dominante sur le détail, compteur superposé, informations sur surface arrondie, actions Message/Contacter persistantes. « Contacter » ouvre le parcours vendeur existant ; aucun appel immédiat sans contrôle de consentement et d’authentification.
- Profil déconnecté : email/mot de passe directement accessibles, inscription et récupération dans le même parcours.
- Messages vides : titre court, une indication utile et contenu défilable si le texte système est grand.
- Mode sombre complet, pas une simple inversion du fond ; boutons, cartes, textes, champs, navigation et zones système cohérents.
- Ancienneté issue de la date de publication réelle ; aucune date inventée si elle manque. Les dates des annonces fictives sont fixées relativement à l’export pour montrer « il y a 1 h » et « il y a 2 j ».
- 78 rendus de 39 écrans/panneaux, dont le sélecteur de villes, le retrait d’annonce, l’annonce sans photo et les actions de message par appui long, disponibles en clair et sombre.

Les rendus des actions modifier/supprimer un message utilisent des fixtures ; le contrat correspondant a ensuite été activé sur Supabase après accord explicite et contrôlé par métadonnées, sans mutation d’un message réel. Les menus réels restent conditionnés à la capacité serveur et à l’auteur. « Supprimer du catalogue » retire une annonce par archivage, sans effacement définitif. [État et limites](../docs/MANAGEMENT_MATERIAL3.md).

La [maquette initiale](reference-initiale.png) est conservée pour comparaison. Ses exemples de villes et limites de photos ne remplacent pas les règles du produit. Les rendus actuels sont la référence d’implémentation ; ils ne sont pas une copie pixel par pixel de cette image.

## Régénération

Depuis la racine du dépôt, sans configuration réelle Supabase :

```powershell
flutter test --no-pub tool/export_maquettes_test.dart --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --reporter expanded
```

Ce générateur explicite utilise les dépendances de test existantes. Il est placé dans `tool/`, séparément de la suite fonctionnelle `test/`, et écrit uniquement les références dans ce dossier. Après une évolution d’interface, régénérer et relire les images concernées, puis conserver ensemble le code et ses références. Aucun commit ou push n’est effectué automatiquement.
