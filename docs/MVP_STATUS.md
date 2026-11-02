# État consolidé — 2026-11-02

## Actualisation : mise en place des quatre volets

Recherche française corrigée et vérifiée en visiteur ; contrats galerie et suppression déployés, expiration 15 jours active, sans suppression réelle de recette. Signalement des messages/profils, badge serveur du compte officiel, contrôle de rôle admin et session MFA renforcée après inscription TOTP déployés. Aide/confidentialité publiques : https://kibo-assistance-2026.stonytern8.chatgpt.site. Signature locale préparée et bundle Android sans assets fictifs construit ; aucune publication Play Store. Serveur/client push préparés mais désactivés sans Firebase. **OTP SMS exclu et désactivé.** Catalogue de recette maintenu visible sur instruction explicite. Voir [preuves et limites actuelles](ROLLOUT_MVP_20261102.md) ; les limites et compteurs des sections suivantes sont historiques.

Restent des étapes qui exigent une participation/ressource extérieure : TOTP à enregistrer par le propriétaire, Firebase à créer/configurer, sauvegarde externe de signature et canal pilote, recette Google/deux appareils/réseau dégradé et suppression réelle d’un compte dédié autorisé. Le pilote n’est pas déclaré prêt à une diffusion publique large.

---

Le MVP comprend catalogue, publication, favoris visiteurs/compte, profil vendeur, contacts, chat, commentaires, notifications internes et administration mobile. Le dernier audit a validé 443 tests standard ; ses preuves serveur datent du 2 novembre et ne sont pas rejouées lors de la consolidation Git. Voir [audit](AUDIT_ETAT_ACTUEL_2026_11_02.md).

Consolidation validée localement : sources Flutter, assets, tests, scripts, documentation, migrations historiques et propositions sont conservés ensemble. Les configurations locales et clés de signature restent ignorées. CI étendue aux chemins assets/tool/scripts/supabase, aux variantes photos et aux fixtures Node du worker. **447 tests standard + 447 avec photos + 19 tests Node réussis**, analyse stricte et format conformes. Aucun déploiement automatique.

Limites actuelles : préfixes français tél/télé défectueux dans la recherche actuelle ; gestion complète des photos et suppression effective de compte encore à valider/activer ; Google à recetter, téléphone OTP désactivé ; push et badge Équipe KIBO absents. Signature release et recette à deux appareils restent à faire. Les propositions SQL et fonctions préparées ne prouvent pas leur déploiement. Le catalogue partagé contient des fixtures : ne pas les effacer sans autorisation.

Prochain lot : recherche française, cycle des photos publiées, recette à deux appareils/réseau dégradé. Toute migration ou écriture distante exige son autorisation propre. [Reprise](NEXT_TASK.md).

---

Les sections ci-dessous sont les preuves historiques des lots ; leurs compteurs et limitations décrivent leur date.

# État MVP — 2026-11-01

Cette grille distingue implémentation locale, serveur et recette appareil. Aucun « terminé » global ne doit être déduit d'une suite de tests simulés.

État courant après lots autonomes 2–8 : **293 tests standard + 293 photos réussis**, analyse stricte/format/diff conformes ; dernière version installée/lancée sur TECNO sans effacement. [Récapitulatif, migrations et limites](MVP_AUTONOMOUS_RECAP.md). Les comptes rendus chiffrés des lignes historiques ci-dessous restent leurs preuves de lot initiales.

| Parcours | Application locale | Serveur | Appareil |
|---|---|---|---|
| Catalogue, recherche, photos | Implémenté et testé | Réparé/déployé précédemment | Retour utilisateur global positif sur TECNO |
| Auth email et profil propre | Implémenté/testé | Existant | Recettes historiques, confirmation email avec limites documentées |
| Publication directe et favoris compte | Implémenté/testé | Contrats présents | Retour global, détails A/B encore à distinguer |
| Favoris sans compte et transfert | Implémenté/testé | Réutilise lecture/INSERT existants | À tester physiquement |
| Mes annonces, édition, vente, archivage | Implémenté/testé | Deux phases déployées le 2026-11-01 | À tester physiquement, aucune annonce réelle changée par l'agent |
| Commentaires et réponses | Implémenté/testé, 17 nouveaux tests, suites 208+208 réussies | Table/RLS/triggers existants audités ; lecture anon LIMIT 0 réussie | À tester ; aucune création réelle |
| Profil public vendeur et contact WhatsApp/appel | Implémenté/testé, préférences volontaires privées | Migration contacts 20261101044111 appliquée après accord ; RLS/ACL contrôlées | À tester ; aucun contact réel effectué |
| Chat Realtime | Liste, messages texte persistants, pagination et actualisation implémentés/testés ; suites 247+247 | Contrats/RLS audités ; publication activée avec accord, migration 20261101050420 | Compilé/installé/lancé sur TECNO, processus actif ; échange entre deux comptes à recetter |
| Notifications et signalements | Centre personnel, compteur, lecture et formulaires implémentés/testés ; suites 272+272 | Contrat 20261101051653 appliqué avec accord ; notifications pour futurs messages/commentaires | Lot installé/lancé sur TECNO ; recette réelle à effectuer ; push OS non implémenté |
| Modération et audit | File mobile admin, décisions motivées et journal implémentés/testés | Fonctions contrôlées, journal RLS et atomicité testée localement | Aucun rôle créé ni contenu réel modéré ; administration web séparée à concevoir |
| Recherche et brouillon améliorés | Filtres actifs/recherche/scroll conservés, brouillon texte isolé, aperçu et choix de principale | Reprise de publication par UUID sur contrats existants | Installé/lancé ; photos du brouillon temporaires, recette humaine restante |
| Chat enrichi et blocage | Dernier message/date/non lus, lecture, position et reprise d'envoi ; blocage/déblocage | 20261101052757/53807/54728 appliqués ; RLS et anti-abus contrôlés | Installé/lancé ; échange réel à deux comptes restant |
| Récupération et données du compte | PKCE email, changement de mot de passe, information et demande de suppression annulable | Auth existant ; demande RLS, aucun effacement automatique | Réception/lien à froid et traitement opérateur à valider |

Le lot de privilèges ciblé est appliqué aux tables actuelles et aux defaults postgres. MAINTAIN retiré d'anon/authenticated sur neuf tables et des defaults postgres/public après accord explicite, migration 20261101090123 ; autres privilèges/RLS inchangés. Defaults supabase_admin et Storage restent hors de ce delta. [Contrôle réel](CLIENT_MAINTAIN_DEPLOYED.md). Pas de contournement de RLS pour avancer.

Priorité : recette des parcours du MVP et préparation d'un pilote. Conserver les contrôles ciblés et les autorisations des opérations risquant les données. Lancement sur téléphone autorisé après validation des lots ; aucune publication ni commit/push automatique.
