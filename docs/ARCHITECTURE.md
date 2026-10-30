# Architecture cible — KIBO

## Vue d'ensemble
- Client mobile : Flutter / Dart.
- Backend : Supabase.
- Base : PostgreSQL.
- Authentification : Supabase Auth.
- Fichiers : Supabase Storage.
- Temps réel : Supabase Realtime.
- Autorisation : Row Level Security (RLS).
- Administration : application web séparée, à concevoir.

## Organisation Flutter indicative
Adapter à la structure réellement générée et éviter la complexité prématurée.

```text
lib/
  core/
  shared/
  data/
  domain/
  features/
    auth/
    home/
    search/
    listings/
    favorites/
    profile/
    chat/
    comments/
    notifications/
    moderation/
```

## Domaines de données à modéliser
Profils ; catégories ; annonces ; images d'annonces ; favoris ; conversations ; participants ; messages ; commentaires et réponses ; signalements ; notifications ; journaux d'audit.

Le schéma SQL définitif doit être conçu sous forme de migrations versionnées, relues et testées. Un ancien script SQL de travail ne doit pas être considéré comme prêt pour la production.

## Sécurité
- Activer RLS sur toutes les tables accessibles via l'API.
- Définir des grants minimaux et des politiques par opération.
- Séparer données de profil publiques et privées.
- Restreindre les fonctions SECURITY DEFINER et leurs privilèges EXECUTE.
- Contrôler propriétaire et statut des annonces lors des mises à jour.
- Éviter d'exposer publiquement les photos de brouillons ou annonces masquées.
- Valider nombre, type MIME, taille et chemin des images ; maximum 8 photos par annonce.
- Protéger les actions administrateur côté serveur, jamais par une simple valeur client.
- Tester les accès autorisés et interdits des politiques RLS.

## Configuration
Les URL et clés publiques nécessaires au client peuvent être configurées par environnement. Les secrets privilégiés restent côté serveur. Ne jamais commiter de secrets réels.