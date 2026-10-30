# Feuille de route — KIBO

Les phases avancent progressivement. Une phase n'est terminée qu'après vérifications et validation.

1. **Environnement** : vérifier Flutter, Dart, Android SDK, licences, Git et VS Code.
2. **Initialisation** : créer le projet Flutter, vérifier le lancement sur émulateur Android et fixer l'identifiant d'application.
3. **Socle UI** : intégrer Manrope, couleurs, thèmes, composants et navigation.
4. **Architecture/configuration** : structurer le code et préparer Supabase sans exposer de secrets.
5. **Backend sécurisé** : concevoir migrations PostgreSQL, RLS, Storage et tests avant déploiement.
6. **Authentification** : email/mot de passe, Google OAuth, puis téléphone OTP après validation du fournisseur SMS.
7. **Catalogue** : accueil, catégories, recherche, filtres et détail d'annonce.
8. **Publication** : formulaire, photos, compression et gestion des annonces.
9. **Engagement** : favoris, profils, commentaires et réponses.
10. **Communication** : chat Realtime, notifications, WhatsApp et appel.
11. **Modération** : signalements, masquage, outils d'administration et audit.
12. **Qualité/livraison** : tests, sécurité, performances, accessibilité, build Android et préparation iOS.

## Règle de progression
Commencer par l'étape 1. Ne pas générer de grandes parties du produit avant validation du socle et de l'environnement.