# Connexion Google — 2026-11-02

Finition UI du 2026-11-02 : logo G officiel embarqué depuis Google, proportions/couleurs conservées et bouton sur fond blanc en clair/sombre. Provenance et empreinte dans `assets/branding/README.md`. Aucun chargement réseau pour afficher ce logo.

## Implémentation locale

« Continuer avec Google » est disponible dans les formulaires Connexion et Créer un compte, y compris le formulaire intégré au profil visiteur. Aucun champ email/mot de passe n’est requis pour cette action. La connexion email existante est conservée.

Le repository appelle `signInWithOAuth(OAuthProvider.google)` avec navigateur externe, choix du compte (`prompt=select_account`) et retour exact `com.kibo.kibo://auth/confirm`. Le SDK existant utilise PKCE et le stockage chiffré du vérificateur/de la session. Aucun secret OAuth ni nouveau package dans Flutter. Aucun INSERT/UPSERT de profil ajouté : le trigger serveur existant reste responsable du profil.

Ouvrir le navigateur ne crée pas une session. Le flux du SDK confirme la connexion, charge le profil et ferme le formulaire. Pendant l’ouverture, les soumissions concurrentes sont désactivées. Si l’utilisateur revient sans terminer, les boutons restent réutilisables ; aucun faux succès ni attente bloquante permanente. Les mots de passe éventuellement saisis sont effacés avant l’ouverture Google. Les erreurs sont affichées en français sans contenu brut de lien ou exception.

## État distant réellement vérifié

Lecture seule de `/auth/v1/settings` avec la configuration publique locale existante, le 2026-11-02 : `external.google=true`. Aucune modification distante effectuée. Ce contrôle ne valide ni le client OAuth Google, ni le consentement, ni la liste des retours autorisés, ni la création effective d’un compte.

## Configuration à vérifier si le parcours échoue

1. Google Cloud : écran de consentement KIBO, audience et utilisateurs de test si l’application est en mode test ; client OAuth de type application Web pour ce parcours navigateur.
2. Renseigner comme URI de redirection Google le callback HTTPS **affiché dans le fournisseur Google du tableau de bord Supabase**, normalement `https://<projet>.supabase.co/auth/v1/callback`. Il est distinct du retour natif KIBO.
3. Supabase → Authentication → Providers → Google : client ID et secret correspondant. Le secret reste exclusivement dans le tableau de bord serveur ; ne pas le saisir dans le chat, Flutter ou Git.
4. Supabase → Authentication → URL Configuration → Redirect URLs : autoriser exactement `com.kibo.kibo://auth/confirm`, sans wildcard. Le manifeste Android et le filtre PKCE existent déjà.

Ne modifier ces réglages qu’avec autorisation explicite. Ne pas créer de compte distant de recette automatiquement. Aucun changement RLS, table ou Storage n’est nécessaire à ce parcours client.

## Recette humaine à effectuer

- Depuis Profil déconnecté, tester Google depuis Connexion puis Créer un compte ; vérifier choix du compte, retour KIBO et profil attendu.
- Fermer le navigateur sans accepter : retour au formulaire utilisable, email toujours disponible.
- Refuser le consentement : message sans détail sensible, aucune session créée.
- Tester le retour à chaud puis après arrêt de KIBO, sans effacer ses données.
- Vérifier session persistante après relance, puis déconnexion. Tester un compte email déjà existant avec la même adresse Google ; vérifier le compte et les données retrouvés, sans fusion manuelle côté Flutter.
- Tester un profil nouveau via le trigger serveur : ville par défaut et absence d’erreur liée à des métadonnées email/mot de passe attendues à tort.

Le retour iOS n’est pas configuré/validé dans ce lot ; priorité Android. La configuration du consentement Google et les erreurs affichées dans le navigateur exigent une recette réelle. Les tests simulés ne la remplacent pas.

Références : [Google avec Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google), [API Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth).
