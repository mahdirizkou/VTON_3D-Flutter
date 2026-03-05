import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../data/glasses_api.dart';
import '../models/glasses_item.dart';
import '../../auth/ui/profile_page.dart';
import '../../cart/data/cart_controller.dart';
import '../../cart/ui/widgets/cart_badge_icon.dart';
import 'explore_page.dart';
import 'favorites_page.dart';
import 'notifications_page.dart';
import 'try_on_page.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_state.dart';
import 'widgets/featured_card.dart';
import 'widgets/hero_card.dart';
import 'widgets/recent_try_card.dart';
import 'widgets/section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final GlassesApi _glassesApi = const GlassesApi();

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
    CartController.instance.ensureLoaded();
    _fetchGlasses();
  }

  List<GlassesItem> get _filteredItems {
    return _items.where((item) {
      final bool categoryMatch = _selectedCategory == 'All' ||
          item.tags.map((e) => e.toLowerCase()).contains(_selectedCategory.toLowerCase());
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
      final List<GlassesItem> loaded = await _glassesApi.fetchGlasses();
      if (!mounted) return;
      setState(() {
        _items = loaded;
      });
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _redirectToLogin(message: e.toString());
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load glasses. Please check your connection and try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _addToCart(GlassesItem item) async {
    await CartController.instance.addFromGlasses(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart')),
    );
  }

  Future<void> _openTryOn([GlassesItem? item]) async {
    final GlassesItem? selected = item ?? (_filteredItems.isNotEmpty ? _filteredItems.first : null);

    if (selected == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No glasses available yet.')),
      );
      return;
    }

    try {
      final GlassesItem enriched = await _glassesApi.fetchTryOnPayload(selected);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: enriched)),
      );
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _redirectToLogin(message: e.toString());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load try-on data. Opening item details only.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: selected)),
      );
    }
  }

  Future<void> _redirectToLogin({String? message}) async {
    await TokenStore.instance.clearTokens();
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
          const CartBadgeIcon(),
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
                ? ErrorState(error: _error!, onRetry: _fetchGlasses)
                : _items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchGlasses,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: const [
                            SizedBox(height: 140),
                            EmptyState(
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
                            HeroCard(onStartTryOn: () => _openTryOn()),
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
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final String category = _categories[index];
                                  final bool selected = category == _selectedCategory;
                                  return ChoiceChip(
                                    selected: selected,
                                    label: Text(category),
                                    onSelected: (_) {
                                      setState(() => _selectedCategory = category);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionHeader(
                              title: 'Featured Glasses',
                              trailing: '${_filteredItems.length} items',
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 280,
                              child: _filteredItems.isEmpty
                                  ? const EmptyState(
                                      title: 'No glasses found',
                                      subtitle: 'Try another search or category.',
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _filteredItems.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final GlassesItem item = _filteredItems[index];
                                        final bool isFavorite = _favorites.contains(item.id);
                                        return FeaturedCard(
                                          item: item,
                                          width: featuredCardWidth,
                                          isFavorite: isFavorite,
                                          onFavoriteTap: () => _toggleFavorite(item.id),
                                          onTryTap: () => _openTryOn(item),
                                          onBuyTap: () => _addToCart(item),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 20),
                            const SectionHeader(title: 'Recently Tried'),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 160,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentlyTried.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final GlassesItem item = _recentlyTried[index];
                                  return RecentTryCard(
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
