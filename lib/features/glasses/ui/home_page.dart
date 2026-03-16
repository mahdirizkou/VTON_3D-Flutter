import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../../auth/ui/profile_page.dart';
import '../../cart/data/cart_controller.dart';
import '../../cart/ui/widgets/cart_badge_icon.dart';
import '../../orders/models/order_item.dart';
import '../data/glasses_api.dart';
import '../models/glasses_item.dart';
import 'explore_page.dart';
import 'favorites_page.dart';
import 'notifications_page.dart';
import 'product_details_page.dart';
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

  final List<String> _categories = const <String>[
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

  List<GlassesItem> _items = <GlassesItem>[];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<int> _favorites = <int>{};
  Future<GlassesItem>? _tryOnFuture;
  int? _tryOnItemId;

  @override
  void initState() {
    super.initState();
    CartController.instance.ensureLoaded();
    _fetchGlasses();
  }

  List<GlassesItem> get _filteredItems {
    return _items.where((GlassesItem item) {
      final bool categoryMatch = _selectedCategory == 'All' ||
          item.tags.map((String tag) => tag.toLowerCase()).contains(
                _selectedCategory.toLowerCase(),
              );
      final String query = _searchQuery.trim().toLowerCase();
      final bool searchMatch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          (item.brand ?? '').toLowerCase().contains(query) ||
          item.tags.any((String tag) => tag.toLowerCase().contains(query));
      return categoryMatch && searchMatch;
    }).toList();
  }

  List<GlassesItem> get _recentlyTried => _items.take(6).toList();

  GlassesItem? get _primaryTryOnItem {
    if (_filteredItems.isNotEmpty) {
      return _filteredItems.first;
    }
    if (_items.isNotEmpty) {
      return _items.first;
    }
    return null;
  }

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
        final GlassesItem? selected = _primaryTryOnItem;
        if (selected == null || _tryOnItemId != selected.id) {
          _tryOnFuture = null;
          _tryOnItemId = null;
        }
      });
    } on ApiUnauthorizedException catch (error) {
      if (!mounted) return;
      await _redirectToLogin(message: error.toString());
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

  Future<void> _buyNow(GlassesItem item) async {
    await CartController.instance.ensureLoaded();
    await CartController.instance.addItem(
      OrderItem.fromGlasses(item, quantity: 1),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart')),
    );
  }

  void _openProductDetails(GlassesItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          item: item,
          isFavorite: _favorites.contains(item.id),
          onFavoriteToggle: _toggleFavorite,
        ),
      ),
    );
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
      (Route<dynamic> route) => false,
    );
  }

  Future<GlassesItem> _prepareTryOnItem() async {
    final GlassesItem? selected = _primaryTryOnItem;
    if (selected == null) {
      throw Exception('No glasses available yet.');
    }

    try {
      return await _glassesApi.fetchTryOnPayload(selected);
    } on ApiUnauthorizedException {
      rethrow;
    } catch (_) {
      return selected;
    }
  }

  void _ensureTryOnPageReady() {
    final GlassesItem? selected = _primaryTryOnItem;
    if (selected == null) {
      _tryOnFuture = null;
      _tryOnItemId = null;
      return;
    }
    if (_tryOnFuture != null && _tryOnItemId == selected.id) {
      return;
    }
    _tryOnItemId = selected.id;
    _tryOnFuture = _prepareTryOnItem();
  }

  Future<void> _retryTryOnLoad() async {
    setState(() {
      _tryOnFuture = null;
      _tryOnItemId = null;
      _ensureTryOnPageReady();
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == 1) {
      setState(() {
        _selectedIndex = index;
        _ensureTryOnPageReady();
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPageForIndex() {
    return IndexedStack(
      index: _selectedIndex,
      children: <Widget>[
        _buildHomeTab(),
        _buildTryOnTab(),
        const ExplorePage(),
        FavoritesPage(
          allItems: _items,
          favoriteIds: _favorites,
          onToggleFavorite: _toggleFavorite,
          onTryTap: (GlassesItem item) {
            setState(() {
              _selectedIndex = 1;
              _tryOnItemId = item.id;
              _tryOnFuture = _loadSpecificTryOnItem(item);
            });
          },
        ),
        const ProfilePage(),
      ],
    );
  }

  Future<GlassesItem> _loadSpecificTryOnItem(GlassesItem item) async {
    try {
      return await _glassesApi.fetchTryOnPayload(item);
    } on ApiUnauthorizedException {
      rethrow;
    } catch (_) {
      return item;
    }
  }

  Widget _buildHomeTab() {
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
        actions: <Widget>[
          const CartBadgeIcon(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _openNotifications,
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
            onPressed: () => _onDestinationSelected(4),
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
                          children: const <Widget>[
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
                          children: <Widget>[
                            HeroCard(
                              onStartTryOn: () => _onDestinationSelected(1),
                            ),
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
                                          setState(() {
                                            _searchQuery = '';
                                            _tryOnFuture = null;
                                            _tryOnItemId = null;
                                          });
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
                              onSubmitted: (String value) {
                                setState(() {
                                  _searchQuery = value;
                                  _tryOnFuture = null;
                                  _tryOnItemId = null;
                                });
                              },
                              onChanged: (String value) {
                                setState(() {
                                  _searchQuery = value;
                                  _tryOnFuture = null;
                                  _tryOnItemId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (BuildContext context, int index) {
                                  final String category = _categories[index];
                                  final bool selected = category == _selectedCategory;
                                  return ChoiceChip(
                                    selected: selected,
                                    label: Text(category),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCategory = category;
                                        _tryOnFuture = null;
                                        _tryOnItemId = null;
                                      });
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
                                      itemBuilder: (BuildContext context, int index) {
                                        final GlassesItem item = _filteredItems[index];
                                        final bool isFavorite = _favorites.contains(item.id);
                                        return FeaturedCard(
                                          item: item,
                                          width: featuredCardWidth,
                                          isFavorite: isFavorite,
                                          onFavoriteTap: () => _toggleFavorite(item.id),
                                          onTryTap: () {
                                            setState(() {
                                              _selectedIndex = 1;
                                              _tryOnItemId = item.id;
                                              _tryOnFuture = _loadSpecificTryOnItem(item);
                                            });
                                          },
                                          onBuyTap: () => _buyNow(item),
                                          onTap: () => _openProductDetails(item),
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
                                itemBuilder: (BuildContext context, int index) {
                                  final GlassesItem item = _recentlyTried[index];
                                  return RecentTryCard(
                                    item: item,
                                    onTryAgain: () {
                                      setState(() {
                                        _selectedIndex = 1;
                                        _tryOnItemId = item.id;
                                        _tryOnFuture = _loadSpecificTryOnItem(item);
                                      });
                                    },
                                    onTap: () => _openProductDetails(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildTryOnTab() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final GlassesItem? selected = _primaryTryOnItem;
    if (selected == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Try-On')),
        body: const EmptyState(
          title: 'No glasses available',
          subtitle: 'Add products first to open the try-on view.',
        ),
      );
    }

    _ensureTryOnPageReady();
    return FutureBuilder<GlassesItem>(
      future: _tryOnFuture,
      builder: (BuildContext context, AsyncSnapshot<GlassesItem> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final Object error = snapshot.error!;
          if (error is ApiUnauthorizedException) {
            return Scaffold(
              appBar: AppBar(title: const Text('Try-On')),
              body: ErrorState(
                error: error.toString(),
                onRetry: () async {
                  await _redirectToLogin(message: error.toString());
                },
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Try-On')),
            body: ErrorState(
              error: 'Could not load try-on data.',
              onRetry: _retryTryOnLoad,
            ),
          );
        }

        return TryOnPage(item: snapshot.data ?? selected);
      },
    );
  }

  Widget _buildBottomNav() {
    const List<_NavItemData> items = <_NavItemData>[
      _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.videocam_outlined, activeIcon: Icons.videocam_rounded, label: 'Try-On'),
      _NavItemData(icon: Icons.view_in_ar_outlined, activeIcon: Icons.view_in_ar, label: 'My Try'),
      _NavItemData(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Favorites'),
      _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final _NavItemData item = items[index];
              final bool selected = index == _selectedIndex;
              return Expanded(
                child: _BottomNavItem(
                  data: item,
                  selected: selected,
                  onTap: () => _onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageForIndex(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              selected ? data.activeIcon : data.icon,
              color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
