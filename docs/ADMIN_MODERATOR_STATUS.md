# Administrateur et modérateur — état vérifié le 2026-11-02

**Mise à jour après instruction explicite :** `kanasmeth@gmail.com` est désormais administrateur (métadonnée serveur vérifiée). Nouvelle entrée **Profil → Administration**, avec modules signalements et demandes de compte, après déconnexion/reconnexion. [Périmètre et vérifications du lot](UI_REVIEW_2_ADMIN_STRESS.md). Les sections ci-dessous décrivent l’état antérieur à cette demande ; le rôle moderator distinct et les capacités non implémentées restent absents.

## Existe déjà

Une entrée **Profil → Modération** est implémentée sur mobile. Elle est masquée tant que la RPC serveur `kibo_can_moderate` n’autorise pas le compte connecté ; masquer/afficher le bouton n’accorde aucun droit. Le contrat est documenté et son déploiement antérieur consigné dans [NOTIFICATIONS_MODERATION.md](NOTIFICATIONS_MODERATION.md).

Cette vue affiche une file de signalements filtrée/paginée, le contenu signalé et son journal. L’administrateur peut rejeter un signalement, le clôturer sans masquer, ou masquer le contenu et clôturer. Motif obligatoire et confirmation ; annonce publiée → rejected, commentaire publié → hidden. Le serveur réalise la décision et le journal atomiquement. Un masquage est notifié à l’auteur sans lui divulguer l’identité du signaleur.

Contrôle distant en lecture seule du 2026-11-02 : les cinq RPC `kibo_can_moderate`, `kibo_report_content`, `kibo_review_report`, `kibo_account_queue` et `kibo_account_review` sont présentes comme façades SECURITY INVOKER. RLS active constatée sur annonces, commentaires, photos, signalements et journal de modération. Aucun rôle ni politique modifié par ce contrôle.

Les comptes autorisés ont aussi un suivi opérateur des demandes de compte : file, précisions, décision et journal. Ce suivi ne supprime pas réellement un compte ni ses historiques. La suppression destructive reste un processus séparé non activé dans ce lot.

Une [capture issue des vrais widgets avec fixtures](../maquette/clair/18-moderation.png) et sa [version sombre](../maquette/sombre/18-moderation.png) existent. Elles illustrent la vue ; elles ne prouvent pas une attribution de rôle ou une recette de modération réelle sous les comptes fournis.

## Rôles actuels

Le contrôle serveur existant reconnaît `app_metadata.role = admin`, dans un jeton signé. Aucun droit fondé sur `user_metadata` modifiable par le membre. Le rôle admin est une autorisation de l’application ; il ne donne pas les identifiants du tableau de bord Supabase.

Les deux comptes désignés pour le lot de données sont actuellement des membres ordinaires. Aucun des deux n’a été promu. Un rôle distinct **moderator** avec permissions limitées n’est pas encore implémenté : changer uniquement une étiquette Flutter ne suffirait pas, il faudrait adapter et tester les contrôles serveur.

## À concevoir ensemble

Séparation recommandée :

| Rôle | Périmètre envisagé |
| --- | --- |
| Modérateur | Signalements, examen annonces/commentaires, masquage motivé et historique des décisions. |
| Administrateur | Gestion des droits de l’équipe et des règles de modération, supervision, demandes de compte et opérations exceptionnelles dûment contrôlées. |

Les actions déjà disponibles sur mobile figurent ci-dessus. La console web dédiée, l’attribution des rôles dans une interface, les sanctions globales/suspensions de compte, la restauration des contenus et le traitement des signalements de profil restent à développer. Aucun accès « tout faire » ou effacement définitif ne doit être supposé à partir de l’actuelle vue de modération.

La publication reste immédiate après validation : cette équipe intervient **après publication**. Le choix du compte administrateur et l’attribution effective du rôle exigent une instruction spécifique ; la présente demande de données et d’explication n’en attribue aucun.
