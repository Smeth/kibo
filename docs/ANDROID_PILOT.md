# Préparation du pilote Android — 2026-11-01

**Actualisation du 2 novembre :** version 1.0.0+2, clé locale RSA 3072 créée et certificat vérifié, bundle pilote signé construit sans assets de catalogue fictif. Scripts `Prepare-AndroidSigning.ps1` et `Build-AndroidPilot.ps1`. La clé et le mot de passe ne sont pas versionnés ; la copie DPAPI n’est pas une sauvegarde externe. Aucun upload Play Store, ni remplacement de la signature du TECNO. [État du lot et limites restantes](ROLLOUT_MVP_20261102.md). Les paragraphes suivants conservent l’historique de préparation.

Application `com.kibo.kibo` conservée pour permettre la mise à jour du TECNO sans effacer ses données. Libellé Android : KIBO. Aucune publication Play Store ni distribution à des tiers autorisée par ce lot.

## Signature

Le repli release → clé debug du template a été supprimé. Les builds debug de recette restent indépendants de la signature de diffusion. Le graphe Gradle refuse une tâche release, y compris via une tâche agrégée, si le fichier local, les quatre paramètres ou le keystore sont absents. Un fichier présent ne prouve pas que le certificat est valide : aucune signature release réelle n’est déclarée testée.

Configurer uniquement sur le poste de l’opérateur `android/key.properties` ignoré par Git : storeFile, storePassword, keyAlias, keyPassword. Le chemin storeFile relatif est résolu depuis android/. Le keystore doit être conservé dans un emplacement approuvé avec sauvegarde sécurisée ; les motifs *.jks et *.keystore sont déjà ignorés. Ne jamais transmettre ces valeurs dans le chat, les scripts, les commits ou les journaux. Aucun keystore, mot de passe ou secret n’est généré par l’agent.

Conserver la même identité de signature pour mettre à jour une installation release existante. Une installation debug du TECNO ne peut pas être remplacée arbitrairement par une autre signature ; ne pas désinstaller ou effacer ses données pour contourner un échec. Choisir un appareil/périmètre de pilote approprié avec le propriétaire avant de changer de signature. [Guide Flutter officiel](https://docs.flutter.dev/deployment/android#sign-the-app).

## Relance de recette autorisée

Après validations Flutter et une fois le téléphone connecté/débogage autorisé :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Launch-KiboAndroid.ps1
```

Si plusieurs appareils sont présents, indiquer -DeviceId avec un appareil effectivement autorisé. Le script refuse de lancer le build si le téléphone n’est pas disponible. Il réutilise les deux JSON de configuration existants sans afficher leurs valeurs, active les photos, compile/installe/lance en debug sans désinstallation ni effacement. Il confirme le processus et indique si KIBO est au premier plan ; cela ne vaut pas recette humaine à deux comptes. Journal local ignoré `.dart_tool/kibo-android-launch.log`, à expurger avant partage.

## Conditions avant diffusion à des testeurs

- Contrôles format/analyse/tests et installation réellement effectués, avec version et empreinte de l’artefact retenu. Les journaux précédents ne valident pas automatiquement un nouveau binaire.
- Signature de diffusion, propriétaire de la clé, sauvegarde et canal de distribution approuvés. Aucun build release sans ces éléments, aucune génération de clé improvisée.
- [Recette à deux comptes](RECETTE_MVP_DEUX_COMPTES.md) exécutée et résultats renseignés ; Realtime, PKCE, coordonnées et erreurs réseau observés réellement.
- Suppression de compte : [procédure préparée](ACCOUNT_DELETION_RUNBOOK.md), choix de conservation et moyen opérationnel de traitement validés. La file d’examen actuelle ne réalise pas cet effacement.
- Contact support KIBO, horaires/responsable, canal de signalement, traitement des incidents et page de confidentialité approuvés. Ne pas inventer d’adresse ou de numéro de support.
- Revue sur téléphone : taille de texte agrandie, lecteur d’écran, clavier, contraste/états, icône de lancement finale, connexion lente et autonomie ; captures seulement de KIBO sans données privées.
- Recette du changement de version et du retour à une version compatible sans perte des données locales. Aucun rollback automatique de schéma ou restauration de données effacées.

Ces conditions décrivent une préparation, pas une déclaration « prêt production ». Résultats exécutés du lot dans PROGRESS ; aucun commit/push ni publication automatique.

## Exécution constatée dans ce lot

321 tests standard et 321 avec photos, analyse stricte/format/diff conformes ; configuration Gradle debug en dry-run valide, release directe et agrégée sans signature refusées. Lancement debug réel TECNO réussi (21,5 s build, 8,5 s installation), processus 31758 et premier plan confirmés. SHA-256 de l’APK de recette : `10723ECAE483B723612D8FCCE1E8BC72647B1139C43BD54ABF42D9EFE96B51BF`. Aucun effacement ; contrôle visuel ultérieur non réalisé faute de focus confirmé, aucune capture hors KIBO. Cette installation ne remplace ni la recette à deux comptes ni la validation d’une signature release.
