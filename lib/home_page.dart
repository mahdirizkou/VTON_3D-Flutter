import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// pubspec.yaml dependency: http: ^1.2.2

// IMPORTANT:
// - Chrome/Web: 127.0.0.1 works if Django runs on same PC.
// - Android emulator: use 10.0.2.2
// - Physical phone: use your PC LAN IP (e.g. http://192.168.1.10:8000)
const String kBaseUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const VtonApp());
}

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

  List<GlassesItem> _items = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<int> _favorites = <int>{};

  @override
  void initState() {
    super.initState();
    _fetchGlasses();
  }

  List<GlassesItem> get _filteredItems {
    return _items.where((item) {
      final bool categoryMatch = _selectedCategory == 'All' ||
          item.tags
              .map((e) => e.toLowerCase())
              .contains(_selectedCategory.toLowerCase());
      final String q = _searchQuery.trim().toLowerCase();
      final bool searchMatch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          (item.brand ?? '').toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q));
      return categoryMatch && searchMatch;
    }).toList();
  }

  List<GlassesItem> get _recentlyTried => _items.take(6).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGlasses() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/');
      final http.Response response = await http.get(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Unexpected response format');
        }

        final List<GlassesItem> loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(GlassesItem.fromJson)
            .toList();

        if (!mounted) return;
        setState(() {
          _items = loaded;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not load glasses. Please check your connection and try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<GlassesItem> _fetchTryOnPayload(GlassesItem item) async {
    final Uri uri =
        Uri.parse('$kBaseUrl/api/glasses2/glasses/${item.id}/tryon/');
    final http.Response response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format');
    }

    final dynamic positionRaw = decoded['position_offset'];
    final dynamic rotationRaw = decoded['rotation_offset'];

    return item.copyWith(
      glbUrl: decoded['glb_url']?.toString(),
      scale: _parseDouble(decoded['scale']),
      positionOffset:
          positionRaw is Map<String, dynamic> ? Vec3.fromJson(positionRaw) : null,
      rotationOffset:
          rotationRaw is Map<String, dynamic> ? Vec3.fromJson(rotationRaw) : null,
      anchor: decoded['anchor']?.toString(),
      version: decoded['version']?.toString(),
    );
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  Future<void> _openTryOn([GlassesItem? item]) async {
    final GlassesItem? selected =
        item ?? (_filteredItems.isNotEmpty ? _filteredItems.first : null);

    if (selected == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No glasses available yet.')),
      );
      return;
    }

    try {
      final GlassesItem enriched = await _fetchTryOnPayload(selected);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: enriched)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not load try-on data. Opening item details only.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: selected)),
      );
    }
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
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
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
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _fetchGlasses)
                : _items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchGlasses,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: const [
                            SizedBox(height: 140),
                            _EmptyState(
                              title: 'No glasses found',
                              subtitle: 'Pull to refresh and try again.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchGlasses,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          children: [
                            _HeroCard(onStartTryOn: () => _openTryOn()),
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
                                fillColor: colorScheme.surfaceContainerHighest
                                    .withOpacity(0.35),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (value) {
                                setState(() => _searchQuery = value);
                              },
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final String category = _categories[index];
                                  final bool selected =
                                      category == _selectedCategory;
                                  return ChoiceChip(
                                    selected: selected,
                                    label: Text(category),
                                    onSelected: (_) {
                                      setState(
                                          () => _selectedCategory = category);
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
                                      subtitle:
                                          'Try another search or category.',
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _filteredItems.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final GlassesItem item =
                                            _filteredItems[index];
                                        final bool isFavorite =
                                            _favorites.contains(item.id);
                                        return _FeaturedCard(
                                          item: item,
                                          width: featuredCardWidth,
                                          isFavorite: isFavorite,
                                          onFavoriteTap: () =>
                                              _toggleFavorite(item.id),
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
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final GlassesItem item =
                                      _recentlyTried[index];
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
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.videocam_outlined), label: 'Try-On'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined), label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.favorite_outline), label: 'Favorites'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
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
              MaterialPageRoute(builder: (_) => const ExplorePage()),
            );
            return;
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesPage(
                  allItems: _items,
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
            MaterialPageRoute(builder: (_) => const ProfilePage()),
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
                      content: Text(
                          'Step 1: Select frame. Step 2: Open camera. Step 3: Adjust fit.'),
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
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
                      item.thumbnailUrl ??
                          'https://picsum.photos/seed/fallback_${item.id}/900/600',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                      icon: Icon(isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(item.brand ?? 'Unknown brand',
                      style: Theme.of(context).textTheme.bodySmall),
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
                      Text((item.rating ?? 0).toStringAsFixed(1)),
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
                  item.thumbnailUrl ??
                      'https://picsum.photos/seed/recent_${item.id}/900/600',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
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
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.35),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
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
                item.thumbnailUrl ??
                    'https://picsum.photos/seed/tryon_${item.id}/900/600',
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 260,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(item.brand ?? 'Unknown brand',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Price: \$${item.price.toStringAsFixed(2)}'),
            Text('Rating: ${(item.rating ?? 0).toStringAsFixed(1)}'),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Try-On Payload',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('glb_url: ${item.glbUrl ?? '-'}'),
                        Text('scale: ${item.scale?.toStringAsFixed(3) ?? '-'}'),
                        Text(
                          'position_offset: ${item.positionOffset != null ? item.positionOffset!.toInlineString() : '-'}',
                        ),
                        Text(
                          'rotation_offset: ${item.rotationOffset != null ? item.rotationOffset!.toInlineString() : '-'}',
                        ),
                        Text('anchor: ${item.anchor ?? '-'}'),
                        Text('version: ${item.version ?? '-'}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<GlassesItem> onTryTap;

  @override
  Widget build(BuildContext context) {
    final List<GlassesItem> favorites =
        allItems.where((item) => favoriteIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(
              child: Text('No favorites yet. Save frames you like.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final GlassesItem item = favorites[index];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.thumbnailUrl ??
                            'https://picsum.photos/seed/fav_${item.id}/300/300',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined, size: 18),
                        ),
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.brand ?? 'Unknown brand'} • \$${item.price.toStringAsFixed(2)}'),
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
    required this.thumbnailUrl,
    required this.price,
    required this.rating,
    required this.tags,
    this.glbUrl,
    this.scale,
    this.positionOffset,
    this.rotationOffset,
    this.anchor,
    this.version,
  });

  factory GlassesItem.fromJson(Map<String, dynamic> json) {
    final dynamic tagsRaw = json['tags'];
    final List<String> parsedTags = tagsRaw is List
        ? tagsRaw
            .map((e) {
              if (e is String) return e;
              if (e is Map<String, dynamic>) {
                if (e['name'] != null) return e['name'].toString();
                if (e['label'] != null) return e['label'].toString();
              }
              return e.toString();
            })
            .where((tag) => tag.trim().isNotEmpty)
            .toList()
        : <String>[];

    return GlassesItem(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Unnamed',
      brand: json['brand']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      price: _parseDouble(json['price']) ?? 0,
      rating: _parseDouble(json['rating']),
      tags: parsedTags,
    );
  }

  final int id;
  final String name;
  final String? brand;
  final String? thumbnailUrl;
  final double price;
  final double? rating;
  final List<String> tags;

  final String? glbUrl;
  final double? scale;
  final Vec3? positionOffset;
  final Vec3? rotationOffset;
  final String? anchor;
  final String? version;

  GlassesItem copyWith({
    String? glbUrl,
    double? scale,
    Vec3? positionOffset,
    Vec3? rotationOffset,
    String? anchor,
    String? version,
  }) {
    return GlassesItem(
      id: id,
      name: name,
      brand: brand,
      thumbnailUrl: thumbnailUrl,
      price: price,
      rating: rating,
      tags: tags,
      glbUrl: glbUrl ?? this.glbUrl,
      scale: scale ?? this.scale,
      positionOffset: positionOffset ?? this.positionOffset,
      rotationOffset: rotationOffset ?? this.rotationOffset,
      anchor: anchor ?? this.anchor,
      version: version ?? this.version,
    );
  }
}

class Vec3 {
  const Vec3({required this.x, required this.y, required this.z});

  factory Vec3.fromJson(Map<String, dynamic> json) {
    return Vec3(
      x: _parseDouble(json['x']) ?? 0,
      y: _parseDouble(json['y']) ?? 0,
      z: _parseDouble(json['z']) ?? 0,
    );
  }

  final double x;
  final double y;
  final double z;

  String toInlineString() =>
      'x=${x.toStringAsFixed(3)}, y=${y.toStringAsFixed(3)}, z=${z.toStringAsFixed(3)}';
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}