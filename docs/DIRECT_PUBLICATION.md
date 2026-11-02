# Publication directe au lancement

**Mise à jour du 2026-11-02 : prix désormais facultatif, côté client et Supabase**, après instruction et autorisation explicites. NULL = « Prix à négocier », zéro explicite préservé. [Migration appliquée et contrôles](SELLER_SEARCH_OPTIONAL_PRICE.md). Les sections suivantes conservent l’historique du premier contrat ; leurs mentions de prix obligatoire/serveur non déployé ne décrivent plus l’état courant.

## Décision et état réel

Le propriétaire demande désormais une publication immédiate, sans modération préalable. Cette décision remplace le flux pending accepté auparavant pour KIBO-008. Le prix reste obligatoire en XAF, les validations et le propriétaire courant sont conservés ; pas d’image ni de négociabilité ajoutée. La modération après publication reste possible avec les droits administratifs existants.

**Le code Flutter est adapté localement ; le projet Supabase distant n’est pas modifié.** La politique INSERT communiquée par le propriétaire n’autorise que draft/pending avec published_at NULL : elle ne permet donc pas le nouveau flux. La publication réelle doit attendre la revue et l’application explicitement autorisée du delta SQL ci-dessous. Aucun repli silencieux en pending et aucun contournement RLS n’est implémenté.

La définition actuelle distante n’a pas été interrogée de nouveau par l’agent : pas de session d’administration disponible. Les derniers contrôles REST de recette ont renvoyé zéro ligne sous le compte présumé propriétaire, sans confirmation de sa correspondance au vendeur ; le contrôle sous B n’a pas été atteint. Ce résultat ne prouve ni le bon fonctionnement ni une défaillance de la RLS de lecture. Il faudra vérifier les politiques et les comptes avant déploiement.

## Changements Flutter

- Le repository insère explicitement `status = published` et `published_at` en UTC, avec une horloge injectable pour les tests. Le vendeur reste celui de la session vérifiée ; aucun champ de vues, motif de rejet ou rôle n’est envoyé.
- Le retour serveur doit contenir une seule ligne published avec une date valide avant d’annoncer un succès. Un retour pending, une date absente/invalide ou un refus serveur ne devient jamais « Annonce publiée ».
- Le formulaire affiche « Publier l’annonce » et la publication immédiate. Un refus RLS reconnu reçoit un message français sans exception brute. Les autres échecs restent non confirmés, sans retry automatique pour éviter des doublons.
- Après confirmation serveur, l’application revient à Accueil, recharge la première page published et actualise l’état des favoris du compte courant. L’ajout aux favoris reste une action explicite ; aucune annonce n’est automatiquement ajoutée.
- Liste, détail et jointure des favoris gardent leur filtre published. Ils peuvent donc utiliser immédiatement la nouvelle annonce une fois l’INSERT autorisé et confirmé. Pas de nouvel initialiseur SDK ni de changement de stockage de session.

## Migration préparée, pas déployée

Fichier : `supabase/migrations/20261031050000_direct_listing_publication.sql`.

Delta transactionnel sur le schéma existant, sans recréer de table ni modifier de ligne :

1. Vérifie la présence de listings, RLS activée, la politique INSERT attendue pour authenticated, l’absence d’une autre politique INSERT/ALL et de trigger INSERT applicatif actif. Tout écart interrompt la transaction pour revue : les corps complets des triggers distants ne sont pas connus.
2. Crée une fonction de trigger `private.kibo_stamp_listing_publication`, SECURITY INVOKER, search_path pg_catalog. Pas de lecture de données privilégiées ni de SECURITY DEFINER. Le nom n’est pas remplacé s’il existe ; accès direct à la fonction révoqué pour PUBLIC/anon/authenticated.
3. Ajoute un BEFORE INSERT qui remplace published_at par `statement_timestamp()` pour chaque nouvel INSERT published, y compris administratif. Cela neutralise une horloge mobile incorrecte ou une date fournie frauduleusement. L’heure PostgreSQL est l’autorité, pas le téléphone.
4. Modifie uniquement WITH CHECK de `listings_insert_own` : vendeur = auth.uid(), vues initiales 0, aucun motif de rejet. Published est permis avec la date exacte du statement imposée par le trigger ; draft/pending et leur date NULL restent autorisés pour compatibilité. Le défaut pending de la table reste inchangé, puisque Flutter demande published explicitement.
5. Ne touche ni SELECT/UPDATE/DELETE, ni leurs triggers, ni les contraintes/FK, favoris, catégories, profils, Storage ou grants des tables. Ne publie aucune ancienne ligne pending et ne réinitialise aucune donnée.

Les BEFORE ROW triggers s’exécutent avant WITH CHECK. Sources : [CREATE POLICY PostgreSQL](https://www.postgresql.org/docs/current/sql-createpolicy.html), [comportement des triggers](https://www.postgresql.org/docs/current/trigger-definition.html).

### Avant toute application distante

- Lire les définitions exactes des politiques, grants et triggers avec un accès autorisé, notamment les triggers UPDATE et tout trigger INSERT non annoncé. Le preflight bloque les cas non prévus ; ne pas le contourner en supprimant une protection.
- Comparer à la fixture locale et à la version PostgreSQL réellement utilisée, sauvegarder les définitions précédentes et vérifier le plan de retour arrière. Le rollback ne doit pas dépublier automatiquement les lignes créées entre-temps ; il nécessite une revue distincte.
- Tenir compte de la base déjà existante : ce delta n’est pas un schéma initial. Ne lancer aucun reset ou push global de migrations pour reconstituer le backend à partir de ce seul fichier.
- Obtenir l’autorisation explicite du propriétaire, puis faire appliquer uniquement ce delta par l’opérateur autorisé. Aucune application distante n’est autorisée par la simple préparation de ce fichier.

## Tests SQL réellement exécutés, uniquement en local

Une instance PostgreSQL 13 temporaire a été créée sous `.dart_tool/kibo-direct-publication-pg`, liée à 127.0.0.1:55439, sans toucher au service existant. Les tests utilisent les rôles anon/authenticated et des UUID fictifs ; aucune clé privilégiée ou session Supabase réelle. L’instance temporaire a ensuite été arrêtée, sans suppression de fichiers.

Fichiers exécutés, dans l’ordre :

1. `test/sql/direct_publication_fixture.sql` : schéma réduit et données fictives. **Fixture locale, jamais à déployer** ; ce n’est pas une copie complète des fonctions Supabase distantes.
2. Le delta de migration.
3. `test/sql/direct_publication_assertions.sql` : assertions sous rôles clients avec RLS active et transaction finale annulée.
4. `test/sql/direct_publication_legacy_policy.sql` : démontre que l’ancien prédicat refuse published, puis ROLLBACK.

Résultats : publication du propriétaire acceptée, date future remplacée par l’heure serveur, annonce lisible par B et anon, favori immédiatement ajoutable par A/B, vendeur usurpé/vues/rejet privilégiés/INSERT anon refusés, ancien pending invisible à B, favoris de A non lisibles/supprimables par B. Les autres politiques, le trigger UPDATE de la fixture et l’ancienne ligne pending restent préservés. La réapplication du delta est bloquée par le preflight, comme attendu ; les assertions passent encore ensuite.

Ces contrôles utilisent réellement PostgreSQL/RLS, mais **ne certifient pas la configuration du projet Supabase distant**. Le guard UPDATE de la fixture représente le contrat communiqué ; il ne remplace pas l’audit des fonctions déployées.

Pour relancer les assertions uniquement sur cette instance locale si elle est redémarrée :

```powershell
& 'C:/Program Files/PostgreSQL/13/bin/psql.exe' -X -h 127.0.0.1 -p 55439 -U kibo_local_test -d postgres -v ON_ERROR_STOP=1 -f test/sql/direct_publication_assertions.sql
```

Pour rejouer l’ensemble, créer un **nouveau** cluster jetable dans un autre sous-dossier ignoré de `.dart_tool/`, avec `initdb`, utilisateur `kibo_local_test` et données fictives, puis démarrer avec `pg_ctl -h 127.0.0.1 -p 55439` via ses options serveur `-o`. Vérifier qu’il s’agit du cluster de test et que son démarrage a réussi avant tout appel psql. Exécuter les quatre fichiers ci-dessus avec `-X -v ON_ERROR_STOP=1`, puis arrêter seulement ce cluster. Ne pas rejouer la fixture sur une base existante, un service local préexistant ou Supabase ; ne pas installer de nouveau logiciel pour ce test sans accord.

## Validations Flutter finales

- `dart format lib test` : réussi, 50 fichiers.
- `flutter analyze --fatal-infos` : aucune anomalie, code 0 (4,5 s au dernier passage).
- `flutter test --reporter expanded` : **95 tests réussis**, code 0 ; les 91 précédents sont conservés/adaptés, 4 nouveaux tests ajoutés.
- `git diff --check` : réussi, code 0.

Les nouveaux tests vérifient la date UTC envoyée, la date renvoyée par le serveur, le refus d’un faux succès pending/date absente, le refus RLS sans retry/repli et le parcours complet catalogue/détail/favori après publication. Le premier passage du parcours intégré visait un titre sous la navigation : le test a été corrigé pour défiler jusqu’à une cible réellement cliquable, puis la suite entière a été relancée avec succès. Aucun nouveau test physique ni build installé pour ce changement.

## Recette distante et TECNO restante

Après revue/application autorisée de la migration et installation de la nouvelle version : avec un compte de test, créer une annonce, vérifier published et date serveur, retour Accueil avec carte visible, détail relu et ajout/retrait/persistance des favoris. Refaire avec B et visiteur ; vérifier refus d’usurpation, de champs privilégiés et isolation des favoris. Ne pas tester ces écritures sur des données réelles.

Les observations de la recette précédente restent historiques : installation de l’ancien flux vérifiée par empreinte, création unique pending sans photo avec vendeur correct/1000 XAF, absence du catalogue, erreur réseau puis reprise et état vide confirmés par le propriétaire. Publication administrative indisponible ; détail publié, favoris et archivage non exécutés. Aucun test physique de publication directe n’a encore eu lieu.

Aucun commit, push, ajout de dépendance ou changement distant. Les paramètres publics de build restent saisis localement selon [SUPABASE_SETUP.md](SUPABASE_SETUP.md), jamais intégrés aux sources.
