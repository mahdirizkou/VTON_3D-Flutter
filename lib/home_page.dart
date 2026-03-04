import 'package:flutter/material.dart';

void main() => runApp(const VtonApp());

class VtonApp extends StatelessWidget {
  const VtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VTON 3D Glasses',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'All',
    'New',
    'Popular',
    'Men',
    'Women',
    'Unisex',
    'Round',
    'Square',
    'Aviator',
  ];

  final List<GlassesItem> _allItems = const [
    GlassesItem(
      id: 'g1',
      name: 'Aero Classic',
      brand: 'Lumi Optics',
      imageUrl: 'https://picsum.photos/seed/glasses1/900/600',
      price: 149.0,
      rating: 4.7,
      tags: ['New', 'Men', 'Aviator', 'Popular'],
    ),
    GlassesItem(
      id: 'g2',
      name: 'Noir Square',
      brand: 'Urban Lens',
      imageUrl: 'https://picsum.photos/seed/glasses2/900/600',
      price: 129.0,
      rating: 4.4,
      tags: ['Women', 'Square', 'Popular'],
    ),
    GlassesItem(
      id: 'g3',
      name: 'Halo Round',
      brand: 'FrameLab',
      imageUrl: 'https://picsum.photos/seed/glasses3/900/600',
      price: 99.0,
      rating: 4.2,
      tags: ['Unisex', 'Round'],
    ),
    GlassesItem(
      id: 'g4',
      name: 'Edge Pro',
      brand: 'Nexa Vision',
      imageUrl: 'https://picsum.photos/seed/glasses4/900/600',
      price: 179.0,
      rating: 4.8,
      tags: ['New', 'Unisex', 'Square', 'Popular'],
    ),
    GlassesItem(
      id: 'g5',
      name: 'Sunset Aviator',
      brand: 'SkyShade',
      imageUrl: 'https://picsum.photos/seed/glasses5/900/600',
      price: 139.0,
      rating: 4.5,
      tags: ['Women', 'Aviator'],
    ),
    GlassesItem(
      id: 'g6',
      name: 'Metro Slim',
      brand: 'CityFrame',
      imageUrl: 'https://picsum.photos/seed/glasses6/900/600',
      price: 119.0,
      rating: 4.1,
      tags: ['Men', 'Square'],
    ),
    GlassesItem(
      id: 'g7',
      name: 'Pearl Curve',
      brand: 'Mira Eyewear',
      imageUrl: 'https://picsum.photos/seed/glasses7/900/600',
      price: 159.0,
      rating: 4.6,
      tags: ['New', 'Women', 'Round'],
    ),
    GlassesItem(
      id: 'g8',
      name: 'Terra Bold',
      brand: 'Opticraft',
      imageUrl: 'https://picsum.photos/seed/glasses8/900/600',
      price: 189.0,
      rating: 4.9,
      tags: ['Popular', 'Unisex', 'Square'],
    ),
    GlassesItem(
      id: 'g9',
      name: 'Cloud Lite',
      brand: 'FeatherView',
      imageUrl: 'https://picsum.photos/seed/glasses9/900/600',
      price: 109.0,
      rating: 4.3,
      tags: ['Men', 'Round'],
    ),
    GlassesItem(
      id: 'g10',
      name: 'Nova Air',
      brand: 'Visionix',
      imageUrl: 'https://picsum.photos/seed/glasses10/900/600',
      price: 169.0,
      rating: 4.7,
      tags: ['New', 'Unisex', 'Aviator'],
    ),
  ];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<String> _favorites = <String>{};

  List<GlassesItem> get _filteredItems {
    return _allItems.where((item) {
      final bool categoryMatch = _selectedCategory == 'All' ||
          item.tags.map((e) => e.toLowerCase()).contains(
                _selectedCategory.toLowerCase(),
              );

      final String q = _searchQuery.trim().toLowerCase();
      final bool searchMatch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.brand.toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q));

      return categoryMatch && searchMatch;
    }).toList();
  }

  List<GlassesItem> get _recentlyTried => _allItems.take(6).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _openTryOn([GlassesItem? item]) {
    final GlassesItem selected =
        item ?? (_filteredItems.isNotEmpty ? _filteredItems.first : _allItems.first);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TryOnPage(item: selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double featuredCardWidth = width < 380 ? width * 0.72 : width * 0.62;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VTON 3D Glasses'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              'V',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _HeroCard(onStartTryOn: _openTryOn),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by frame, brand, style...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => setState(() => _searchQuery = value),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 14),

            // ✅ FIXED: separatorBuilder params
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final String category = _categories[index];
                  final bool selected = category == _selectedCategory;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    onSelected: (value) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Featured Glasses',
              trailing: '${_filteredItems.length} items',
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 280,
              child: _filteredItems.isEmpty
                  ? const _EmptyState(
                      title: 'No glasses found',
                      subtitle: 'Try another search or category.',
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredItems.length,
                      // ✅ FIXED
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final GlassesItem item = _filteredItems[index];
                        final bool isFavorite = _favorites.contains(item.id);
                        return _FeaturedCard(
                          item: item,
                          width: featuredCardWidth,
                          isFavorite: isFavorite,
                          onFavoriteTap: () => _toggleFavorite(item.id),
                          onTryTap: () => _openTryOn(item),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),
            const _SectionHeader(title: 'Recently Tried'),
            const SizedBox(height: 10),

            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recentlyTried.length,
                // ✅ FIXED
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final GlassesItem item = _recentlyTried[index];
                  return _RecentTryCard(
                    item: item,
                    onTryAgain: () => _openTryOn(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Try-On'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) return;

          if (index == 1) {
            _openTryOn();
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExplorePage()),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritesPage(
                  allItems: _allItems,
                  favoriteIds: _favorites,
                  onToggleFavorite: _toggleFavorite,
                  onTryTap: _openTryOn,
                ),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onStartTryOn});

  final VoidCallback onStartTryOn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try glasses in 3D',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open your camera and see the fit instantly.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onStartTryOn,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Try-On'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Step 1: Select frame. Step 2: Open camera. Step 3: Adjust fit.'),
                    ),
                  );
                },
                child: const Text('How it works'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.item,
    required this.width,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTryTap,
  });

  final GlassesItem item;
  final double width;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      onPressed: onFavoriteTap,
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(item.brand, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(item.rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTryTap,
                      child: const Text('Try'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTryCard extends StatelessWidget {
  const _RecentTryCard({required this.item, required this.onTryAgain});

  final GlassesItem item;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTryAgain,
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class TryOnPage extends StatelessWidget {
  const TryOnPage({super.key, required this.item});

  final GlassesItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                item.imageUrl,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 260,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(item.brand, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Price: \$${item.price.toStringAsFixed(0)}'),
            Text('Rating: ${item.rating.toStringAsFixed(1)}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera placeholder activated.')),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderPage(
      title: 'Explore',
      subtitle: 'Discover trending frames and styles.',
      icon: Icons.explore_outlined,
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderPage(
      title: 'Profile',
      subtitle: 'Manage your account, sizes, and preferences.',
      icon: Icons.person_outline,
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.local_offer_outlined),
            title: Text('New arrivals this week'),
            subtitle: Text('Check out 8 new 3D-ready frames.'),
          ),
          ListTile(
            leading: Icon(Icons.favorite_outline),
            title: Text('Price drop on your favorites'),
            subtitle: Text('Some saved frames are now on sale.'),
          ),
          ListTile(
            leading: Icon(Icons.tips_and_updates_outlined),
            title: Text('Try-On tip'),
            subtitle: Text('Use good lighting for better face tracking.'),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.allItems,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onTryTap,
  });

  final List<GlassesItem> allItems;
  final Set<String> favoriteIds;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<GlassesItem> onTryTap;

  @override
  Widget build(BuildContext context) {
    final List<GlassesItem> favorites =
        allItems.where((item) => favoriteIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet. Save frames you like.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              // ✅ FIXED
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final GlassesItem item = favorites[index];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.brand} • \$${item.price.toStringAsFixed(0)}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          onPressed: () => onTryTap(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite),
                          onPressed: () => onToggleFavorite(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SimplePlaceholderPage extends StatelessWidget {
  const _SimplePlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassesItem {
  const GlassesItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.tags,
  });

  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final double price;
  final double rating;
  final List<String> tags;
}