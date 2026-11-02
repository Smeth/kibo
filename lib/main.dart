import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/trust/trust_scope.dart';
import 'features/push/push_registration.dart';
import 'features/listings/category_shortcuts.dart';

import 'core/config/supabase_config.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/kibo_colors.dart';
import 'core/theme/kibo_theme.dart';
import 'core/widgets/kibo_bottom_navigation.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/profile_page.dart';
import 'features/listings/listing_repository.dart';
import 'features/listings/owned_listing_repository.dart';
import 'features/listings/my_listings_page.dart';
import 'features/listings/publish_listing_page.dart';
import 'features/listings/listing_feed.dart';
import 'features/listings/listing_photos.dart';
import 'features/listings/listing_photo_widgets.dart';
import 'features/favorites/favorites_controller.dart';
import 'features/favorites/favorites_repository.dart';
import 'features/favorites/favorites_page.dart';
import 'features/favorites/guest_favorites.dart';
import 'features/comments/comments_repository.dart';
import 'features/seller/seller_repository.dart';
import 'features/seller/contact_preferences_page.dart';
import 'features/chat/chat_repository.dart';
import 'features/chat/chat_page.dart';
import 'features/chat/chat_overview.dart';
import 'features/safety/safety_repository.dart';
import 'features/safety/safety_page.dart';
import 'features/safety/admin_page.dart';
import 'features/safety/safety_entry.dart';
import 'features/listings/listing_detail_page.dart';
import 'features/listings/listing_query.dart';
import 'features/listings/listing_draft_store.dart';
import 'features/profile/account_settings_page.dart';
import 'features/profile/engagement_repository.dart';
import 'features/profile/engagement_pages.dart';
import 'features/auth/password_pages.dart';
import 'features/comments/comments_page.dart';
import 'core/theme/appearance_controller.dart';
import 'core/widgets/congo_city_field.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KiboTheme.registerFontLicense();
  runApp(
    KiboApp(
      supabase: SupabaseService(config: const SupabaseConfig.fromEnvironment()),
    ),
  );
}

class KiboApp extends StatefulWidget {
  const KiboApp({
    super.key,
    required this.supabase,
    this.authRepository,
    this.listingRepository,
    this.ownedListingRepository,
    this.favoritesRepository,
    this.photoRepository,
    this.photoPicker,
    this.guestFavoritesStore,
    this.commentsRepository,
    this.sellerRepository,
    this.contactLauncher,
    this.chatRepository,
    this.safetyRepository,
    this.draftStore,
    this.accountRequests,
    this.appearance,
  });

  final SupabaseService supabase;
  final AuthRepository? authRepository;
  final ListingRepository? listingRepository;
  final OwnedListingRepository? ownedListingRepository;
  final FavoritesRepository? favoritesRepository;
  final ListingPhotoRepository? photoRepository;
  final ListingPhotoPicker? photoPicker;
  final GuestFavoritesStore? guestFavoritesStore;
  final CommentsRepository? commentsRepository;
  final SellerRepository? sellerRepository;
  final ContactLauncher? contactLauncher;
  final ChatRepository? chatRepository;
  final SafetyRepository? safetyRepository;
  final ListingDraftStore? draftStore;
  final AccountRequestsRepository? accountRequests;
  final AppearanceController? appearance;

  @override
  State<KiboApp> createState() => _KiboAppState();
}

class _KiboAppState extends State<KiboApp> {
  late final _appearance =
      widget.appearance ?? AppearanceController(SecureAppearanceStore());
  @override
  void initState() {
    super.initState();
    _appearance.initialize();
  }

  late final _startup = widget.supabase.initialize();
  AuthRepository? _authRepository;
  ListingRepository? _listingRepository;
  OwnedListingRepository? _ownedListingRepository;
  FavoritesRepository? _favoritesRepository;
  ListingPhotoRepository? _photoRepository;
  ListingPhotoPicker? _photoPicker;
  GuestFavoritesStore? _guestFavoritesStore;
  CommentsRepository? _commentsRepository;
  SellerRepository? _sellerRepository;
  ContactLauncher? _contactLauncher;
  ChatRepository? _chatRepository;
  SafetyRepository? _safetyRepository;
  ListingDraftStore? _draftStore;
  AccountRequestsRepository? _accountRequests;
  PushRegistration? _push;

  @override
  void dispose() {
    _push?.dispose();
    final chats = _chatRepository;
    if (widget.chatRepository == null && chats is SupabaseChatRepository) {
      chats.dispose();
    }
    final safety = _safetyRepository;
    if (widget.safetyRepository == null && safety is SupabaseSafetyRepository) {
      safety.dispose();
    }
    super.dispose();
    if (widget.appearance == null) _appearance.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearance,
      builder: (context, _) => AppearanceScope(
        controller: _appearance,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KIBO',
          theme: KiboTheme.light,
          darkTheme: KiboTheme.dark,
          themeMode: _appearance.mode,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (Theme.of(context).brightness == Brightness.dark
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                      systemNavigationBarColor: Theme.of(
                        context,
                      ).colorScheme.surface,
                      systemNavigationBarIconBrightness:
                          Theme.of(context).brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark,
                    ),
            child: TrustScope(
              clientProvider: () => widget.supabase.client,
              child: child!,
            ),
          ),
          home: FutureBuilder<SupabaseStartupResult>(
            future: _startup,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final result = snapshot.requireData;
              if (result.isReady) {
                (_push ??= PushRegistration(widget.supabase.client)).start();
                return ListingPhotoScope(
                  repository: _photoRepository ??=
                      widget.photoRepository ??
                      SupabaseListingPhotoRepository(widget.supabase.client),
                  picker: _photoPicker ??=
                      widget.photoPicker ?? DeviceListingPhotoPicker(),
                  child: AuthSession(
                    repository: _authRepository ??=
                        widget.authRepository ??
                        SupabaseAuthRepository(
                          widget.supabase.client,
                          clearPersistedSession:
                              widget.supabase.clearPersistedSession,
                        ),
                    child: FavoritesSession(
                      guestStore: _guestFavoritesStore ??=
                          widget.guestFavoritesStore ??
                          SecureGuestFavoritesStore(
                            projectHost: Uri.parse(
                              widget.supabase.config.url,
                            ).host,
                          ),
                      listings: _listingRepository ??=
                          widget.listingRepository ??
                          SupabaseListingRepository(widget.supabase.client),
                      repository: _favoritesRepository ??=
                          widget.favoritesRepository ??
                          SupabaseFavoritesRepository(widget.supabase.client),
                      child: KiboHomePage(
                        accountRequests: _accountRequests ??=
                            widget.accountRequests ??
                            SupabaseAccountRequestsRepository(
                              widget.supabase.client,
                            ),
                        draftStore: _draftStore ??=
                            widget.draftStore ??
                            SecureListingDraftStore(
                              projectHost: Uri.parse(
                                widget.supabase.config.url,
                              ).host,
                            ),
                        safety: _safetyRepository ??=
                            widget.safetyRepository ??
                            SupabaseSafetyRepository(widget.supabase.client),
                        chats: _chatRepository ??=
                            widget.chatRepository ??
                            SupabaseChatRepository(widget.supabase.client),
                        sellers: _sellerRepository ??=
                            widget.sellerRepository ??
                            SupabaseSellerRepository(widget.supabase.client),
                        contactLauncher: _contactLauncher ??=
                            widget.contactLauncher ?? DeviceContactLauncher(),
                        comments: _commentsRepository ??=
                            widget.commentsRepository ??
                            SupabaseCommentsRepository(widget.supabase.client),
                        ownedRepository: _ownedListingRepository ??=
                            widget.ownedListingRepository ??
                            SupabaseOwnedListingRepository(
                              widget.supabase.client,
                            ),
                        repository: _listingRepository ??=
                            widget.listingRepository ??
                            SupabaseListingRepository(widget.supabase.client),
                      ),
                    ),
                  ),
                );
              }
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.settings_outlined,
                            color: KiboColors.primary,
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Configuration KIBO',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class KiboHomePage extends StatefulWidget {
  const KiboHomePage({
    super.key,
    required this.repository,
    this.ownedRepository,
    this.comments,
    this.sellers,
    this.contactLauncher,
    this.chats,
    this.safety,
    this.draftStore,
    this.accountRequests,
  });
  final ListingRepository repository;
  final OwnedListingRepository? ownedRepository;
  final CommentsRepository? comments;
  final SellerRepository? sellers;
  final ContactLauncher? contactLauncher;
  final ChatRepository? chats;
  final SafetyRepository? safety;
  final ListingDraftStore? draftStore;
  final AccountRequestsRepository? accountRequests;

  @override
  State<KiboHomePage> createState() => _KiboHomePageState();
}

class _KiboHomePageState extends State<KiboHomePage> {
  int selectedTab = 0;
  int _safetyRevision = 0;
  ListingQuery _searchQuery = const ListingQuery();
  String _homeCity = '';
  Future<void> _openSafety(SafetyScreen screen) async {
    final auth = AuthScope.maybeOf(context),
        owner = AuthScope.maybeOf(context)?.identity?.id;
    if (auth == null || owner == null) {
      setState(() => selectedTab = 4);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScope(
          controller: auth,
          child: SafetyPage(
            repository: widget.safety!,
            ownerId: owner,
            screen: screen,
            onPreferences: widget.accountRequests is AccountEngagementRepository
                ? () => _openEngagement(true)
                : null,
            onOpenNotice: (notice) async {
              if (auth.identity?.id != owner) return;
              Widget? page;
              final threadId = notice.data['conversation_id'],
                  listingId = notice.data['listing_id'],
                  parentId = notice.data['parent_id'];
              if (notice.data['account_request'] == true &&
                  widget.accountRequests is AccountEngagementRepository) {
                page = EngagementPage(
                  controller: auth,
                  repository:
                      widget.accountRequests as AccountEngagementRepository,
                );
              } else if (threadId is String && widget.chats != null) {
                final thread = await widget.safety!.conversation(
                  owner,
                  threadId,
                );
                if (!mounted || auth.identity?.id != owner) return;
                if (thread == null) {
                  throw StateError('Conversation indisponible');
                }
                page = ChatPage(
                  repository: widget.chats!,
                  ownerId: owner,
                  thread: thread,
                );
              } else if (listingId is String) {
                page =
                    widget.comments != null &&
                        notice.data.containsKey('parent_id')
                    ? CommentsPage(
                        listingId: listingId,
                        repository: widget.comments!,
                        parentId: parentId is String ? parentId : null,
                        safety: widget.safety,
                      )
                    : ListingDetailPage(
                        id: listingId,
                        repository: widget.repository,
                        comments: widget.comments,
                        sellers: widget.sellers,
                        contactLauncher: widget.contactLauncher,
                        chats: widget.chats,
                        safety: widget.safety,
                      );
              }
              if (page != null && mounted && auth.identity?.id == owner) {
                final content = page;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthScope(controller: auth, child: content),
                  ),
                );
              }
            },
            onOpenReport: (report) async {
              Widget? page;
              if (report.listingId != null) {
                page = ListingDetailPage(
                  id: report.listingId!,
                  repository: widget.repository,
                  comments: widget.comments,
                  safety: widget.safety,
                );
              }
              if (page != null && mounted && auth.identity?.id == owner) {
                final content = page;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthScope(controller: auth, child: content),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
    if (mounted) setState(() => _safetyRevision++);
  }

  Future<void> _openMessages() async {
    final auth = AuthScope.maybeOf(context);
    final owner = auth?.identity?.id;
    if (auth == null || owner == null) {
      setState(() => selectedTab = 4);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScope(
          controller: auth,
          child: ChatPage(repository: widget.chats!, ownerId: owner),
        ),
      ),
    );
    if (mounted) setState(() => _safetyRevision++);
  }

  Future<void> _openAdmin() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || auth.identity == null || widget.safety == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminPage(
          auth: auth,
          safety: widget.safety!,
          accounts: widget.accountRequests is AccountEngagementRepository
              ? widget.accountRequests as AccountEngagementRepository
              : null,
          onReports: () => _openSafety(SafetyScreen.moderation),
          onAccounts: () => _openEngagement(false, operatorOnly: true),
        ),
      ),
    );
    if (mounted) setState(() => _safetyRevision++);
  }

  Future<void> _openEngagement(
    bool preferences, {
    bool operatorOnly = false,
  }) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null ||
        auth.identity == null ||
        widget.accountRequests is! AccountEngagementRepository) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EngagementPage(
          controller: auth,
          repository: widget.accountRequests as AccountEngagementRepository,
          preferences: preferences,
          operatorOnly: operatorOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    if (auth?.recoveringPassword == true) {
      return PasswordChangePage(controller: auth!, recovery: true);
    }
    return Scaffold(
      body: SafeArea(
        child: selectedTab == 4
            ? ProfilePage(
                onAccountSettings: widget.accountRequests == null
                    ? null
                    : () {
                        final auth = AuthScope.maybeOf(context);
                        if (auth == null || auth.identity == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccountSettingsPage(
                              controller: auth,
                              repository: widget.accountRequests!,
                              chats: widget.chats,
                            ),
                          ),
                        );
                      },
                onNotifications: widget.safety == null
                    ? null
                    : () => _openSafety(SafetyScreen.notifications),
                moderationEntry: widget.safety == null
                    ? null
                    : SafetyEntry(
                        repository: widget.safety!,
                        moderation: true,
                        moderationLabel: 'Administration',
                        onPressed: _openAdmin,
                      ),
                onMessages: widget.chats == null ? null : _openMessages,
                onContactSettings: widget.sellers == null
                    ? null
                    : () {
                        final auth = AuthScope.maybeOf(context);
                        final owner = auth?.identity?.id;
                        if (auth == null || owner == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AuthScope(
                              controller: auth,
                              child: ContactPreferencesPage(
                                ownerId: owner,
                                repository: widget.sellers!,
                              ),
                            ),
                          ),
                        );
                      },
                onMyListings: widget.ownedRepository == null
                    ? null
                    : () {
                        final auth = AuthScope.maybeOf(context);
                        final favorites = FavoritesScope.maybeOf(context);
                        if (auth == null || favorites == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) {
                              Widget page = MyListingsPage(
                                repository: widget.ownedRepository!,
                                listings: widget.repository,
                              );
                              final photos = ListingPhotoScope.maybeOf(context);
                              if (photos != null) {
                                page = ListingPhotoScope(
                                  repository: photos.repository,
                                  picker: photos.picker,
                                  child: page,
                                );
                              }
                              return AuthScope(
                                controller: auth,
                                child: FavoritesScope(
                                  controller: favorites,
                                  child: page,
                                ),
                              );
                            },
                          ),
                        );
                      },
              )
            : selectedTab == 2
            ? PublishListingPage(
                draftStore: widget.draftStore,
                repository: widget.repository,
                onPublished: (_) {
                  setState(() {
                    selectedTab = 0;
                  });
                  FavoritesScope.maybeOf(context)?.refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Annonce publiée.')),
                  );
                },
              )
            : selectedTab == 3
            ? FavoritesPage(
                safety: widget.safety,
                chats: widget.chats,
                sellers: widget.sellers,
                contactLauncher: widget.contactLauncher,
                listings: widget.repository,
                comments: widget.comments,
              )
            : ListingFeed(
                initialQuery: selectedTab == 1
                    ? _searchQuery
                    : ListingQuery(city: _homeCity),
                onQueryChanged: selectedTab == 1
                    ? (query) => _searchQuery = query
                    : (query) {
                        if (query.city != _homeCity) {
                          setState(() => _homeCity = query.city);
                        }
                      },
                safety: widget.safety,
                chats: widget.chats,
                sellers: widget.sellers,
                contactLauncher: widget.contactLauncher,
                key: ValueKey('$selectedTab|$_homeCity'),
                searchEnabled: selectedTab == 1,
                repository: widget.repository,
                comments: widget.comments,
                leading: [
                  _buildHeader(),
                  if (selectedTab == 0)
                    CategoryShortcuts(
                      repository: widget.repository,
                      onSelected: (category) => setState(() {
                        _searchQuery = ListingQuery(
                          categoryId: category?.id,
                          city: _homeCity,
                        );
                        selectedTab = 1;
                      }),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final foreground = KiboColors.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: KiboColors.primaryDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Tooltip(
                message: 'Le commerce, simplement.',
                child: Text(
                  'KIBO',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Theme(
                data: theme.copyWith(
                  iconButtonTheme: IconButtonThemeData(
                    style: IconButton.styleFrom(foregroundColor: foreground),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.chats != null)
                      ChatEntry(
                        repository: widget.chats!,
                        revision: _safetyRevision,
                        showLabel: false,
                        onPressed: _openMessages,
                      ),
                    if (widget.safety != null)
                      SafetyEntry(
                        repository: widget.safety!,
                        revision: _safetyRevision,
                        showLabel: false,
                        onPressed: () =>
                            _openSafety(SafetyScreen.notifications),
                      ),
                    if (AppearanceScope.maybeOf(context) != null)
                      IconButton(
                        tooltip: 'Changer l’apparence',
                        icon: const Icon(Icons.contrast_rounded),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => AppearanceScope(
                            controller: AppearanceScope.maybeOf(context)!,
                            child: const SafeArea(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: AppearancePicker(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: AuthScope.maybeOf(context)?.identity != null
                          ? 'Ouvrir mon profil connecté'
                          : 'Ouvrir mon profil',
                      onPressed: () => setState(() => selectedTab = 4),
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (selectedTab == 0) ...[
            const SizedBox(height: 8),
            Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: const ValueKey('home-search-action'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _searchQuery = ListingQuery(city: _homeCity);
                  selectedTab = 1;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rechercher une annonce...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('home-city-filter'),
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                ),
                onPressed: () async {
                  final city = await pickCongoCity(
                    context,
                    current: _homeCity,
                    allowAll: true,
                  );
                  if (city != null && mounted) setState(() => _homeCity = city);
                },
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(
                  _homeCity.isEmpty ? 'Toutes les villes du Congo' : _homeCity,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return KiboBottomNavigation(
      selectedIndex: selectedTab,
      onDestinationSelected: (index) {
        setState(() => selectedTab = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Recherche',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          label: 'Publier',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          label: 'Favoris',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}
