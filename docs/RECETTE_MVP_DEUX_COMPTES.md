# Recette MVP à deux comptes — 2026-11-01

Document opérationnel préparé ; **aucune étape ci-dessous n’est déclarée exécutée**. Il complète les anciens plans photos et reprend les contrats désormais déployés, dont `20261101092315 kibo_engagement_workflows`. Les limitations historiques « serveur non déployé » des premiers plans ne décrivent pas l’état actuel.

## Préconditions et accord

Identifier l’environnement et deux comptes de test préexistants A (vendeur) et B (acheteur). Saisir les accès directement sur les appareils, jamais dans le chat, les rapports ou les commandes. L’accord de compiler/installer n’autorise pas à créer des annonces, messages, favoris synchronisés, contacts ou demandes dans le projet réel. Faire approuver la liste des écritures ci-dessous et leurs comptes avant la recette. Aucun compte administrateur créé pour contourner ce prérequis ; les scénarios opérateur restent bloqués sans opérateur déjà autorisé.

Deux appareils connectés sont recommandés pour la réception simultanée. Un seul appareil permet les changements A/B et la persistance, mais ne valide pas à lui seul le Realtime sur le second appareil. Préparer seulement des photos synthétiques sans personnes, GPS ou galerie privée. Réseau de test contrôlé ; pas de suppression de données de l’application ni de désinstallation pour provoquer une panne. Les éventuels brouillons/favoris existants doivent être préservés : utiliser un compte/appareil de test approuvé.

Pour chaque ligne : renseigner NON EXÉCUTÉ / BLOQUÉ / RÉUSSI / ÉCHEC, heure Africa/Lagos, version/identifiant du build, appareil(s), alias A/B, résultat attendu et réellement observé. Joindre uniquement captures expurgées et identifiants de données fictives autorisées ; jamais de JWT, lien PKCE, URL signée, mot de passe ou coordonnées personnelles. Un état de l’interface seul ne prouve pas la RLS.

## Parcours ordonné

| ID | Actions et résultat attendu | Écriture à autoriser | État initial |
|---|---|---|---|
| R01 | Sans compte : catalogue, recherche, filtres, retour détail et défilement conservés. | Aucune | NON EXÉCUTÉ |
| R02 | Favori visiteur ajouté/retraité ; redémarrage sans effacer les données ; favori encore présent si l’annonce est disponible. | Stockage local de test | NON EXÉCUTÉ |
| R03 | Connexion B : refuser le transfert puis le réouvrir ; accepter explicitement ; aucun transfert vers A après changement de compte. | Auth et favoris B | NON EXÉCUTÉ |
| R04 | A prépare un brouillon avec trois photos synthétiques, change leur ordre, quitte puis relance. Texte, photos et principale restaurés sous A seulement. | Brouillon local A | NON EXÉCUTÉ |
| R05 | A publie une annonce fictive une seule fois. B/visiteur voient sa fiche et les trois photos ; validation XAF/champs/limites. | Annonce et photos A | NON EXÉCUTÉ |
| R06 | Interrompre le réseau pendant les photos puis le rétablir. Relancer et terminer ; même identifiant d’annonce, aucune seconde publication. Ne pas interrompre une annonce réelle. | Reprise R05 | NON EXÉCUTÉ |
| R07 | Coordonnées A désactivées par défaut ; activer volontairement les canaux synthétiques approuvés. B connecté voit les boutons, visiteur ne récupère pas les coordonnées. | Contacts A ; aucun appel/message externe envoyé | NON EXÉCUTÉ |
| R08 | B démarre un chat depuis l’annonce, envoie un texte fictif. A le reçoit sans ouvrir une autre conversation ; vérifier l’heure, le contenu et le compteur. | Conversation/message B | NON EXÉCUTÉ |
| R09 | A ouvre la notification : bonne conversation ; lecture du message confirmée ; badge global actualisé au retour. L’absence de push Android n’est pas un échec de ce parcours. | Lecture message/notification A | NON EXÉCUTÉ |
| R10 | A coupe les notifications de messages. B envoie : message visible et compteur non lu accru ; aucune nouvelle notification new_message. Anciennes notifications conservées. | Préférences A et message B | NON EXÉCUTÉ |
| R11 | A coupe les notifications commentaires ; B commente puis répond. Commentaires visibles, préférence appliquée aux futurs avis ; réactiver et vérifier un nouvel avis. | Préférences/commentaires fictifs | NON EXÉCUTÉ |
| R12 | A bloque B dans le chat ; B ne peut plus envoyer. Historique conservé. Compte et données → Interlocuteurs bloqués : B une seule fois, annuler puis confirmer le déblocage. | Blocage/déblocage A | NON EXÉCUTÉ |
| R13 | Blocage réciproque : A débloque B mais B maintient son blocage ; A ne peut pas envoyer. Retirer ensuite le blocage B explicitement. | Blocages A/B | NON EXÉCUTÉ |
| R14 | Pendant une lecture/envoi suspendu, changer A→B→A. Aucun nom, message ou décision tardive de l’ancienne session n’est appliqué au nouvel écran. | Sessions approuvées ; données fictives uniquement | NON EXÉCUTÉ |
| R15 | Arrière-plan puis reprise : ressources suspendues, liste réactualisée, réception retrouvée. Au réseau lent, aucune duplication d’un même message après reprise manuelle. | Message fictif et son retry | NON EXÉCUTÉ |
| R16 | Demande de compte A confirmée par SUPPRIMER ; suivi et annulation pending. Aucun compte réellement effacé. | Demande fictive A et annulation | NON EXÉCUTÉ |
| R17 | Avec opérateur existant : besoins de précisions, réponse A, note visible et nouvelle file ; deux vues concurrentes, la seconde décision obsolète est refusée. | Demande/notes/notifications système | BLOQUÉ sans opérateur |
| R18 | Préférences désactivées : notification système de R17 toujours reçue ; clic ouvre le suivi personnel. | Lecture notification A | BLOQUÉ par R17 |
| R19 | A vend/archive l’annonce fictive ; elle disparaît des résultats publics, historique propriétaire conservé, ancien favori B sans accès au contenu masqué. | Statuts de l’annonce R05 | NON EXÉCUTÉ |
| R20 | 320/360 px, texte agrandi, clavier et lecteur d’écran : actions et erreurs accessibles, aucune fausse confirmation, bouton retour utilisable hors écriture. | Aucune donnée supplémentaire | NON EXÉCUTÉ |

La couverture SQL locale de 21 conversations ne valide pas une pagination réelle avec 21 conversations autorisées : ne pas créer vingt comptes/annonces sans accord spécifique. Les signalements/modération utilisent les plans existants et un jeu fictif approuvé séparément.

## Clôture

Inventorier les seules données fictives autorisées, leurs identifiants et le responsable de nettoyage. Aucun nettoyage automatique et aucune suppression de compte via la demande actuelle. Restaurer uniquement les préférences/blocages de test dont l’état initial a été noté, avec accord. Reporter les échecs et scénarios bloqués ; ne pas transformer un build ou des tests simulés réussis en recette humaine réussie.
