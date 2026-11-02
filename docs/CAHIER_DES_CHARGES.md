# Cahier des charges — KIBO V1

## Vision et marché
Marketplace généraliste de produits et services en République du Congo. Lancement à Brazzaville, puis extension à Pointe-Noire et aux autres villes.

## Plateformes
- Android en priorité, iOS ensuite.
- Français au lancement.
- Monnaie : XAF.

## Types d'utilisateurs
- Visiteur : consulte/recherche/filtre les annonces publiques et conserve des favoris locaux sur son appareil sans compte.
- Utilisateur : publie, commente, conserve des favoris synchronisés et échange après authentification. Les favoris visiteurs peuvent être transférés vers le compte après confirmation explicite, sans doublons.
- Administrateur/modérateur : traite les signalements, annonces, commentaires et comptes depuis une interface d'administration séparée envisagée.

## Fonctionnalités V1
- Accueil et navigation par catégories.
- Recherche et filtres.
- Détail d'annonce et galerie de maximum 3 photos.
- Publication et gestion de ses annonces.
- Favoris et profils.
- Contact vendeur par WhatsApp, appel et chat intégré.
- Chat temps réel.
- Commentaires publics et réponses.
- Notifications.
- Signalement d'annonces et commentaires.
- Modération après publication, masquage et journal d'audit.

## Catégories
Téléphones et informatique ; Véhicules et motos ; Immobilier ; Maison et équipement ; Mode et beauté ; Services ; Alimentation ; Emploi et formation ; Loisirs et divertissement.

## Publication et modération
**Décision courante pour le lancement :** publication immédiate sans modération préalable, avec `published_at` issu du serveur. Cela remplace l’adaptation pending/publication administrative précédemment validée pour KIBO-008/009/010. Prix facultatif côté Flutter et Supabase depuis le 2026-11-02 ; zéro explicite distinct du prix absent. Jusqu’à trois photos selon le contrat actuel. [Publication](DIRECT_PUBLICATION.md), [prix facultatif activé et contrôlé](SELLER_SEARCH_OPTIONAL_PRICE.md).

Publication automatique après validation des champs obligatoires. Prévoir signalements, anti-spam, statut masqué, actions administrateur et traçabilité. La publication immédiate ne signifie pas absence de modération.

## Règles des annonces — décisions KIBO-004

Décisions validées par le propriétaire le 2026-10-31. Cette section est la référence fonctionnelle ; elle ne décrit pas une implémentation existante. La limite de trois photos remplace la limite précédente de huit.

### Prix
- Le prix est facultatif dans toutes les catégories ; tout prix renseigné est exprimé en XAF.
- Prix absent : affichage « Prix à négocier », sans le remplacer par zéro.
- Zéro renseigné explicitement reste « 0 XAF ». Aucun champ `is_negotiable` n’est ajouté dans ce lot.

### Localisation
- Ville obligatoire ; quartier et précision complémentaire facultatifs.
- Adresse exacte et coordonnées GPS non publiques par défaut.

### Suppression et historique
- Archivage logique par défaut : une annonce archivée disparaît des résultats publics mais reste dans l’historique de son propriétaire.
- Les favoris associés sont conservés, sans donner accès à l’annonce archivée.
- La suppression physique est réservée à un processus contrôlé.

### Photos
- Maximum de 3 photos par annonce.
- Compression automatique dans Flutter avant upload ; taille maximale après compression : 4 Mo par photo.
- Formats acceptés : JPEG, PNG et WebP.
- Une photo principale choisie parmi les photos ; ordre modifiable par le propriétaire.
- Bucket Supabase privé.
- Contrôle serveur du nombre et de la taille réelle des fichiers, y compris lors d’uploads concurrents ; rejet des fichiers non conformes.
- Nettoyage contrôlé des fichiers orphelins à prévoir.

La compression côté Flutter ne constitue pas une garantie de sécurité. Une contrainte SQL sur les métadonnées ne contrôle pas, à elle seule, la taille réelle d’un fichier Storage. Les choix techniques encore nécessaires sont consignés dans [DECISIONS_TECHNIQUES.md](DECISIONS_TECHNIQUES.md#2026-10-31--préparation-du-backend-kibo-004).

## Authentification
- Téléphone + code OTP, après validation d'un fournisseur SMS réellement fonctionnel au Congo.
- Google OAuth.
- Email + mot de passe.
- Session persistante tant qu'elle reste valide.
- Pas d'authentification anonyme Supabase nécessaire pour consulter les annonces.
- Ne pas fusionner automatiquement deux comptes sans preuve de contrôle des identifiants concernés.

## Hors périmètre V1
Paiement intégré, livraison intégrée, abonnements et annonces sponsorisées.

## Exigences non fonctionnelles
Sécurité des données, RLS PostgreSQL, performance mobile, compression d'images, gestion des erreurs, accessibilité, tests et observabilité.

## À confirmer avant production
Fournisseur SMS et délivrabilité au Congo ; politique de conservation des données ; règles de modération ; conformité juridique locale ; coûts et limites Supabase ; processus d'administration.
