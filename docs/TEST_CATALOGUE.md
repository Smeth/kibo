# Jeu de données de recette — 2026-11-02

## Second lot réellement ajouté

Après choix explicite de `frposx@gmail.com` : **1 080 annonces supplémentaires, 1 080 JPEG et 4 320 commentaires/réponses** importés et vérifiés, lot `kibo-stress-20261102-v1`. 120 annonces dans chaque catégorie ; questions sous smethturc, réponses sous frposx. Ancien lot 108/108/432 conservé, soit 1 188 annonces et 4 752 commentaires au total. Sources visuelles réutilisées, charge de catalogue distincte d’une mesure de concurrence/FPS. [Incident réseau, reprise vérifiée, audit et limites](UI_REVIEW_2_ADMIN_STRESS.md).

## Autorisation et périmètre

Demande utilisateur : au moins 100 annonces avec au moins une image, et des commentaires. Destination choisie explicitement : base Supabase connectée avec comptes dédiés ; deux comptes existants ont été désignés. Le compte effectivement choisi pour la session vendeur possède les annonces et réponses ; l’autre est auteur des questions. Aucun rôle administrateur attribué. Après deux contrôles sans écriture, une connexion locale au second compte a été demandée ; les cibles courantes sont dans la configuration ignorée.

Le lot `kibo-demo-20261102-v1` contient **108 annonces, 108 fichiers image et 432 commentaires/réponses** : neuf catégories × douze annonces, deux questions et deux réponses par annonce. Images sources DummyJSON destinées aux prototypes ; 95 contenus visuels distincts. Les logements/services/formations utilisent des illustrations d’équipement, pas des photos de logements réels. Chaque annonce est explicitement fictive. Aucun contact, message privé, signalement ou sanction n’est ajouté par ce générateur.

Les commentaires peuvent déclencher les notifications normales vers les deux comptes de test, selon leurs préférences existantes. Ces préférences ne sont pas modifiées. Le lot reste visible dans le catalogue partagé : les titres portent `[TEST …]` et les descriptions indiquent qu’aucune vente réelle n’est proposée.

## Fichiers et préparation

`assets/test_catalogue/catalogue.json` contient les textes, identifiants stables, liens de parenté des commentaires, chemins des 108 fichiers image, URL sources et empreintes. `scripts/prepare_test_catalogue.py` prépare ces fichiers sans appeler Supabase ; le téléchargement en parallèle est borné à six connexions. L’hébergeur refusait l’agent Python par défaut ; la reprise avec un en-tête navigateur a réussi. Aucun fichier préexistant écrasé par la préparation.

Les cibles réelles sont uniquement dans `config/seed.local.json`, ignoré par Git. Ce fichier contient les identifiants des deux comptes et du projet, aucun mot de passe/jeton. La configuration publique locale existante reste utilisée sans affichage de ses valeurs. Les deux comptes ont été vérifiés existants, confirmés, avec profil et sans rôle admin.

## Annonces et photos

Lanceur ponctuel : `tool/import_test_catalogue.dart`, installé sur le même package Android pour réutiliser la session sécurisée existante, sans extraire les jetons. Vérifie le projet exact puis l’identité du vendeur ; si un autre compte est connecté, aucune écriture. Après les contrôles initiaux sans session attendue, le lanceur a été corrigé pour écouter les événements de restauration, au lieu de conclure immédiatement. Il propose également le formulaire natif de connexion ; un changement de compte est effectué uniquement via ce bouton utilisateur. L’import commence uniquement dans la session du vendeur configuré. Aucun rôle ou secret supplémentaire.

`TestCatalogueImporter` décode et compresse toutes les images avant la première écriture. Les annonces passent par `SupabaseListingRepository.createOnce` avec identifiants stables ; le conflit de contenu ou de propriétaire est refusé. Les photos passent par les réservations et l’Edge Function existantes, sous les droits du vendeur, avec validation JPEG/digest/propriétaire. Une relance reprend les mêmes identifiants et ne crée pas de nouvelles annonces ; elle peut retéléverser les mêmes photos. Le changement de session arrête la suite. Un échec partiel peut laisser une annonce sans photo jusqu’à la reprise ; aucun nettoyage destructif automatique.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Import-TestCatalogueAndroid.ps1
```

Ce lanceur est volontairement distinct de l’application normale. Réinstaller/relancer ensuite `scripts/Launch-KiboAndroid.ps1` sans effacement. L’installation du lanceur ne prouve pas la fin de son import : contrôler les lignes, réservations et objets Storage du lot.

## Commentaires et contrôles distants

Les commentaires sont préparés séparément pour insertion opérateur strictement bornée aux identifiants du lot et aux deux comptes désignés. Parents avant réponses, un seul niveau, validation du propriétaire et de la publication de chaque annonce, conflit d’ID refusé sauf contenu identique. Transaction unique, aucun UPDATE/DELETE des données existantes, aucune désactivation des triggers ou de RLS. Les notifications automatiques restent actives. Ce chargement opérateur ne constitue pas une recette RLS du formulaire de commentaires sous le second compte.

Les contrôles finaux doivent confirmer : 108 annonces publiées du vendeur désigné ; une photo par annonce avec objet JPEG réel non vide dans le bucket privé ; 432 commentaires dont 216 racines et 216 réponses ; uniquement les deux auteurs attendus ; rôles inchangés et RLS active. Le journal de PROGRESS distingue préparation locale, lancement et import réellement vérifié.

La suppression éventuelle du lot nécessitera une demande explicite : utiliser les identifiants exacts, contrôler la présence de contributions ultérieures et les objets Storage ; ne jamais supprimer par un simple filtre de titre TEST. Aucun script de suppression globale n’est fourni.

## État de validation

**Import réellement achevé le 2026-11-02** : 108 annonces publiées, 108 objets JPEG non vides et 432 commentaires (216 racines / 216 réponses), 12 annonces dans chacune des neuf catégories. Vendeur : second compte désigné ; questions : premier compte, réponses : vendeur. Les 432 notifications automatiques de commentaire ont été constatées ; aucun compte tiers destinataire ajouté par le lot. Les deux comptes sont restés non administrateurs, RLS active sur les cinq tables contrôlées. Une photo du lot a aussi été téléchargée en visiteur avec la seule configuration publique : HTTP 200, JPEG inspecté visuellement. Aucun rôle, schéma, politique ou bucket modifié.

Annonces/photos : réellement publiées par le SDK sous la session du vendeur via les mécanismes existants. Commentaires : insertion opérateur transactionnelle, bornée au manifeste et aux deux comptes, réellement exécutée après confirmation des 108 photos. Ce second point ne remplace pas une recette RLS du formulaire de commentaires sous le compte acheteur.

Sept tests dédiés : structure/liens/marquage des 108/432 éléments, empreinte et JPEG de chaque image, autre compte sans effet, dernière image invalide sans écriture, changement de session avant upload, reprise des identifiants et refus d’un autre lot. Ils utilisent des gateways simulées ; ne pas les présenter comme un import distant réalisé. Analyse stricte et suites globales consignées dans PROGRESS.
