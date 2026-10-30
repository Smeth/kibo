import 'package:flutter/material.dart';

import 'core/config/supabase_config.dart';
import 'core/supabase/supabase_service.dart';

const Color kiboGreen = Color(0xFF087F5B);
const Color kiboDark = Color(0xFF075B45);
const Color kiboBackground = Color(0xFFF7F9F7);
const Color kiboText = Color(0xFF17211D);
const Color kiboSecondary = Color(0xFF66736C);
const Color kiboBorder = Color(0xFFE5ECE7);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kiboBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kiboGreen,
          primary: kiboGreen,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
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
                        color: kiboGreen,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Configuration KIBO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
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
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _buildProductCard(
                    title: 'Smartphone Android',
                    price: '85 000 FCFA',
                    location: 'Poto-Poto, Brazzaville',
                    icon: Icons.phone_android,
                    color: const Color(0xFFE5F2EC),
                    label: 'Téléphones',
                  ),
                  _buildProductCard(
                    title: 'Canapé moderne',
                    price: '150 000 FCFA',
                    location: 'Bacongo, Brazzaville',
                    icon: Icons.weekend_outlined,
                    color: const Color(0xFFF4EBDD),
                    label: 'Maison',
                  ),
                  _buildProductCard(
                    title: 'Moto en bon état',
                    price: '450 000 FCFA',
                    location: 'Moungali, Brazzaville',
                    icon: Icons.two_wheeler,
                    color: const Color(0xFFE9EDF6),
                    label: 'Véhicules',
                  ),
                  _buildProductCard(
                    title: 'Appartement à louer',
                    price: '120 000 FCFA / mois',
                    location: 'Talangaï, Brazzaville',
                    icon: Icons.apartment,
                    color: const Color(0xFFF2E9E5),
                    label: 'Immobilier',
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KIBO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: kiboGreen,
                ),
              ),
              Text(
                'Le commerce, simplement.',
                style: TextStyle(fontSize: 11, color: kiboSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kiboBorder),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: kiboText,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5F2EC),
            child: const Icon(Icons.person_outline, color: kiboGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kiboBorder),
        ),
        child: const Row(
          children: [
            SizedBox(width: 15),
            Icon(Icons.search, color: kiboSecondary, size: 23),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Que recherchez-vous ?',
                style: TextStyle(color: kiboSecondary, fontSize: 14),
              ),
            ),
            Icon(Icons.tune_rounded, color: kiboGreen),
            SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 22, 16, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kiboGreen, kiboDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenue sur KIBO !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Achetez, vendez et trouvez des services près de chez vous.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 5),
              const Text(
                'Brazzaville, Congo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Explorer les catégories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kiboText,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 94,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategory == index;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedCategory = index);
                },
                child: SizedBox(
                  width: 66,
                  child: Column(
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: selected ? kiboGreen : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: kiboBorder),
                        ),
                        child: Icon(
                          category.icon,
                          color: selected ? Colors.white : kiboGreen,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: kiboText,
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Annonces récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kiboText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Voir tout',
              style: TextStyle(color: kiboGreen, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String title,
    required String price,
    required String location,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kiboBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: color,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      icon,
                      size: 65,
                      color: kiboGreen.withValues(alpha: 0.65),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9,
                          color: kiboGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.favorite_border,
                        size: 17,
                        color: kiboText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kiboText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kiboGreen,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: kiboSecondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: kiboSecondary,
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
    return NavigationBar(
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE5F2EC),
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
