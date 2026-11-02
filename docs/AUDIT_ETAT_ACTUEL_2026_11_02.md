# Bilan de KIBO — état examiné le 2 novembre 2026

## 1. Avis général

**KIBO est un MVP fonctionnel en phase de recette. Il est utilisable pour des tests encadrés. Je ne le considère pas encore prêt pour un lancement public large.**

La consultation, la publication, les photos, les favoris, les échanges et une première administration existent réellement. Les priorités sont de fiabiliser les parcours, protéger l’exploitation et achever les obligations nécessaires à une diffusion publique.

Les manques les plus importants sont : conservation/versionnement du travail, recherche française encore défaillante sur certains préfixes, suppression effective de compte, préparation de diffusion, notifications hors application, gestion des photos déjà publiées, outils de confiance/modération et validation réelle sur plusieurs appareils.

Ce rapport est une analyse, **pas une autorisation de corriger ou déployer tous les points cités**. Aucun compte, contenu, rôle, réglage, politique, objet Storage ou schéma distant n’a été modifié pendant cet audit. Aucun commit/push ni nouvelle installation n’a été effectué pour l’audit.

## 2. Ce qui a été contrôlé et ce qui ne l’a pas été

Contrôles effectués :

- Dépôt local, branche main, statut Git, sources Flutter, configuration de compilation et workflow CI.
- Documentation récente, en distinguant les paragraphes historiques et les comptes rendus actuels.
- Analyse Flutter relancée : **aucune anomalie**.
- Suite standard relancée : **443 tests réussis**. Ce sont principalement des tests unitaires/widgets et des échanges HTTP simulés, pas 443 scénarios réels sur téléphone.
- Format en lecture seule : 147 fichiers, aucun changement nécessaire. Diff sans erreur d’espacement ; avertissements LF/CRLF Git seulement.
- Lecture distante des tables, RLS, politiques pertinentes, métadonnées Auth/Storage, rôles agrégés, migration et fonction photo active ; conseillers sécurité et performance.
- Vérification publique des fournisseurs Auth et reproduction de recherches par l’API sous les droits visiteur.
- Consultation agrégée des journaux sur la fenêtre de 24 h par défaut, sans afficher de messages, jetons, coordonnées ou identités privées.

Limites importantes :

- Le lot précédent avait aussi validé 443 tests avec photos activées ; cette variante n’a pas été rejouée dans le présent audit, qui ne change pas l’application.
- Dernière installation documentée : TECNO, mode **profile**, processus 20344, premier plan confirmé. Pas de nouveau parcours exhaustif de tous les écrans sur téléphone pendant cet audit.
- Pas de test d’intrusion, de recette destructive, de simulation de nombreux utilisateurs concurrents, de mesure FPS/mémoire/batterie, de test iOS ou de build release signé.
- Pas de pourcentage de couverture de code calculé. Un nombre de tests ne constitue ni une certification de sécurité ni une preuve de performance.
- Sauvegardes cloud, restauration complète, facturation/quotas et disponibilité contractuelle n’ont pas été certifiés.

Les conclusions sont soit **constatées** (code, métadonnées, reproduction), soit des **risques à vérifier**, soit des **propositions produit**. Ces catégories ne doivent pas être confondues.

## 3. Photographie de l’environnement connecté

Chiffres constatés au moment des contrôles ; ils peuvent changer après une nouvelle utilisation.

| Élément | État constaté |
|---|---|
| Comptes Auth | 3, dont 1 administrateur |
| Tables applicatives public | 18, toutes avec RLS active |
| Annonces | 1 200 : 1 193 publiées, 3 pending, 3 archivées, 1 vendue |
| Annonces des deux lots fictifs | 1 188, toutes publiées à cet instant |
| Autres annonces | 12 ; leur caractère commercial réel n’est pas présumé |
| Commentaires | 4 753, dont 4 752 sur les lots fictifs |
| Notifications | 4 755 |
| Conversations / messages | 2 / 5 ; cela ne prouve pas une recette simultanée complète |
| Signalements / demandes de compte | 0 / 0 présents à cet instant |
| Photos du nouveau système | 1 199 réservations et 1 199 objets |
| Cohérence des photos | 0 réservation sans objet, 0 objet sans réservation ; 0 annonce publiée sans photo à cet instant |
| Taille des JPEG stockés | Environ 10 Ko en moyenne ; maximum constaté 247 590 octets |
| Prix NULL | 0 annonce actuellement sans prix ; la colonne est bien nullable |
| Google / email / téléphone | Google et email activés ; Phone désactivé |
| Confirmation email | Auto-confirmation désactivée |
| MFA Supabase admin | 0 facteur vérifié constaté ; la sécurité éventuelle du compte Google externe n’est pas contrôlée ici |
| Realtime | Tables conversations et messages présentes dans la publication |
| Fonction serveur photo | kibo-upload-listing-photo ACTIVE, version 1, vérification JWT activée |
| Migrations distantes / fichiers locaux migrations | 19 / 4 ; 21 autres fichiers SQL dans proposals |

**99 % des annonces en table sont fictives.** Le volume aide à tester les pages et le cache ; il ne mesure ni l’activité commerciale, ni la concurrence, ni la capacité maximale. Les 95 visuels sources réutilisés et les petites images rendent le jeu plus léger qu’un catalogue de grandes photos toutes différentes.

Les tests sont dans la base utilisée par l’application normale, sur instruction explicite antérieure. Avant ouverture à de vrais utilisateurs, prévoir un environnement de recette séparé et un retrait contrôlé des fixtures. Ne pas supprimer simplement tout ce qui commence par TEST : utiliser les manifestes et préserver toute contribution ultérieure de tiers.

## 4. Fonctions déjà solides

| Domaine | Ce qui existe |
|---|---|
| Navigation et présentation | Identité Manrope/Emerald, thèmes clair/sombre, composants communs, tests de petits écrans et texte agrandi. |
| Consultation | Catalogue public, catégories, villes du Congo, détail, photos, ancienneté et filtres. |
| Prix | Facultatif réellement activé côté Flutter et PostgreSQL ; zéro distinct de l’absence, affichage Prix à négocier. |
| Publication | Publication immédiate, contrôles de champs, brouillon local avec photos et reprise par identifiant stable. |
| Photos | Jusqu’à trois, compression, contrôle de taille/dimensions, suppression des métadonnées GPS/EXIF, validation serveur et bucket privé. |
| Gestion vendeur | Recherche/statuts, modification du texte/prix, vente, retrait par archivage, sélection des cartes et actions groupées confirmées. |
| Favoris | Locaux sans compte, synchronisés après connexion, transfert local vers compte sur confirmation explicite. |
| Contact | Profil vendeur minimal, contacts volontaires distincts d’Auth, WhatsApp/appel après connexion, message direct avec connexion préalable. |
| Chat | Texte persistant, pagination, Realtime, secours périodique, compteurs de non-lus, modification/suppression de ses messages, blocage. |
| Commentaires | Racines et un niveau de réponses, publication réservée aux membres, consultation publique, signalement. |
| Sécurité de session | Stockage sécurisé des sessions/PKCE, invalidation lors des changements de compte, refus des réponses tardives et vérifications serveur. |
| Administration | File de signalements, décisions motivées et journalisées, masquage, traitement des demandes de compte. |

Il faut conserver ces protections lors des améliorations. Une simplification visuelle ne doit pas supprimer les contrôles serveur, l’isolation des comptes ou les confirmations d’actions groupées.

## 5. Défaut confirmé : recherche française incomplète

La recherche porte bien sur **titre et description**. Elle est progressive dès trois caractères et utilise des préfixes. La correction récente fonctionne pour certains termes, mais pas pour tous les débuts de mots français.

| Saisie | Résultat serveur constaté |
|---|---:|
| iph | 44 annonces |
| tél | 0 |
| télé | 0 |
| télép | 0 |
| téléphone | 132 |

Le cas tél a également été confirmé via l’API visiteur : zéro résultat, alors que téléphone retourne un total de 132. Ce n’est donc pas seulement un résultat artificiel d’une requête opérateur.

Cause constatée : PostgreSQL transforme `tél:*` et `télé:*` avec son dictionnaire français en `tel:*`, alors que le mot Téléphone est indexé comme `téléphon`. Les deux ne correspondent pas. La gestion des accents et la réduction des mots français perturbent les préfixes courts.

**Priorité élevée :** harmoniser la normalisation entre index et requêtes, puis ajouter des tests réels sur accents, préfixes courts, pluriels, marques, modèles, apostrophes et plusieurs mots. Changer seulement un paramètre client sans vérifier le vecteur existant serait insuffisant.

Autres limites de recherche :

- Pas de correction de fautes, de synonymes, de suggestion ou d’historique.
- Pas de classement par pertinence ; les tris proposés sont date et prix. Les poids titre/description du vecteur ne sont pas exploités par un classement ts_rank.
- Pas de filtre condition du produit, surface, kilométrage, capacité ou autres attributs métier ; pas de rayon géographique.
- Pagination de vingt avec bouton Voir plus, pas de chargement automatique à l’approche du bas.
- Risque déduit du code : la pagination par offset peut se décaler si de nouvelles annonces arrivent entre deux pages. Tester les doublons/sauts et envisager curseur/dédoublonnage.

Ces dernières limites sont des améliorations, pas toutes des défauts bloquants du MVP.

## 6. Publication, photos et cycle de vie des annonces

### Gestion des photos : incohérence importante

Avant publication, le vendeur peut préparer jusqu’à trois photos et choisir leur ordre. Après publication :

| Situation | Possibilité actuelle |
|---|---|
| Annonce sans photo | Ajouter un lot jusqu’à trois photos. |
| Annonce avec une photo | Pas de parcours pour simplement compléter avec une deuxième/troisième. |
| Mauvaise photo déjà publiée | Pas de remplacement ni de retrait individuel. |
| Ordre des photos déjà publiées | Pas de réorganisation. |

L’utilisateur peut modifier le titre et le prix, mais pas corriger aussi simplement une photo. C’est un vrai manque du parcours vendeur. Il faut un contrat serveur pour retirer/remplacer/réordonner proprement, pas seulement ajouter des boutons.

La publication et les photos ne forment pas une transaction unique. L’annonce peut être créée avant que toutes les images aient réussi. La reprise par identifiant et les messages d’échec existent, ce qui est positif ; il reste à valider ce parcours sur réseau réel et à prévoir l’entretien des réservations/objets incomplets. **L’audit actuel n’en constate aucun orphelin.**

### Statuts et suppression

La suppression proposée est un **archivage**, conservant historique, photos et échanges. Ce choix est cohérent avec une marketplace, à condition de le dire clairement.

Manques :

- Pas de republication d’une annonce archivée ou vendue.
- Pas de parcours complet corriger puis soumettre à nouveau après rejet.
- Les anciens statuts pending/rejected n’offrent pas tous les mêmes actions ; le nouveau parcours publie directement, mais trois anciennes pending existent encore.
- Pas d’expiration/renouvellement d’annonce constaté dans le parcours actuel ; un catalogue peut conserver de vieilles offres si le vendeur ne les retire pas.
- Les actions groupées couvrent les annonces éligibles déjà chargées, pas toutes les pages du compte. Il faut conserver cette précision.

### Champs et prix

Le prix facultatif est bien appliqué, mais aucun enregistrement NULL n’est encore présent : la publication réelle sans prix sur appareil reste à recetter. Les filtres de prix excluent naturellement les annonces sans montant ; ce comportement mérite une explication ou un filtre Prix à négocier.

Les neuf catégories partagent un formulaire très générique. Pour les catégories les plus utilisées, ajouter progressivement des champs utiles : état/marque/modèle pour téléphones, caractéristiques pour véhicules, surface/type pour immobilier. Les champs obligatoires supplémentaires doivent rester limités.

Les villes du Congo sont contrôlées par le sélecteur de l’interface. Le stockage reste textuel ; l’inspection des contraintes n’a pas trouvé de référence serveur à une liste de villes. Une normalisation par identifiant de ville serait utile pour la qualité des données et l’évolution internationale.

## 7. Compte, connexion et téléphone

### État réel

- Email/mot de passe, récupération et changement de mot de passe existent ; l’auto-confirmation email est désactivée.
- Google est proposé dans l’interface et activé dans les réglages publics. **Cela ne prouve pas un parcours complet réussi** : choix du compte, consentement, redirection, retour à froid, doublon d’email, persistance et annulation restent à consigner sur appareil.
- Téléphone +242/OTP est préparé dans Flutter, mais Phone est désactivé côté service et le fournisseur SMS n’est pas opérationnel dans ce lot.
- Les identifiants Auth ne sont pas automatiquement publiés comme coordonnées vendeur : bon choix de confidentialité.

### Avant activation du téléphone

Choisir un fournisseur réellement compatible Supabase/+242, vérifier réception et coût, expiration, renvoi, erreurs et limites serveur. Le délai local de renvoi ne suffit pas contre les abus. Un prestataire incompatible demandera un hook serveur spécifique. Le challenge CAPTCHA n’est pas intégré au formulaire ; l’adapter si la politique serveur le demande.

Prévoir les changements de numéro et les comptes créés par plusieurs méthodes : Google, email et téléphone peuvent produire des parcours de compte distincts. Aucune fusion arbitraire des comptes ne doit être faite par simple correspondance de saisie.

### Manques de sécurité de compte

- Pas de parcours MFA dans l’application ; aucun facteur Supabase vérifié constaté pour l’administrateur.
- Pas de gestion des appareils/sessions exposée au membre.
- La protection Supabase contre les mots de passe compromis est signalée désactivée.
- Deliverabilité email, redirections de production et reprise de compte après changement d’appareil restent à valider.

Le téléphone sans OTP/preuve de possession ne doit pas être présenté comme une alternative acceptable pour accéder aux comptes d’autres personnes. Une bonne simplification consiste à utiliser un code SMS fiable ou Google, pas à retirer l’authentification.

## 8. Profils et confiance entre membres

Le profil vendeur public est minimal : nom et ville. Il n’expose pas encore avatar, présentation, catalogue complet du vendeur, ancienneté clairement mise en avant, évaluations ou identité de boutique.

Dans les commentaires, les auteurs sont présentés comme Vous/Membre, ce qui limite la reconnaissance. Une identité publique minimale cohérente serait préférable à un affichage très générique, sans rendre publics des champs privés.

WhatsApp et appel peuvent être affichés même si le vendeur n’a pas activé ces moyens ; l’indisponibilité est découverte après le clic. Améliorer l’affordance en exposant seulement une disponibilité autorisée, sans diffuser les numéros au chargement.

La connexion obligatoire pour obtenir les contacts est un choix produit déjà validé. Elle protège mieux les coordonnées mais ajoute une étape au contact ; son effet sur la conversion devra être mesuré.

Les favoris visiteurs et les brouillons sont locaux. Ils ne constituent pas une sauvegarde cloud : changement de téléphone ou effacement des données peut les faire perdre. La synchronisation des favoris compte existe ; leur transfert reste volontaire.

Évaluations, vendeurs suivis et boutiques vérifiées sont des pistes utiles plus tard. Une note ne doit pas être présentée comme une preuve de transaction si KIBO ne sait pas attester qu’un échange a eu lieu.

## 9. Messagerie et notifications

### Ce qui fonctionne

Chat lié à une annonce, messages texte, historique, compteurs de non-lus, modification/suppression de ses messages et blocage sont implémentés. Les identifiants stables limitent les doublons lors des reprises. Les abonnements sont suspendus quand l’application passe en arrière-plan.

### Limite commerciale majeure : pas de push

Les notifications actuelles sont **dans KIBO**. Aucun service de notifications système n’est intégré au client. Un utilisateur ayant fermé l’application ne reçoit pas une alerte KIBO comparable à une notification WhatsApp. Cela peut allonger fortement les délais de réponse d’une marketplace.

Les préférences de notifications existantes concernent les catégories de notifications internes ; elles ne constituent pas l’activation de notifications push.

### Autres limites

- Pas de photo, pièce jointe ou audio dans le chat.
- Pas d’indicateur de saisie/présence ni de présentation complète envoyé/reçu/lu comparable aux grandes messageries. Le suivi de lecture serveur ne doit pas être confondu avec cette interface.
- Pas de boîte d’envoi hors ligne avec reprise contrôlée ; les erreurs incertaines demandent de vérifier/reprendre, ce qui évite des doublons mais reste à améliorer.
- Pas de signalement de message ou de profil depuis les parcours actuels, alors que le blocage et les signalements d’annonce/commentaire existent.
- Le blocage protège les nouveaux messages KIBO ; il ne peut pas bloquer un appel externe ou effacer un numéro déjà obtenu.
- Realtime est complété par une relecture toutes les 15 secondes. Les compteurs ont aussi des rafraîchissements à 30 secondes. Mesurer les requêtes et la visibilité des routes pour éviter des lectures inutiles ; ne pas supprimer le secours sans solution de fiabilité.

### Confidentialité réelle

Le code n’implémente pas de chiffrement de bout en bout. **Les politiques serveur autorisent l’administrateur à lire conversations et messages**, même si l’interface habituelle filtre les conversations du membre. Cette possibilité est déjà mentionnée dans Compte et données.

Ce n’est pas un accès public constaté, mais un privilège interne sensible. Il faut décider qui en a besoin, limiter les rôles futurs et journaliser les accès opérateur nécessaires. Ne pas promettre une confidentialité technique identique à WhatsApp.

## 10. Compte officiel KIBO et administration

### Badge officiel : encore une proposition

La discussion sur le compte Équipe KIBO **n’a pas encore été implémentée**. Il n’y a ni badge officiel protégé et affiché dans les conversations/profils, ni identité publique dédiée de communication.

Un rôle admin donne des droits internes ; il ne doit pas automatiquement certifier que tous ses échanges sont une communication officielle de la plateforme.

À prévoir avant cet usage :

1. Une identité publique Équipe KIBO contrôlée côté serveur, avec logo, badge et libellé explicite.
2. Protection contre les noms/imitations visuelles laissant croire à un compte officiel. Un utilisateur peut choisir un nom ressemblant à KIBO ; une simple coche dans le nom ne doit pas être reconnue comme certification.
3. Affichage homogène dans profil, conversations et messages, avec contrôle serveur de l’expéditeur.
4. Un parcours pour contacter un membre sans détourner une conversation d’achat. Le chat actuel démarre à partir d’une annonce ; ce n’est pas une messagerie de support générale ou un outil d’annonce officielle à tous.
5. Journal des communications, politique d’usage et maîtrise de l’envoi en masse.

### Administration actuelle

Deux modules mobiles : signalements/modération et demandes de compte. Décisions motivées, confirmations et journaux sont de bons points. Les compteurs du tableau sont des premières pages avec 20+, **pas des statistiques complètes de la marketplace**.

Manquent : rôle modérateur distinct, gestion sécurisée de l’équipe, recherche/gestion des membres, sanctions globales temporaires, recours/correction après rejet, restauration contrôlée de contenu et supervision de la qualité du catalogue. Pas de console web dédiée.

Un seul compte admin est présent. Réduire le risque de perte/compromission : MFA, procédure de récupération, droits minimaux et continuité opérateur. Éviter de multiplier les comptes tout-puissants pour résoudre un besoin de modération.

L’outil ne suffit pas à organiser la modération : responsable, horaires, règles de contenu, priorités et traitement d’un incident doivent être définis. La publication immédiate rend cette organisation particulièrement importante.

## 11. Suppression de compte : demande traitable, effacement non opérationnel

L’écran enregistre une demande, permet son suivi et son traitement opérateur. **Il ne supprime pas réellement le compte ni toutes ses données.** La clôture administrative n’est pas une preuve d’effacement.

Un prototype local d’historique/anonymisation et un moteur à adaptateurs fictifs existent. Il manque les adaptateurs réels, les règles de conservation approuvées et l’orchestration PostgreSQL/Storage/Auth. Certaines dépendances peuvent bloquer l’effacement ou supprimer les contributions d’autres personnes si l’on utilise des DELETE/cascades simples.

Il faut pouvoir retirer identité, annonces et coordonnées tout en traitant correctement l’historique des autres participants, les commentaires/réponses et les preuves de modération. Sauvegardes, anciens JWT et délais de conservation doivent aussi entrer dans la conception.

Pour Google Play, les applications concernées doivent proposer un chemin de demande de suppression dans l’application et une ressource web extérieure. Le fonctionnement effectif du traitement reste indispensable ; un simple statut traité ne suffit pas. [Exigences officielles Google Play](https://support.google.com/googleplay/android-developer/answer/13327111).

Pour une future diffusion Apple, la possibilité d’initier la suppression depuis l’application est également une exigence. [Référence Apple](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/).

C’est un préalable à traiter avant diffusion publique, pas un simple bouton à ajouter. Les textes juridiques et les durées de conservation doivent être validés selon l’exploitation réelle ; cet audit n’est pas une certification juridique.

## 12. Sécurité et abus : acquis et chantiers

### Acquis constatés

- RLS active sur les 18 tables public, pas de vue publique détectée dans cet inventaire.
- Rôle admin lu dans app_metadata signé ; pas de droit accordé par un nom ou user_metadata.
- Sessions/PKCE dans le stockage sécurisé ; sauvegarde Android automatique désactivée.
- Coordonnées vendeur privées et volontaires, distinctes d’Auth.
- Nouveau bucket photo privé, taille/MIME bornés, décodage JPEG complet et contrôle du propriétaire/réservation côté serveur ; métadonnées GPS/EXIF supprimées.
- Aucune incohérence réservation/objet détectée à cet instant.
- Trois fonctions SECURITY DEFINER restantes dans public sont des fonctions de trigger ; leur exécution directe anon/authenticated est révoquée.
- Limites serveur constatées : 30 nouveaux messages/minute/membre et 5 signalements/minute/membre, avec verrou protégeant la concurrence.
- Configurations locales privées ignorées par Git et non suivies ; pas de clé privilégiée requise dans Flutter pour ces fonctions.

Ces contrôles ne constituent pas un test exhaustif de tous les accès forgés et changements de session.

### Écarts et risques

1. Protection des mots de passe compromis désactivée, signalée par le [conseiller Supabase](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
2. Absence de MFA Supabase constatée sur le compte admin, dont les droits sont larges.
3. Limites de débit non constatées sur tous les parcours : publication, commentaires et chargements photo méritent des plafonds anti-abus/coûts. Les limites de taille et RLS ne remplacent pas un quota de débit.
4. Ancien bucket listing-images toujours public avec anciennes règles d’envoi. **Il est vide et la table legacy listing_images est vide** : aucune fuite d’objet de ce bucket n’est constatée. Auditer puis fermer le chemin inutilisé après validation, plutôt que laisser deux contrats actifs.
5. Pas de recette offensive complète sur projet de staging avec comptes A/B/admin, anciens jetons et opérations concurrentes.
6. Pas d’outillage applicatif global de remontée des crashs/incidents constaté ; les diagnostics photo et journaux métier ne remplacent pas un suivi global expurgé.

Le conseiller mentionne aussi le journal kibo_message_action_log avec RLS sans politique. Son accès client direct est volontairement fermé : **ne pas créer une politique permissive juste pour faire disparaître l’information**. [Explication du linter](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## 13. Performance et qualité perçue

### Cache et images

Le cache est réel : mémoire, 24 Mio de fichiers compressés, 100 entrées maximum et TTL de 45 secondes ; changement de session invalidant le cache. Flutter conserve aussi ses images décodées : 24 Mio n’est donc pas un plafond de mémoire totale de l’application.

Les images peuvent être retéléchargées après expiration, éviction, changement de compte ou redémarrage. Ce comportement explique certains rechargements ; ce n’est pas une preuve d’absence de cache. Le TTL court et l’absence de cache disque limitent cependant le confort sur réseau lent.

Les cartes adaptent la résolution de décodage, mais le transfert peut encore porter le fichier stocké complet. Prévoir de vraies vignettes et tailles adaptées, puis mesurer le bénéfice. Toute extension du cache doit conserver l’invalidation des contenus retirés et la séparation des comptes.

### Base et charge

Un index GIN pour la recherche et plusieurs index de catalogue existent. Les conseillers signalent **7 clés étrangères sans index couvrant**, **3 politiques évaluant des fonctions Auth ligne par ligne** et des politiques permissives multiples pour categories. C’est un plan d’optimisation, pas une preuve que la base est actuellement lente.

[Index de clés étrangères](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys), [évaluations RLS](https://supabase.com/docs/guides/database/database-linter?lint=0003_auth_rls_initplan), [politiques multiples](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies).

Les index signalés inutilisés ne doivent pas être supprimés automatiquement sur la base d’un petit trafic de recette. Mesurer les requêtes et leur coût réel d’abord.

### Ce qui manque pour parler de fluidité prouvée

Mesurer en mode profile sur le TECNO : ouverture à froid/à chaud, première page/photo, défilement prolongé, recherche, retour d’onglets, mémoire après plusieurs minutes et consommation réseau. Refaire sur connexion lente, réseau interrompu et catalogue avec trois grandes images par annonce.

Un test avec 1 188 annonces n’équivaut pas à des centaines d’utilisateurs simultanés. Préparer ensuite une charge progressive dans un environnement séparé, avec objectifs et limites de coûts convenus. Aucun chiffre FPS ou seuil de capacité maximale n’a été démontré.

## 14. UX, simplicité et accessibilité

Les derniers correctifs améliorent les espacements, la sélection des cartes, le rafraîchissement et l’uniformité du profil. Les tests couvrent plusieurs petits écrans et grandes tailles de texte.

Il reste à vérifier sur appareil : TalkBack, ordre de focus, clavier, changements d’orientation, permission galerie refusée, grandes polices réelles, contraste des états et compréhension par une personne découvrant KIBO. L’absence de débordement dans un widget test ne prouve pas à elle seule la facilité d’utilisation.

Améliorations utiles :

- Zoom/plein écran sur les photos, au-delà de la galerie défilante existante.
- Retrait/modification de ses propres commentaires ; aucune action correspondante n’est exposée actuellement. Préserver les réponses des autres plutôt que les effacer en cascade.
- Aide et contact support facilement trouvables, version/build visible pour signaler un incident.
- Messages d’erreur plus précis et cohérents, sans exceptions techniques : distinguer réseau, session expirée, accès refusé, donnée retirée et conflit de modification.
- Parcours après connexion conduisant au contexte attendu de façon cohérente pour toutes les actions. Le message vendeur le fait déjà ; d’autres parcours invités renvoient encore vers Profil ou affichent une consigne.
- Expliquer le périmètre du blocage, du favori local, de l’archivage et du prix absent avec des libellés courts.

Éviter de rendre tous les champs obligatoires ou d’ajouter des fenêtres de confirmation pour chaque action réversible. Garder les confirmations pour les actes sensibles et groupés.

## 15. Exploitation, Git et capacité à livrer

### Point majeur : le travail actuel n’est pas encore consolidé dans Git

Le dépôt est sur main avec un travail local très important : **36 entrées suivies modifiées et 90 entrées non suivies** dans le statut enregistré au début de l’audit. Les entrées de répertoire ne sont pas un comptage de tous les fichiers.

Les **53 fichiers Dart de lib/features existent localement mais aucun n’est suivi dans l’index Git de cette branche**. Le dernier commit local est encore le socle KIBO-003.1. La présence sur le poste ne prouve donc pas que GitHub/CI/sauvegarde distante possèdent l’application actuelle. Le serveur GitHub n’a pas été interrogé pour déduire un état distant différent.

Cela résulte notamment de la règle respectée : pas de commit/push sans autorisation. Ce n’est pas une raison de publier précipitamment, mais une priorité de conservation : revue, vérification des exclusions de secrets, commits cohérents puis push autorisé.

### Reproductibilité et CI

- La CI existe pour format/analyse/tests Flutter standard.
- Elle ne vérifie pas les scénarios SQL/RLS/Edge et ne construit pas de release.
- Ses filtres de chemins ne couvrent pas directement assets, supabase ou tool ; une modification isolée dans ces dossiers peut ne pas déclencher la CI.
- Pas de dossier integration_test, donc pas de suite complète automatisée d’appareil en place dans ce format.
- 19 migrations distantes pour seulement 4 fichiers dans migrations, avec de nombreux deltas dans proposals. Il faut un historique de reconstruction cohérent et une procédure testée sur projet vide. Ce simple écart ne prouve pas une perte de migration, mais signale un travail de consolidation.
- README, MVP_STATUS et plusieurs en-têtes SQL mélangent des états anciens et actuels : prix obligatoire/facultatif, photos préparées/déployées, anciens compteurs de tests. Les comptes rendus récents les nuancent, mais une page d’état unique éviterait les erreurs de reprise.

### Distribution Android

Les installations actuelles sont des builds de recette/profile. Le fichier de configuration de signature release est absent. Le code bloque correctement une release sans signature ; **la signature de diffusion n’a pas été validée**.

Restent à fixer : propriétaire/sauvegarde de la clé, canal de test, version/build unique, artefact identifié, mise à jour sans perte de données et procédure de retour à une version compatible. pubspec indique encore 1.0.0+1 et une description de template.

Le bundle embarque environ **3,54 Mo de fixtures** de catalogue, dont le manifeste de 1 080 annonces. Ces fichiers ne sont pas un secret, mais devraient être réservés aux builds de développement plutôt qu’à la distribution publique.

### Exploitation réelle

À formaliser : responsabilité des incidents, contact support, sauvegarde base **et images**, test de restauration, rétention, alertes d’erreur, suivi des coûts/quotas, capacité à désactiver une fonction problématique et séparation recette/production.

Les journaux agrégés consultés montrent une activité API/Storage/Auth importante liée notamment aux imports. Dans la vue edge_logs sur la fenêtre consultée : 4 Auth 400, 6 Data 409 et 17 Storage 400, sans 5xx observé dans cette vue. Ces réponses ne sont pas automatiquement des défauts : conflits de reprise et sondes de contrôle peuvent en produire. Ce n’est ni un taux d’erreur commercial ni un engagement de disponibilité ; il faut corréler des parcours identifiés.

## 16. Préparation iOS et hors périmètre

iOS est une étape ultérieure assumée. Une autorisation galerie est préparée, mais le schéma de retour d’authentification n’est pas configuré dans Info.plist et aucun build/recette iOS n’est validé.

Avec Google pour l’authentification principale, il faudra vérifier les exigences Apple de connexion équivalente ; Sign in with Apple est une solution habituelle, sous réserve des exceptions et critères applicables. [Règle officielle 4.8](https://developer.apple.com/app-store/review/guidelines/#login-services).

Paiement intégré, livraison, abonnement et annonces sponsorisées sont **hors V1**, pas des oublis bloquants. Les ajouter maintenant augmenterait fortement la charge d’exploitation et de contrôle. Ils ne doivent pas retarder les parcours de base.

## 17. Priorités proposées

P0 = préalable avant diffusion publique ou conservation fiable du projet ; P1 = important pour le pilote et la confiance ; P2 = amélioration après stabilisation ; P3 = évolution ultérieure.

| Priorité | Sujet | Pourquoi |
|---|---|---|
| P0 | Consolider/sauvegarder le code avec autorisation | Application actuelle largement locale et non suivie. |
| P0 | Préparer suppression effective et ressource web | Demande existante, effacement non opérationnel, exigences de diffusion. |
| P0 | Signature/canal de diffusion, version et restauration | Build de recette différent d’un produit distribué et maintenable. |
| P0 | Confidentialité, règles, support et conservation validés | Des données personnelles et des décisions de modération seront traitées. |
| P0 avant public | Isoler la recette et retirer les fixtures de l’offre publique | 99 % du catalogue actuel est fictif. |
| P1 | Corriger les préfixes français et tester réellement | Défaut reproduit sur tél/télé. |
| P1 | Finaliser la recette multi-appareils et réseau dégradé | Plusieurs parcours restent prouvés surtout par mocks/fixtures. |
| P1 | Modifier/compléter/retirer les photos déjà publiées | Incohérence du cycle vendeur quotidien. |
| P1 | Notifications push | Un vendeur hors application peut manquer une demande. |
| P1 | MFA admin, droits minimaux et supervision | Un seul admin avec privilèges sensibles. |
| P1 avant communication officielle | Identité Équipe KIBO, badge serveur et canal adapté | Proposition discutée mais non livrée. |
| P1 | Signalements de messages/profils, couverture anti-abus | Blocage et signalements actuels incomplets. |
| P1 | Politique et opérations de modération/recours | Publication immédiate et manque de resoumission après rejet. |
| P1 pour cible téléphone | Fournisseur OTP réellement testé +242 | Code préparé mais service non activé. |
| P1/P2 | Profilage images/réseau et suivi des incidents | Pas de fluidité/capacité maximale prouvée. |
| P2 | Optimiser cache, vignettes, index/RLS après mesures | Diminuer données téléchargées et lectures inutiles. |
| P2 | Republication, expiration, commentaires modifiables | Compléter le cycle de vie de contenu. |
| P2 | Profils enrichis, partage de lien, recherches enregistrées | Faciliter confiance et découverte organique. |
| P3 | iOS, métiers avancés et monétisation future | Après validation du lancement Android. |

## 18. Ordre de travail en lots

**Lot A — conservation et environnement** : revue/versionnement autorisé du travail ; environnement de recette séparé et inventaire des fixtures ; reconstruction documentée et CI couvrant assets/SQL/Edge.

**Lot B — parcours de base** : correction recherche française ; gestion complète des photos publiées ; recette à deux appareils avec erreurs réseau, session et reprises.

**Lot C — confiance** : compte officiel et badge serveur ; protection/rôles de l’équipe ; signalement des messages/profils et traitement motivé avec recours.

**Lot D — préparation publique** : suppression effective contrôlée ; pages publiques confidentialité/support/suppression et politique de conservation ; signature, version et canal pilote maîtrisé.

**Lot E — engagement et vitesse** : push ; activation OTP après fournisseur ; mesures puis optimisation des images/rafraîchissements/index.

Chaque lot devrait se terminer par preuves locales, contrôles serveur si autorisés, installation/recette correspondant au périmètre et mise à jour d’un état produit consolidé. Aucun délai ferme n’est promis sans préciser les fournisseurs, les règles de conservation et les conditions de diffusion.

## 19. Références de vérification

Principaux fichiers lus :

- [État et historique](PROGRESS.md), [prochaine tâche](NEXT_TASK.md), [pilote Android](ANDROID_PILOT.md), [recette deux comptes](RECETTE_MVP_DEUX_COMPTES.md).
- [Recherche](../lib/features/listings/listing_query.dart), [repository catalogue](../lib/features/listings/listing_repository.dart), [cache photo](../lib/features/listings/listing_photo_cache.dart), [gestion propriétaire](../lib/features/listings/owned_listing_repository.dart), [éditeur](../lib/features/listings/edit_listing_page.dart).
- [Chat](../lib/features/chat/chat_repository.dart), [commentaires](../lib/features/comments/comments_repository.dart), [profil vendeur](../lib/features/seller/seller_repository.dart), [administration](../lib/features/safety/admin_page.dart), [informations compte](../lib/features/profile/account_settings_page.dart).
- [Suppression : procédure](ACCOUNT_DELETION_RUNBOOK.md), [prototype non déployé](RETAINED_HISTORY_PROTOTYPE.md), [Google](GOOGLE_AUTH.md), [téléphone](PHONE_AUTH.md).
- [CI](../.github/workflows/flutter_ci.yml), [dépendances/assets](../pubspec.yaml), [signature Android](../android/app/build.gradle.kts), [iOS](../ios/Runner/Info.plist).
- [Requêtes d’inventaire et reproduction en lecture seule](../supabase/audits/application_state_readonly.sql). Les contrôles correspondants ont été exécutés séparément par le connecteur ; ce fichier n’est pas une migration et ne doit pas être exposé dans l’application.

Journaux locaux de vérification : `.dart_tool/audit-{analyze,tests,format,diff-check}.log` et inventaire Git `.dart_tool/audit-current-status.txt`. Ces fichiers ignorés ne constituent pas une sauvegarde du projet. Les données métier privées et secrets ne sont pas inclus dans ce rapport.
