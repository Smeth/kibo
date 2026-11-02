# Notifications Android — préparation du 2 novembre 2026

Le propriétaire ne dispose pas encore de projet Firebase. **Client et serveur préparés ; aucun envoi actif, aucune réception réelle validée.** L’OTP téléphone reste désactivé et hors de ce lot. Les notifications internes existantes continuent à fonctionner.

## Comportement préparé

SDK officiels firebase_core 5.1.0 et firebase_messaging 17.0.1, versions verrouillées. Profil → Notifications sur ce téléphone explique l’état actuel. Avec configuration autorisée : consentement Android explicite, enregistrement RPC privé du token, reprise après connexion et renouvellement, retrait à la déconnexion/désactivation. Le refus de permission ne bloque pas KIBO. Aucun token, texte de message ou secret n’est journalisé.

Contrat `supabase/proposals/push_notifications.sql` : tables privées avec RLS et aucun accès direct client, cinq appareils au maximum par compte, rattachement du token au compte connecté, file d’envoi issue des nouvelles notifications et donc de leurs préférences existantes. Pas de reprise des anciennes notifications. Lots de dix, baux de cinq minutes, cinq tentatives maximum, fenêtre d’envoi de 24 h ; anciennes métadonnées de file purgées après sept jours lors d’un passage du worker. Invalidations FCM UNREGISTERED retirées. La livraison est au moins une fois : un doublon reste possible après une réponse perdue ; le tag Android est l’identifiant de notification.

Fonction `kibo-send-push` : appel serveur uniquement, vérification JWT et clé de service attendue. Sans configuration et `KIBO_PUSH_ENABLED=true` côté serveur, elle refuse de traiter la file. Aucun cron d’envoi n’est créé. Le texte envoyé est générique (« Vous avez une nouvelle activité… »), sans texte privé de conversation. Le clic ouvre l’application ; consulter ensuite le centre de notifications KIBO. Le routage direct vers une conversation depuis une alerte n’est pas implémenté dans ce lot.

## Activation quand Firebase existe

1. Créer/configurer le projet Firebase de l’exploitant et l’application Android `com.kibo.kibo`, activer Cloud Messaging HTTP v1. Aucun compte ou accord fournisseur créé par l’agent.
2. Sur le poste, copier l’exemple dans `config/firebase.local.json` (ignoré) et y placer uniquement les paramètres publics Android. Le compte de service Firebase ne va jamais dans Flutter ni dans ce fichier.
3. Dans les secrets de la fonction Supabase, saisir localement `FIREBASE_SERVICE_ACCOUNT_JSON`, puis `KIBO_PUSH_ENABLED=true`. Réserver le compte de service à l’envoi FCM, sans droits administrateur supplémentaires. Ne jamais communiquer ces valeurs dans le chat ou Git. Conserver les secrets Supabase existants.
4. Ajouter une invocation serveur sécurisée périodique de `kibo-send-push` avec la clé de service conservée dans Vault, jamais dans le SQL versionné ni dans un client. Contrôler ses coûts/quotas avant planification. Cette planification n’a pas été créée ici.
5. Compiler avec `scripts/Launch-KiboAndroid.ps1 -ProfileMode -EnableDiscoveryV2 -EnableMediaManagement -EnableAccountDeletion -EnablePush`. Ne pas activer cette option avec les valeurs d’exemple.
6. Recetter sur comptes et appareils autorisés : permission accordée/refusée, premier plan/arrière-plan/arrêt, préférence désactivée, déconnexion/changement de compte, renouvellement du token et reprise réseau. Le code testé avec transports simulés ne prouve pas la délivrabilité Firebase ni le comportement du TECNO en économie d’énergie.

Références : [réception Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [envoi HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api). Les signatures utilisées sont également vérifiées dans le SDK installé.
