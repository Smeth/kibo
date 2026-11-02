# Connexion par téléphone — préparation du 2026-11-02

## Code prêt, service SMS non activé

Le parcours Flutter est implémenté pour **Supabase Auth avec OTP SMS** : numéro congolais, demande de code, vérification, renvoi après 60 secondes et correction du numéro. La connexion et la création de compte utilisent le même parcours sans mot de passe. Le serveur crée le compte si nécessaire ; seule sa vérification OTP ouvre une session. Aucun code universel ou contournement de vérification.

Par défaut, `KIBO_PHONE_AUTH_ENABLED=false` : le bouton indique « Téléphone · bientôt disponible » et ne peut pas envoyer de SMS. Le repository refuse aussi les appels d’envoi/vérification lorsque cette option est désactivée. Aucun fournisseur activé, aucun SMS envoyé et aucun compte distant créé pendant ce lot.

Formats acceptés : neuf chiffres nationaux (ex. fictif `06 123 45 67`), `+242` suivi de neuf chiffres, ou `00242` suivi de neuf chiffres. Normalisation en E.164 `+242…`. Les autres indicatifs, lettres et extensions sont refusés. Le formulaire attend six chiffres pour le code : conserver cette longueur dans Supabase ou adapter la validation lors d’un changement de contrat.

Le code est vidé après tentative/correction/connexion et n’est pas persisté par KIBO. Le délai est appliqué aussi après un échec d’envoi et conservé après correction du numéro. Il est local au formulaire : **les limites serveur sont indispensables** contre les abus, même après fermeture/réouverture de l’application.

La session et son profil réutilisent le SDK et le stockage sécurisé existants. Le profil personnel affiche le numéro lorsque l’email est absent ou vide. Le numéro Auth n’est ni copié vers les contacts vendeurs ni rendu public automatiquement. Aucune liaison/fusion automatique client d’un compte téléphone avec un compte Google/email existant : ce sont potentiellement deux comptes distincts.

## Contrôle distant en lecture seule

Le 2026-11-02 : colonnes de `public.profiles` et trigger INSERT de `auth.users` inspectés, sans lire de ligne métier. `handle_new_user` insère l’ID et le nom facultatif depuis les métadonnées ; il ne dépend pas d’un email. Nom nullable, ville par défaut Brazzaville et type par défaut individual constatés. Cela indique une compatibilité du contrat avec un compte téléphone ; la création réelle reste à tester après activation. Aucun SQL/migration/réglage distant appliqué.

## Activation après choix du fournisseur

1. Choisir un prestataire pris en charge par Supabase Auth et capable de livrer réellement les SMS au Congo-Brazzaville (+242). Un fournisseur non compatible directement nécessite un **Send SMS Hook** côté serveur à développer/valider séparément : ce lot ne contient pas cet adaptateur. Il ne suffit donc pas d’acheter une offre OTP quelconque.
2. Avec autorisation explicite, configurer le fournisseur dans **Supabase → Authentication → Providers → Phone**, activer Phone et les nouvelles inscriptions, conserver six chiffres, définir expiration et limites d’envoi/vérification. Les identifiants du fournisseur restent uniquement côté serveur, jamais dans Flutter, Git ou le chat. Ne pas activer de numéro/code de test fixe en production.
3. Vérifier les limitations géographiques du fournisseur, le crédit et l’émetteur autorisé, puis les protections contre les abus. Si CAPTCHA est exigé par le projet, son challenge n’est pas intégré à ce formulaire : il faut le brancher avant activation ; ne pas désactiver une protection existante pour contourner un refus.
4. Compiler avec `--dart-define=KIBO_PHONE_AUTH_ENABLED=true`. Pour le téléphone connecté, le lanceur local propose désormais :

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Launch-KiboAndroid.ps1 -EnablePhoneAuth
```

Sans `-EnablePhoneAuth`, le lanceur compile explicitement avec l’option à false. Un hot reload ne change pas une constante de compilation. Pour un autre pipeline, ajouter le même dart-define aux paramètres existants. Aucun changement de code Flutter n’est nécessaire pour un prestataire SMS directement compatible une fois ces réglages validés.

5. Autoriser puis exécuter une recette sur numéros contrôlés : première inscription et profil, reconnexion, code erroné/expiré/rejoué, renvoi, numéro corrigé, SMS non livré, limites et hors réseau, session après fermeture/relance et déconnexion. Vérifier aussi les interactions métier d’un profil sans email. Les coûts et la livraison réelle ne sont pas validés par les mocks.

Le canal WhatsApp, les autres pays, le changement de numéro et la liaison entre comptes sont hors périmètre de ce lot.

## Validation locale

Tests HTTP simulés : `/otp` reçoit numéro normalisé, canal SMS et création autorisée ; `/verify` reçoit le code et `type=sms`, puis ouvre une session sans email. Aucun appel HTTP si la fonction est désactivée ou les saisies invalides. Contrôleur/widgets : doublons, délai, échecs, corrections, non-confusion entre envoi et connexion, fermeture des deux routes sur vraie notification de session simulée, petit écran/clavier/texte agrandi.

Références : [Phone sign-in](https://supabase.com/docs/guides/auth/phone-login), [envoi OTP Dart](https://supabase.com/docs/reference/dart/auth-signinwithotp), [vérification Dart](https://supabase.com/docs/reference/dart/auth-verifyotp), [Send SMS Hook](https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook).
