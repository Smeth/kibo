# Gestion des annonces et messages — 2026-11-01

## Annonces : fonctionnalités et présentation locales

« Mes annonces » affiche la photo de couverture ou un emplacement explicite, le prix, la ville, un statut illustré et les actions. La projection privée charge les références photos seulement lorsque les photos sont activées ; les réservations sont triées par position. Les mêmes URL signées et composants photo que le catalogue sont réutilisés. Recherche, statuts, pagination, contrôle de session/propriétaire et verrouillage optimiste restent en place.

Le formulaire « Modifier mon annonce » affiche désormais la galerie existante. Pour une annonce sans photo, le sélecteur existant permet d’ajouter jusqu’à trois images, de les prévisualiser, puis de les enregistrer séparément du texte. La sélection peut être annulée avant toute tentative d’envoi. Après une tentative potentiellement partielle, elle reste verrouillée pour permettre la reprise avec les mêmes empreintes et réservations. Un échec conserve les images ; le succès est affiché seulement après confirmation du repository. Le retour à la liste recharge les annonces, même si seules les photos ont été enregistrées. Les photos existantes sont conservées : remplacement, retrait et réordonnancement ne sont pas ajoutés dans ce lot.

Limite de reprise : les octets sélectionnés pour cet ajout sont conservés tant que le formulaire reste ouvert, sans nouveau brouillon persistant dédié après fermeture. Une réservation laissée par un envoi partiel puis une fermeture nécessite un parcours de réparation complémentaire ; ne pas présenter ce cas comme validé. Aucun fichier Storage existant n’est remplacé ou effacé.

« Supprimer du catalogue » utilise la transition d’archivage déjà déployée. La confirmation explique clairement qu’il s’agit d’un retrait du catalogue, pas d’un effacement définitif. Photos, favoris et conversations sont conservés ; aucune suppression SQL directe ni cascade nouvelle. L’action est proposée uniquement pour les statuts déjà archivables. Vente et retrait par archivage restent disponibles, avec une seule action de retrait pour éviter les doublons.

## Messages : contrat activé après accord explicite

Bulles Material avec couleurs du thème, coins différenciés, horodatage, accusé de lecture et marqueur « Modifié ». Le menu de ses propres messages ouvre un formulaire validé ou une confirmation de suppression pour les deux interlocuteurs. La suppression laisse une trace « Message supprimé » ; le texte n’est plus affiché dans la conversation. Le texte d’une modification échouée reste disponible lors de la réouverture du formulaire, jusqu’à la fermeture de la page ou au changement de session.

L’interface ne propose ces actions que si `kibo_chat_message_actions` confirme le contrat serveur. Celui-ci a été appliqué après accord explicite de l’utilisateur pendant ce lot. Sur un serveur ancien sans cette fonction, le chat continue de fonctionner et les menus restent masqués. Si la session change pendant le formulaire d’édition, son texte est masqué et la sauvegarde désactivée.

`supabase/proposals/chat_message_actions.sql` a été appliqué via la migration `chat_message_actions_20261101`, résultat `success: true`. Il ajoute deux dates nullable aux messages, deux RPC contrôlées et un journal atomique de métadonnées (acteur, message, action, date), sans ancien contenu. Les colonnes métier existantes ne sont pas réécrites à l’installation. Droits directs UPDATE/DELETE non accordés, RLS conservée, auteur/participant vérifiés côté serveur, conversation bloquée refusée, texte validé et contrôle de version avant modification. Le journal est inaccessible aux clients et disparaît avec le profil/message correspondant.

Audit de métadonnées distant réellement exécuté avant application : RLS active ; pas de privilèges UPDATE/DELETE client ; INSERT limité par colonnes ; nouvelles dates, fonction de capacité et journal alors absents. `can_send`, les quatre déclencheurs INSERT et la projection correspondent au socle attendu. Requêtes reproductibles dans `supabase/audits/message_actions_readonly.sql`. Aucun contenu métier consulté par cet audit.

Après application, vérifications distantes réellement effectuées : les deux RPC et dates existent ; RLS des messages et du journal active ; UPDATE/DELETE directs, lecture client du journal, INSERT de la date d’édition et EXECUTE visiteur refusés ; EXECUTE membre accordé ; wrappers publics SECURITY INVOKER. Aucun message réel modifié ou supprimé pour la recette. La proposition est testée avec les fixtures du contrat chat courant ; l’activation conjointe du prototype futur d’anonymisation des comptes nécessite une revue séparée. Un contenu déjà lu, copié ou présent dans une ancienne notification ne peut pas être rappelé. Les suppressions ne constituent pas une purge des sauvegardes.

Conseiller de sécurité distant consulté après application : INFO « RLS Enabled No Policy » sur le journal, attendu puisque l’accès client y est entièrement refusé et que seule la fonction serveur écrit ([explication](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)). Avertissement Auth indépendant : protection contre les mots de passe compromis désactivée ; réglage non modifié dans ce lot ([documentation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)).

## Google : possible, pas activé dans l’application

La connexion Google est prise en charge par Supabase et Flutter. Le parcours recommandé pour ce MVP est OAuth avec navigateur et PKCE, en réutilisant le callback Android et le stockage sécurisé existants. Il faut créer/configurer le client OAuth et l’écran de consentement Google, déclarer le callback Supabase dans Google, activer Google dans Supabase et autoriser le retour vers KIBO, puis intégrer et tester « Continuer avec Google » dans le profil déconnecté. Le secret OAuth reste exclusivement côté serveur, jamais dans Flutter ni dans le chat.

La configuration actuelle du fournisseur Google n’a pas été vérifiée à distance et aucun réglage Auth n’a été modifié. L’application ne contient pas encore de bouton Google. Tester ensuite les annulations, erreurs, retours à froid/chaud et le cas d’un compte email déjà existant avant activation générale.

Documentation officielle consultée : [Google avec Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google), [API Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth).

## Fichiers et vérifications

- `lib/features/listings/owned_listing_repository.dart`, `my_listings_page.dart`, `edit_listing_page.dart`, format de prix partagé dans `listing_models.dart`.
- `lib/features/chat/chat_repository.dart`, `chat_page.dart`, nouveau `message_bubble.dart`.
- `test/listings/{my_listings_widgets,owned_listing_repository}_test.dart`, `test/chat/chat_repository_test.dart`, nouveau `test/chat/message_actions_test.dart`.
- Proposition SQL ci-dessus, `supabase/audits/message_actions_readonly.sql`, `test/sql/message_actions_assertions.sql`, suite `MessageActions` du lanceur `scripts/Test-OwnerManagementSql.ps1`.
- `tool/export_maquettes_test.dart`, références dans `maquette/`, documents de progression et prochaine tâche.

Les tests utilisent uniquement des fixtures : mutations de messages, annulation, erreur/reprise, session changée, contrat absent, blocage, photos absentes/existantes et reprise d’upload, confirmation du retrait d’annonce, projections et résultats RPC. **369 tests standard + 369 photos activées réussis**, quatorze nouveaux ; analyse stricte sans anomalie, format 123 fichiers inchangés et diff conforme. Les tests PostgreSQL `MessageActions` ont réussi dans une instance temporaire locale au projet ; aucune donnée réelle touchée. Logs `.dart_tool/management4-{analyze,tests,photos-tests,format-check,sql}.log`. Export visuel et relance TECNO dans `PROGRESS.md`. Aucun commit/push. Seul le contrat serveur explicitement autorisé a été appliqué.

Export final réussi : **76 PNG de 38 écrans/panneaux**, clair/sombre, manifeste/dimensions contrôlés. Application normale installée et relancée sur TECNO, code 0, processus 22520 et premier plan confirmés. Aucune recette de mutation de message réel ni recette humaine à deux comptes revendiquée. Aucune disparition de fichier préexistant selon l’inventaire initial.
