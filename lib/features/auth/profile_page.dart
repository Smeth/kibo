import 'package:flutter/material.dart';
import '../trust/help_page.dart';
import '../trust/security_page.dart';
import '../trust/trust_scope.dart';
import '../push/push_settings_page.dart';

import 'auth_controller.dart';
import 'auth_page.dart';
import '../profile/edit_profile_page.dart';
import '../../core/widgets/kibo_section.dart';
import '../../core/theme/appearance_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.onMyListings,
    this.onContactSettings,
    this.onMessages,
    this.onNotifications,
    this.moderationEntry,
    this.onAccountSettings,
  });
  final VoidCallback? onMessages;
  final VoidCallback? onNotifications;
  final Widget? moderationEntry;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onMyListings;
  final VoidCallback? onContactSettings;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    if (auth != null && auth.identity == null) {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mon profil',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const AppearancePicker(),
                ],
              ),
            ),
            AuthPage(controller: auth, embedded: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _HelpEntry(),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mon profil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (auth == null)
            const Text('Le service de compte est indisponible.')
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (auth.profileStatus == ProfileStatus.ready &&
                              auth.profile!.fullName != null)
                            Text(
                              auth.profile!.fullName!,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          Text(
                            (auth.identity!.email?.isNotEmpty ?? false)
                                ? auth.identity!.email!
                                : (auth.identity!.phone?.isNotEmpty ?? false)
                                ? auth.identity!.phone!
                                : 'Compte connecté',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (auth.profileStatus == ProfileStatus.ready) ...[
                            const SizedBox(height: 4),
                            Text(
                              auth.profile!.city,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (auth.profileStatus == ProfileStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (auth.profileStatus == ProfileStatus.ready) ...[
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () {
                        auth.message = null;
                        final profile = auth.profile!;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EditProfilePage(
                              controller: auth,
                              profile: profile,
                            ),
                          ),
                        );
                      },
                child: const Text('Modifier mon profil'),
              ),
            ] else ...[
              Text(
                auth.profileStatus == ProfileStatus.missing
                    ? 'Votre compte est connecté, mais le profil n’est pas encore disponible. Réessayez dans un instant.'
                    : 'Votre compte est connecté, mais le profil ne peut pas être chargé.',
              ),
              TextButton(
                onPressed: auth.synchronizeProfile,
                child: const Text('Réessayer le profil'),
              ),
            ],
            const SizedBox(height: 24),
            if (onMyListings != null)
              KiboMenuAction(
                onTap: onMyListings,
                icon: Icons.inventory_2_outlined,
                label: 'Mes annonces',
              ),
            if (onMessages != null)
              KiboMenuAction(
                onTap: onMessages,
                icon: Icons.chat_bubble_outline,
                label: 'Mes messages',
              ),
            if (onNotifications != null)
              KiboMenuAction(
                onTap: onNotifications,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
              ),
            if (onAccountSettings != null)
              KiboMenuAction(
                onTap: onAccountSettings,
                icon: Icons.manage_accounts_outlined,
                label: 'Compte et données',
              ),
            // ignore: use_null_aware_elements -- contournement du lint context après await du SDK local.
            if (moderationEntry case final entry?) entry,
            if (onContactSettings != null)
              KiboMenuAction(
                onTap: auth.busy ? null : onContactSettings,
                icon: Icons.contact_phone_outlined,
                label: 'Mes coordonnées de contact',
              ),
            if (AppearanceScope.maybeOf(context) != null) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AppearancePicker(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (TrustScope.maybeClient(context) case final client?) ...[
              KiboMenuAction(
                icon: Icons.security_outlined,
                label: 'Sécurité du compte',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SecurityPage(client: client),
                  ),
                ),
              ),
              KiboMenuAction(
                icon: Icons.notifications_active_outlined,
                label: 'Notifications sur ce téléphone',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PushSettingsPage(client: client),
                  ),
                ),
              ),
            ],
          ],
          if (auth?.message != null) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(auth!.message!)),
          ],
          const SizedBox(height: 16),
          const _HelpEntry(),
          if (auth != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: auth.busy ? null : auth.signOut,
              child: Text(auth.busy ? 'Veuillez patienter…' : 'Se déconnecter'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpEntry extends StatelessWidget {
  const _HelpEntry();
  @override
  Widget build(BuildContext context) => KiboMenuAction(
    icon: Icons.help_outline,
    label: 'Aide et confidentialité',
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HelpPage())),
  );
}
