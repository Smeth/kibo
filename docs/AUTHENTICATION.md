# Authentification — KIBO-005 / KIBO-006

Préparation téléphone du 2026-11-02 : [parcours OTP SMS, activation et limites](PHONE_AUTH.md). Désactivé par défaut en attendant le fournisseur ; comptes sans email pris en charge dans le profil personnel. Logo Google officiel embarqué dans le bouton, y compris hors ligne.

Extension Google du 2026-11-02 : bouton dans les deux formulaires, OAuth navigateur externe, callback PKCE et session chiffrée existants réutilisés. Fournisseur distant constaté activé en lecture seule ; recette réelle Google encore à effectuer. [Implémentation, configuration et limites](GOOGLE_AUTH.md). Les sections KIBO-005/006 ci-dessous décrivent le socle historique email.

Extension MVP courante : récupération email PKCE, réponse sans énumération de comptes, changement de mot de passe et événement de récupération lié au compte concerné. Les tests SDK utilisent un stockage PKCE fictif ; aucun email réel envoyé pour la recette. Réception et ouverture à froid restent à valider. [Rapport autonome](MVP_AUTONOMOUS_RECAP.md).

## Parcours et organisation

L’accueil reste public et conserve son contenu. L’avatar d’en-tête et la destination Profil ouvrent l’espace de compte. Depuis ce profil, un visiteur peut choisir Connexion ou Créer un compte ; un utilisateur connecté voit son email, les informations de profil disponibles et Se déconnecter. Le retour Accueil conserve la consultation publique.

`lib/features/auth/` contient le repository injectable, le contrôleur réactif, les validations, le formulaire et le profil. `KiboApp` conserve un seul démarrage Supabase et installe `AuthSession` après réussite. Le flux `onAuthStateChange` et la session courante alimentent `AuthScope` ; les erreurs de flux sont traitées sans exception brute. Les réponses de profil tardives sont ignorées après changement d’utilisateur ou déconnexion.

Inscription : email, mot de passe d’au moins huit caractères et confirmation identique. Connexion : email et mot de passe non vide, sans imposer rétroactivement cette longueur aux anciens comptes. Les règles supplémentaires du serveur restent applicables. Les mots de passe ne sont pas tronqués ni normalisés, restent masqués par défaut et sont effacés du formulaire après la tentative ; ils ne sont pas persistés par KIBO. Les formulaires peuvent défiler avec clavier et texte agrandi, désactivent les doubles soumissions et utilisent des messages français non issus directement des exceptions.

## Session persistante

`SupabaseConfig` est inchangé. `SupabaseService` réactive persistance et rafraîchissement automatique avec le SDK existant `supabase_flutter 2.18.3`. `SecureSessionStorage` remplace la persistance SharedPreferences par `flutter_secure_storage 11.2.0` ; les vérificateurs PKCE utilisent aussi un adaptateur chiffré. Les clés de stockage sont séparées par hôte de projet, sans valeur de configuration réelle dans les sources.

Cette dépendance est justifiée par la présence de jetons de session sensibles : pas de repli en clair. Sur Android, le plugin utilise les mécanismes cryptographiques de la plateforme ; les sauvegardes sont désactivées et les SharedPreferences exclues du transfert Android 12+. L’écriture et la suppression de session sont ordonnées pour éviter qu’une écriture déjà en cours ne rétablisse une session après sa suppression. La déconnexion utilise le scope local : elle ne déconnecte pas tous les autres appareils ; une erreur de révocation réseau reste signalée sans restaurer la session locale supprimée par le SDK.

Depuis KIBO-006, le retour de confirmation Android utilise `com.kibo.kibo://auth/confirm`, centralisé dans `core/config/auth_callback.dart` et envoyé comme `emailRedirectTo` à l’inscription. Le manifeste déclare exactement le schéma, l’hôte et le chemin ; `flutter_deeplinking_enabled=false` laisse le plugin `app_links` déjà utilisé par Supabase recevoir les liens, à chaud et au démarrage. Aucun nouveau plugin ni changement de version. Pas d’OAuth, OTP, récupération de mot de passe ou édition de profil ajoutés.

Le SDK conserve PKCE, le vérificateur chiffré `SecurePkceStorage`, la session chiffrée et `debug:false`. Sa détection est activée avec `detectSessionInUriPredicate` : seuls cette adresse et un code PKCE non vide, ou une erreur de confirmation, sont acceptés ; les autres adresses, ports, identifiants URI et jetons du flux implicite sont refusés. Les erreurs peuvent arriver en query ou fragment et sont présentées en français sans contenu brut du lien. Aucun échange manuel concurrent : le SDK échange le code puis émet la session ; le contrôleur recharge le profil. Un formulaire ouvert se ferme après connexion ; au démarrage à froid, ouvrir Profil depuis l’accueil pour vérifier le compte.

Un schéma personnalisé n’est pas un Android App Link HTTPS vérifié : une autre application peut tenter de le déclarer. PKCE exige le vérificateur local pour échanger le code ; il ne garantit pas que le système livre toujours le lien à KIBO. Une future URL HTTPS vérifiée nécessitera un domaine contrôlé et une association Android, hors périmètre. Ne jamais journaliser l’URI complète, le code, un lien email ou un jeton.

## Configuration distante manuelle — KIBO-006

Dans **Supabase → Authentication → URL Configuration**, autoriser exactement :

```text
com.kibo.kibo://auth/confirm
```

- Ajouter cette valeur à **Redirect URLs**, sans wildcard ni slash terminal. L’application demande explicitement cette adresse : elle doit être autorisée pour éviter un repli sur Site URL.
- Pour ce projet Android, remplacer également le **Site URL** `http://localhost:3000` par cette même URI afin que le repli ne cible plus localhost. Si ce projet dessert aussi un site web, faire valider sa véritable URL HTTPS de repli avant ce changement ; aucun domaine web n’est inventé ici.
- Vérifier le template **Confirm signup** : le lien doit utiliser `{{ .ConfirmationURL }}` (vérification par Supabase puis redirection), sans localhost codé en dur. Ne pas remplacer ce lien par la seule URI native : cela sauterait la vérification email. Un template personnalisé fondé sur `.SiteURL` ou `token_hash` nécessite une revue ; KIBO reçoit ici un `code` PKCE, pas un `token_hash` à vérifier lui-même.
- Aucun réglage distant n’a été lu ou modifié pour KIBO-006 ; ces étapes restent à réaliser par le propriétaire. Ne modifier ni RLS, ni schéma, ni secrets.

## Recette du retour Android — KIBO-006

1. Installer une nouvelle compilation contenant le manifeste et le callback, avec les paramètres publics saisis localement selon [SUPABASE_SETUP.md](SUPABASE_SETUP.md). Un hot reload ne met pas à jour le manifeste. Ne pas désinstaller/effacer les données entre inscription et confirmation.
2. Vérifier uniquement le routage sans code sensible : `adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "com.kibo.kibo://auth/confirm"`. KIBO doit s’ouvrir sans créer de session. Cette commande ne valide pas l’échange PKCE.
3. Depuis KIBO déconnecté, créer un nouveau compte de test contrôlé. Ouvrir le **nouvel** email sur ce TECNO, puis le lien dans le navigateur. Vérifier le retour dans KIBO, sans localhost, le formulaire fermé et Profil avec la bonne ville. Un ancien email conserve son ancienne destination.
4. Avec un autre test d’inscription, arrêter complètement l’app après envoi de l’email, sans effacer ses données ; ouvrir le lien pour vérifier le démarrage à froid et la reprise du vérificateur. Ouvrir Profil pour constater la connexion.
5. Tester lien expiré/déjà utilisé : message compréhensible, pas de crash ni divulgation. Une confirmation depuis un autre appareil ou après perte/remplacement du vérificateur ne permet pas l’échange PKCE local ; revenir se connecter par email/mot de passe si l’adresse est confirmée. Éviter plusieurs inscriptions PKCE en attente sur le même appareil : le vérificateur peut être remplacé.
6. Vérifier la session après arrêt/relance, puis déconnexion et relance. Ne partager aucun lien, code, mot de passe, email de test ou jeton dans les journaux/captures.

Les tests automatisés utilisent uniquement des fixtures et ne certifient ni le routage du navigateur Android, ni la configuration distante, ni l’envoi d’email. La nouvelle recette native reste à effectuer sur TECNO.

## Contrat `public.profiles`

Selon les métadonnées vérifiées et communiquées par le propriétaire le 2026-10-31 : `id` référence `auth.users.id` ; `city` vaut par défaut Brazzaville, `account_type` individual, dates par défaut maintenant ; `username`, `full_name`, `avatar_path`, `bio`, `neighborhood` sont facultatifs. `profiles_read` permet SELECT à anon/authenticated avec condition vraie. `profiles_update_own` limite UPDATE à `id = auth.uid()` dans USING et WITH CHECK.

Le trigger `on_auth_user_created`, AFTER INSERT sur `auth.users`, appelle `handle_new_user()` et crée déjà la ligne. **Aucun INSERT/UPSERT concurrent dans `profiles` depuis Flutter.** Après ouverture ou restauration d’une session, le repository lit `id, full_name, city`, filtrés par l’identifiant courant. Depuis KIBO-007, une action explicite permet de modifier uniquement `full_name` et `city` sur son profil ; ni rôle ni type de compte ne sont écrits. Voir [PROFILE.md](PROFILE.md) pour les contrôles et la recette restante. Un profil absent ou refusé reste distinct d’un échec d’authentification et peut être rechargé explicitement.

Après signup sans session, aucune requête de profil n’est faite ; le message invite à confirmer l’email sans promettre l’existence d’un nouveau compte, car Supabase peut masquer les inscriptions en doublon. Recherche effectuée dans le dépôt : aucune migration SQL ni corps de `handle_new_user()` trouvé. En conséquence, aucune métadonnée utilisateur additionnelle n’est transmise au trigger. La récupération du profil existant a été confirmée pendant la recette KIBO-005 ; aucun SQL ni changement RLS effectué ici.

## Tests et recette Android

Les 30 tests précédents sont conservés ; le faux client commun expose désormais un flux auth vide. Les nouveaux tests couvrent validations, messages sans détails bruts, confirmation sans session, session immédiate/restaurée, déconnexion, doubles soumissions, erreurs de flux, profil manquant/refusé et réponse tardive. Les tests widget couvrent navigation, visibilité du mot de passe, chargement, confirmation et inscription à 320 px/texte 150 % avec clavier. Des requêtes HTTP simulées vérifient le filtre de profil, l’absence d’écriture `profiles` et l’absence de métadonnées supplémentaires. Le stockage simulé vérifie l’isolation par projet, l’ordre écriture/suppression et la restauration du SDK après deux initialisations.

Les tests ne créent aucun compte distant. Le stockage natif chiffré et les services distants ne sont pas validés par les mocks.

Recette KIBO-005 confirmée sur TECNO CK6n : inscription, réception/ouverture du lien, connexion, profil avec ville, restauration après arrêt complet, déconnexion persistante et second compte correct. Le retour navigateur localhost défaillant motive KIBO-006. Le renouvellement après expiration et le hors réseau restent non vérifiés physiquement.

KIBO-006 ajoute les tests du filtre d’URI, du redirect et du challenge S256 au signup, de l’échange avec vérificateur chiffré après recréation du client, du refus sans vérificateur/rejeu et de la fermeture du formulaire sur session externe. Les 49 tests antérieurs sont conservés, avec adaptation du message de confirmation. Les résultats sont consignés dans [PROGRESS.md](PROGRESS.md) ; la nouvelle recette native reste à effectuer. Aucun compte/paramètre réel dans les tests automatisés. Aucun commit ni push.

Références : [SDK d’inscription Supabase](https://supabase.com/docs/reference/dart/auth-signup), [stockage chiffré et configuration Android du plugin](https://pub.dev/packages/flutter_secure_storage).

Références KIBO-006 : [redirections Supabase](https://supabase.com/docs/guides/auth/redirect-urls), [PKCE](https://supabase.com/docs/guides/auth/sessions/pkce-flow), [gestion des liens Flutter avec plugin](https://docs.flutter.dev/release/breaking-changes/deep-links-flag-change).
