# Profil — KIBO-007

Extension courante : « Compte et données », changement de mot de passe et demande de suppression annulable. Cette demande ne supprime pas le compte : traitement opérateur à définir/valider avant diffusion. Informations sur les accès réels (participants et administrateurs autorisés pour les messages), stockage local et coordonnées volontaires. [Rapport autonome](MVP_AUTONOMOUS_RECAP.md).

## Périmètre

Le propriétaire a validé l’édition du nom affiché et de la ville. Dans Profil, un compte connecté dont le profil est chargé peut ouvrir « Modifier mon profil ». Le formulaire reprend les valeurs actuelles, permet d’annuler et affiche les erreurs en français sans détail serveur brut. L’accueil public et les parcours KIBO-005/006 restent présents.

- `full_name` : nom affiché facultatif ; une valeur vide après trim devient `null`.
- `city` : obligatoire après trim. Saisie libre, pas de liste fermée ni de limite de longueur métier inventée ; les contraintes serveur restent applicables.
- Le formulaire indique que ces informations sont publiques, conformément au SELECT public communiqué pour `profiles`.
- Pas d’édition d’email, mot de passe, avatar, bio, quartier, identifiant ou type de compte.

## Organisation et autorisation

`lib/features/profile/edit_profile_page.dart` et `profile_validation.dart` portent le formulaire et la validation partagée. Le repository auth existant expose `updateProfile` ; aucun second client ni package ajouté. Le contrôleur existant maintient profil, chargement et message de résultat.

Le formulaire capture l’identifiant de son profil. Le contrôleur et le repository le comparent à la session courante avant d’envoyer la requête. L’écriture est un PATCH/UPDATE de `full_name` et `city` seulement, filtré par `id` courant ; aucun INSERT/UPSERT. Les champs `account_type`, `id`, dates et autres données ne sont jamais écrits. Le client demande en retour `id, full_name, city` et exige exactement une ligne correspondant au propriétaire avant d’annoncer un succès. Zéro ligne, refus RLS ou erreur réseau restent des échecs ; les saisies sont conservées pour réessayer.

Ces contrôles Flutter complètent la politique distante `profiles_update_own` communiquée par le propriétaire (`id = auth.uid()` en USING et WITH CHECK). Ils ne remplacent ni RLS ni les grants serveur ; aucune politique ni permission distante n’a été modifiée ou testée réellement pendant l’implémentation.

Les doubles soumissions sont bloquées ; les actions et champs sont désactivés durant l’enregistrement, ainsi que le retour de l’écran. L’annulation avant envoi n’écrit rien. Une requête déjà envoyée n’est pas annulée au niveau serveur par un changement de session : sa réponse est ignorée pour le nouveau compte, dont le profil est rechargé. Le brouillon de l’ancien compte n’est plus affiché après changement de session. Les réponses de lecture obsolètes ne doivent pas remplacer une sauvegarde courante.

## Vérification et procédure de recette

Les tests utilisent des comptes fictifs et un transport HTTP simulé, sans écriture distante. Ils couvrent le PATCH filtré et ses deux champs, le nom effacé, le refus sans session/avec ancienne identité, ville vide, RLS simulée et zéro ligne ; contrôleur, doubles soumissions, réponse tardive, changement de compte, erreur/reprise, annulation et rendu à 320 px, texte 150 %, clavier visible. Les tests KIBO-005/006 sont conservés.

Procédure Android (résultats réellement obtenus et limites ci-dessous) :

1. Se connecter avec un compte de test existant. Ouvrir Profil puis Modifier mon profil ; vérifier les valeurs et le thème Manrope/Emerald.
2. Effacer la ville : message requis sans envoi ; saisir une ville et un nom de test puis Enregistrer. Vérifier le retour au profil et le message de succès.
3. Arrêter/relancer puis vérifier les valeurs relues du serveur. Effacer uniquement le nom et enregistrer : le nom doit rester facultatif.
4. Modifier puis Annuler : les données enregistrées restent identiques. Tester hors réseau : erreur compréhensible et saisie conservée ; réessayer après rétablissement.
5. Tester avec un second compte : aucun brouillon ni profil du premier ne doit s’afficher. Les refus RLS réels nécessitent un protocole séparé autorisé ; ne pas modifier une politique pour les simuler.
6. Vérifier 100 %/150 % et clavier, puis restaurer le réglage initial du téléphone.

Cette recette implique des UPDATE réels : elle n’a pas été exécutée pendant le développement. Aucun changement de Supabase distant, migration, dépendance, commit ni push. KIBO-006 reste en attente de sa recette email bloquée par HTTP 429 ; KIBO-007 ne contourne pas cette limitation.

## Recette physique — 2026-10-31

Le propriétaire a ensuite autorisé la recette avec ses deux comptes de test et les UPDATE via l’application. Seuls les résultats fonctionnels sont consignés : aucun identifiant, valeur de profil, clé, mot de passe ou jeton n’est reproduit. Les confirmations d’écran proviennent du propriétaire ; détection, comparaison des APK et arrêt/relance ont été exécutés par l’agent via ADB.

| Scénario | Résultat constaté |
|---|---|
| Version installée | L’ancienne installation précédait KIBO-007. Nouvelle compilation debug ARM64 et installation `adb install -r` réussies selon le propriétaire, sans désinstallation/effacement. SHA-256 de l’APK installé et de l’APK local comparés : identiques. |
| Préremplissage | Premier compte : nom et ville correspondent au profil courant. |
| Sauvegarde en ligne | Les deux champs modifiés sont affichés sur Profil avec « Profil mis à jour. ». |
| Arrêt complet puis relance | Arrêt par `am force-stop` puis démarrage de MainActivity réussis ; session et deux nouvelles valeurs conservées, selon confirmation. |
| Annulation | Deux champs modifiés puis Annuler : valeurs enregistrées inchangées sur Profil et dans le formulaire rouvert. |
| Sauvegarde hors réseau | Wi-Fi et données mobiles désactivés manuellement : erreur compréhensible, saisies conservées, bouton Enregistrer réactivé. |
| Nouvelle tentative en ligne | Après rétablissement des connexions dans leur état initial, enregistrement réussi sans ressaisie ; les deux valeurs et le message de succès s’affichent. |
| Second compte | Connexion avec le second compte : ses propres valeurs uniquement, aucun brouillon du premier. Sauvegarde de deux valeurs distinctes réussie. |
| Retour au premier compte | Ses dernières valeurs enregistrées avant changement de compte sont intactes sur Profil et dans le formulaire ; aucune valeur du second compte n’apparaît. |

Aucun échec fonctionnel ni blocage rencontré dans ces scénarios. Aucun correctif applicatif ni collecte de logs supplémentaire nécessaire. Aucun changement de réglage Supabase, schéma, politique RLS ou dépendance ; aucun commit ni push. Seuls `docs/PROFILE.md` et `docs/NEXT_TASK.md` sont actualisés pendant cette recette ; autres modifications locales préservées.

### Limites et contrôles non réalisés physiquement

- L’isolation vérifiée concerne le parcours normal de l’application. Aucune requête forgée sous le compte B ne cible l’ID du compte A ; le refus RLS serveur d’une telle tentative n’est donc pas certifié. Les tests automatisés de RLS restent des simulations.
- Ville vide et effacement complet du nom : couverts automatiquement, pas exercés pendant cette recette physique.
- Rendu à 100 %/150 % et contrôle visuel détaillé Manrope/Emerald/clavier : pas de nouvelle validation physique dédiée. Le test widget à 320 px/texte 150 % est distinct.
- Aucune nouvelle validation du callback KIBO-006, d’une expiration/rotation de jeton, ni d’iOS ou d’un build release.

### Contrôles après recette

- `dart format lib test` : réussi, 31 fichiers, 0 changement.
- `flutter analyze --fatal-infos` : aucune anomalie, code 0 (3,6 s).
- `flutter test --reporter expanded` : 67 tests réussis, code 0 (environ 5 s).
- `git diff --check` : réussi, code 0 ; avertissements Git de conversion LF/CRLF uniquement.
- Comparaison des empreintes des fichiers locaux avec l’état de départ de recette : seuls `docs/PROFILE.md` et `docs/NEXT_TASK.md` ont changé, aucun fichier supprimé. Aucun commit ni push.
