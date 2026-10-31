import 'package:flutter/material.dart';

import 'core/config/supabase_config.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/kibo_colors.dart';
import 'core/theme/kibo_theme.dart';
import 'core/widgets/kibo_bottom_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KiboTheme.registerFontLicense();
  runApp(
    KiboApp(
      supabase: SupabaseService(config: const SupabaseConfig.fromEnvironment()),
    ),
  );
}

class KiboApp extends StatelessWidget {
  const KiboApp({super.key, required this.supabase});

  final SupabaseService supabase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KIBO',
      theme: KiboTheme.light,
      home: FutureBuilder<SupabaseStartupResult>(
        future: supabase.initialize(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.requireData;
          if (result.isReady) return const KiboHomePage();
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
                      Text(result.errorMessage!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class KiboHomePage extends StatefulWidget {
  const KiboHomePage({super.key});

  @override
  State<KiboHomePage> createState() => _KiboHomePageState();
}

class _KiboHomePageState extends State<KiboHomePage> {
  int selectedCategory = 0;
  int selectedTab = 0;

  final categories = const [
    (name: 'Tout', icon: Icons.grid_view_rounded),
    (name: 'Téléphones', icon: Icons.phone_android),
    (name: 'Véhicules', icon: Icons.directions_car_outlined),
    (name: 'Immobilier', icon: Icons.home_outlined),
    (name: 'Maison', icon: Icons.chair_outlined),
    (name: 'Mode', icon: Icons.checkroom_outlined),
    (name: 'Services', icon: Icons.handyman_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildWelcome()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildSectionHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final columns =
                      constraints.crossAxisExtent >=
                          312 * (scaler.scale(14) / 14) + 12
                      ? 2
                      : 1;
                  final cardWidth =
                      (constraints.crossAxisExtent - (columns - 1) * 12) /
                      columns;
                  final imageHeight = (cardWidth * 0.85)
                      .clamp(140.0, 180.0)
                      .toDouble();
                  final cards = [
                    _buildProductCard(
                      imageHeight: imageHeight,
                      title: 'Smartphone Android',
                      price: '85 000 FCFA',
                      location: 'Poto-Poto, Brazzaville',
                      icon: Icons.phone_android,
                      color: const Color(0xFFE5F2EC),
                      label: 'Téléphones',
                    ),
                    _buildProductCard(
                      imageHeight: imageHeight,
                      title: 'Canapé moderne',
                      price: '150 000 FCFA',
                      location: 'Bacongo, Brazzaville',
                      icon: Icons.weekend_outlined,
                      color: const Color(0xFFF4EBDD),
                      label: 'Maison',
                    ),
                    _buildProductCard(
                      imageHeight: imageHeight,
                      title: 'Moto en bon état',
                      price: '450 000 FCFA',
                      location: 'Moungali, Brazzaville',
                      icon: Icons.two_wheeler,
                      color: const Color(0xFFE9EDF6),
                      label: 'Véhicules',
                    ),
                    _buildProductCard(
                      imageHeight: imageHeight,
                      title: 'Appartement à louer',
                      price: '120 000 FCFA / mois',
                      location: 'Talangaï, Brazzaville',
                      icon: Icons.apartment,
                      color: const Color(0xFFF2E9E5),
                      label: 'Immobilier',
                    ),
                  ];
                  return SliverList.list(
                    children: [
                      for (
                        var start = 0;
                        start < cards.length;
                        start += columns
                      )
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (
                                  var offset = 0;
                                  offset < columns;
                                  offset++
                                ) ...[
                                  if (offset > 0) const SizedBox(width: 12),
                                  Expanded(child: cards[start + offset]),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KIBO',
                  style: text.displaySmall?.copyWith(
                    color: KiboColors.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le commerce, simplement.',
                  style: text.bodySmall?.copyWith(
                    color: KiboColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KiboColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KiboColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 24,
            backgroundColor: KiboColors.primaryContainer,
            child: Icon(Icons.person_outline, color: KiboColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: KiboColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KiboColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: KiboColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Que recherchez-vous ?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KiboColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.tune_rounded, color: KiboColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KiboColors.primary, KiboColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue sur KIBO !',
            style: text.headlineSmall?.copyWith(color: KiboColors.surface),
          ),
          const SizedBox(height: 8),
          Text(
            'Achetez, vendez et trouvez des services près de chez vous.',
            style: text.bodyMedium?.copyWith(color: KiboColors.surface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: KiboColors.surface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Brazzaville, Congo',
                  style: text.labelMedium?.copyWith(color: KiboColors.surface),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: KiboColors.surface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final text = Theme.of(context).textTheme;
    final labelScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Explorer les catégories', style: text.titleMedium),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56 + 16 + 36 * labelScale,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategory == index;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedCategory = index);
                },
                child: SizedBox(
                  width: 88 * labelScale,
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: selected
                              ? KiboColors.primary
                              : KiboColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KiboColors.border),
                        ),
                        child: Icon(
                          category.icon,
                          color: selected
                              ? KiboColors.surface
                              : KiboColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Annonces récentes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: () {}, child: const Text('Voir tout')),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required double imageHeight,
    required String title,
    required String price,
    required String location,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: ValueKey('listing-card-$title'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: ValueKey('listing-image-$title'),
            height: imageHeight,
            child: Container(
              width: double.infinity,
              color: color,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      icon,
                      size: 64,
                      color: KiboColors.primary.withValues(alpha: 0.65),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: KiboColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelMedium?.copyWith(
                                  color: KiboColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: KiboColors.surface,
                          child: Icon(
                            Icons.favorite_border,
                            size: 24,
                            color: KiboColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: KiboColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: KiboColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: text.bodySmall?.copyWith(
                          color: KiboColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
