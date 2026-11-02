# Suppression de compte — procédure et historique

**Actualisation du 2 novembre 2026 :** contrat et fonction d’exécution déployés après accord explicite, conservation privée de 15 jours et expiration horaire actives. La suppression administrative est reprenable et exige confirmation et connexion récente ; aucun compte réel supprimé pour la recette. Le propriétaire doit encore valider son facteur TOTP et la recette destructive sur un compte dédié. [État vérifié et limites](ROLLOUT_MVP_20261102.md). Les mentions « non implémenté/non activé » ci-dessous décrivent le runbook initial.

Date : 2026-11-01, Africa/Lagos. Choix utilisateur reçu : **anonymiser les échanges conservés ; supprimer profil, annonces et coordonnées**, à valider avant mise en service. Il s’agit d’une orientation produit, pas d’une autorisation d’effacer un compte réel ni d’une politique juridique de conservation déjà validée.

Avancement local suivant : [prototype d’historique privé et moteur d’orchestration](RETAINED_HISTORY_PROTOTYPE.md), SQL sur fixture et tests de reprise en mémoire réussis. Aucun de ces éléments n’est déployé ; les adaptateurs réels, guards et règles de conservation restent à réaliser/valider avant activation.

## État vérifié et risques

Audit distant en lecture seule des contraintes et colonnes, sans lire les lignes des membres. Requête réutilisable : `supabase/audits/account_deletion_dependencies_readonly.sql`. Le parcours actuel traite les demandes et leurs notes ; aucune fonction de suppression effective n’a été découverte parmi les fonctions applicatives auditées. Ne pas utiliser le bouton du Dashboard Auth pour simuler l’achèvement.

| Dépendance réelle | Effet actuel | Préparation nécessaire |
|---|---|---|
| auth.users → profiles | CASCADE | La suppression Auth déclenche celle du profil et ses dépendances. |
| profiles → listings ; messages.sender_id ; reports.reporter_id | RESTRICT | L’effacement peut être refusé si ces références existent. |
| profiles → conversations → messages | CASCADE | Risque de perdre aussi les messages de l’autre participant. |
| listings → conversations | RESTRICT | Supprimer l’annonce ne suffit pas ; préserver la conversation du membre restant exige un contrat adapté. |
| profiles/listings → listing_comments ; parent_id → réponses | CASCADE | Risque de perdre des réponses d’autres auteurs. Définir ce qui reste consultable après retrait du parent. |
| reports → listing/comment/reported_user | SET NULL, mais cible obligatoire | Vérifier les contraintes : une suppression de toutes les cibles d’un signalement peut être refusée. |
| profiles → demande et historique de demandes | CASCADE | L’actuel historique ne constitue pas une preuve durable d’une suppression terminée. |
| photos.owner_id → profiles | NO ACTION | Traiter objets et métadonnées avant le profil, selon l’inventaire validé. |

Supabase indique qu’un compte possédant encore des objets Storage ne peut pas être supprimé, et qu’un JWT déjà émis peut rester valide jusqu’à son expiration. Le nettoyage Storage et l’interdiction des nouveaux accès doivent donc être prévus avant de considérer l’opération terminée. [Gestion officielle des utilisateurs](https://supabase.com/docs/guides/auth/managing-user-data#deleting-users).

## Décisions à finaliser

- Durées et motifs de conservation des échanges, signalements et preuves opérateur ; approbation par le responsable KIBO compétent avant production. Aucun délai légal n’est inventé ici.
- Rendu « Compte supprimé », conversations en lecture seule pour le membre restant, retrait des noms/avatar/coordonnées et de tout lien vers l’ancien compte. Les DTO, RLS, compteurs et guards doivent accepter cet état sans conserver une identité fictive pouvant se connecter.
- Un identifiant pseudonymisé ne suffit pas à garantir l’anonymat : les textes libres, pièces jointes, notes et liens peuvent contenir des données personnelles. Définir une revue/rédaction de ces contenus et des métadonnées avant de déclarer les échanges anonymisés.
- Préserver les contributions des autres membres. En particulier, supprimer une annonce ne doit pas détruire leur historique de chat ou leurs réponses par cascade involontaire.
- Inventaire des buckets réels : objets liés aux annonces, anciens listing_images, avatar et objets possédés par le compte. Une référence de chemin ou owner_id seule n’est pas une autorisation de supprimer tout un bucket.

## Séquence opérateur cible

1. **Vérifier la demande et l’identité.** Demande non annulée et version actuelle ; preuve récente de contrôle du compte au moyen du parcours Auth, jamais mot de passe/code demandé dans le chat. Motif de rétention ou litige éventuel examiné. Un administrateur ne peut pas changer une identité pour contourner cette étape.
2. **Préparer un dossier d’exécution minimal.** Référence d’opération indépendante des FK qui disparaîtront, version de la politique et de la demande, inventaire des seuls objets/lignes concernés, responsable et validations. Pas de copie globale de messages ou de coordonnées dans les journaux. Aucun « completed » à ce stade.
3. **Geler les nouvelles interactions du compte.** Contrôle serveur commun à toutes les écritures, accès RPC/Storage et URLs signées concernés, compatible avec les JWT encore valides. Révoquer les sessions par l’API Auth appropriée ; un simple changement d’interface Flutter n’est pas une barrière serveur. Les accès du membre restant à l’historique conservé doivent continuer selon la politique.
4. **Détacher et anonymiser dans une transaction SQL contrôlée.** Nouvelle migration nécessaire : relations d’auteur/participant/annonce acceptant la disparition, protections RLS, état supprimé de la conversation, garde des commentaires/réponses et signalements. Retirer coordonnées et éléments publics prévus par la politique, préserver seulement les échanges autorisés et leurs auteurs restants. Aucun SQL DELETE direct sur auth.users. Une panne du journal ou un conflit de version doit annuler cette phase.
5. **Nettoyer Storage par son API.** Retirer uniquement les objets dont l’appartenance est établie dans l’inventaire approuvé, avec reprise idempotente par objet et sans suppression brute dans storage.objects. Ne jamais suivre un chemin arbitraire transmis par le client. Vérifier les références anciennes comme nouvelles.
6. **Supprimer le compte Auth par l’API Admin côté serveur.** Secret exclusivement serveur ; aucune clé privilégiée dans Flutter. Appeler cette étape seulement après succès des phases antérieures et préconditions relues. [API Admin deleteUser](https://supabase.com/docs/reference/javascript/auth-admin-deleteuser).
7. **Vérifier puis clôturer.** Absence du compte Auth/profil/annonces/coordonnées/objets ciblés ; accès via ancien JWT effectivement bloqué ; autre membre encore capable de lire son historique autorisé ; aucune référence orpheline ou cascade tierce. Conserver uniquement la preuve minimale approuvée hors des tables qui sont supprimées. La disparition du profil ne prouve pas à elle seule la réussite. Mettre l’opération à terminé seulement après tous les contrôles.

PostgreSQL, Storage et Auth ne partagent pas une transaction unique : utiliser une orchestration avec étapes persistantes, verrou par compte et reprise idempotente. Après une panne, relire la dernière phase confirmée ; ne pas rejouer aveuglément l’ensemble ni supprimer un second compte. Un échec Storage/Auth laisse une opération à reprendre, jamais une fausse suppression réussie. La restauration d’un compte réellement effacé n’est pas promise.

## Tests exigés avant activation

Fixture locale et projet de staging autorisé : vendeur/acheteur/tiers/admin ; annonce avec favoris de tiers, conversation bilatérale, commentaires/réponses d’autres auteurs, signalement avec une seule cible, photos/avatars et demande en cours. Vérifier contribution tierce préservée, identité retirée, conversation non réutilisable pour envoyer, aucun accès tiers, aucun secret client ; JWT antérieur, concurrence annulation/examen, recréation de demande, deux opérateurs ; pannes avant/après chaque phase et journal indisponible ; reprise sans doublon et refus de cible/chemin arbitraires.

**Non implémenté/non testé ici :** worker de suppression, nouvelles relations/RLS, purge Storage, suppression Auth, anonymisation de texte libre, délais de conservation et recette destructive. Leur activation exigera un contrat préparé/testé puis l’accord distant précis. Cette procédure ne doit pas être présentée dans l’application comme une suppression automatique déjà disponible.
