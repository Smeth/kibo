# KIBO — Identité visuelle V1

## Positionnement
Premium, minimaliste et accessible. Interface claire et lumineuse. Signature : **« Le commerce, simplement. »**

## Logo
Wordmark typographique « KIBO », sans symbole intégré. Une icône d'application pourra utiliser un K dérivé du wordmark.

## Typographie
Manrope : ExtraBold 800 pour logo et grands titres ; SemiBold 600 pour titres de sections ; Regular 400 pour textes courants.

## Palette
| Rôle | Couleur |
|---|---|
| Primary Emerald | #087F5B |
| Primary Dark | #075B45 |
| Accent | #12A879 |
| Background | #F7F9F7 |
| Surface | #FFFFFF |
| Text Primary | #17211D |
| Text Secondary | #66736C |
| Border | #E5ECE7 |
| Success | #10B981 |
| Warning | #F59E0B |
| Error | #EF4444 |
| Info | #3B82F6 |

## Dimensions
- Espacements multiples de 4.
- Marge horizontale écran : 16 px.
- Rayon cartes : 16 px.
- Rayon boutons : 12 px.
- Hauteur cible boutons : 52 px.
- Champs : 52 à 56 px.
- Icônes : 24 px.

## Principes UI
Photos d'annonces dominantes ; espaces généreux ; hiérarchie claire ; ombres discrètes ; séparateurs subtils ; icônes cohérentes (Lucide ou équivalent). Prévoir les états chargement, vide, erreur et succès. Clair et sombre disponibles ; choix du téléphone par défaut, réglage local « Appareil / Clair / Sombre ».

## Déclinaison sombre — demande utilisateur du 2026-11-01

La palette claire ci-dessus est conservée. Les surfaces sombres sont des neutres teintés de vert ; l’accent est éclairci pour rester lisible. Rôles centralisés dans `KiboTheme.dark`, composants reliés au `ColorScheme`.

| Rôle sombre | Couleur |
|---|---|
| Fond | #101A16 |
| Surface | #18251F |
| Texte principal | #E7F0EB |
| Texte secondaire | #B0C0B6 |
| Action/prix | #6DDCB2 |
| Texte sur action | #003827 |
| Conteneur principal | #173F30 |
| Texte sur conteneur | #A8F2CF |
| Bordure | #3A4E43 |
| Erreur | #FFB4AB |

Le choix est mémorisé sur l’appareil, séparément des sessions et comptes. Aucun réglage Android global n’est modifié. Les références d’écrans se trouvent dans [`maquette/`](../maquette/README.md).
