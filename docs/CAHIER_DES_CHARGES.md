# Cahier des charges — KIBO V1

## Vision et marché
Marketplace généraliste de produits et services en République du Congo. Lancement à Brazzaville, puis extension à Pointe-Noire et aux autres villes.

## Plateformes
- Android en priorité, iOS ensuite.
- Français au lancement.
- Monnaie : XAF.

## Types d'utilisateurs
- Visiteur : consulte les annonces publiques sans compte.
- Utilisateur : publie, commente, ajoute aux favoris et échange après authentification.
- Administrateur/modérateur : traite les signalements, annonces, commentaires et comptes depuis une interface d'administration séparée envisagée.

## Fonctionnalités V1
- Accueil et navigation par catégories.
- Recherche et filtres.
- Détail d'annonce et galerie de maximum 8 photos.
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
Publication automatique après validation des champs obligatoires. Prévoir signalements, anti-spam, statut masqué, actions administrateur et traçabilité. La publication immédiate ne signifie pas absence de modération.

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