import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../../cart/data/cart_controller.dart';
import '../../cart/ui/widgets/cart_badge_icon.dart';
import '../data/glasses_api.dart';
import '../models/glasses_item.dart';
import '../../auth/ui/profile_page.dart';
import '../../orders/models/order_item.dart';
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

// ═══════════════════════════════════════════════════════════════════
// PALETTE — Luxury Optical Tech
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const surface    = Color(0xFF111827);
  static const card       = Color(0xFF161F2E);
  static const cardBorder = Color(0xFF1E2D45);
  static const chrome     = Color(0xFFB8C8DC);
  static const chromeDim  = Color(0xFF6B8099);
  static const electric   = Color(0xFF00A8FF);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// HOME PAGE  —  navbar persistante via IndexedStack
// ═══════════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ── Contrôleurs & API originaux ────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final GlassesApi _glassesApi = const GlassesApi();

  final List<String> _categories = const [
    'All', 'New', 'Popular', 'Men', 'Women',
    'Unisex', 'Round', 'Square', 'Aviator',
  ];

  List<GlassesItem> _items            = [];
  bool              _isLoading        = true;
  String?           _error;
  String            _selectedCategory = 'All';
  String            _searchQuery      = '';
  final Set<int>    _favorites        = <int>{};

  // ── Index de navigation actif ──────────────────────────────────
  int _selectedNav = 0;

  // ── Animations ─────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double>   _pulseAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    CartController.instance.ensureLoaded();
    _fetchGlasses();
  }

  // ── Filtres originaux ──────────────────────────────────────────
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
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── _fetchGlasses original ─────────────────────────────────────
  Future<void> _fetchGlasses() async {
    setState(() { _error = null; _isLoading = true; });
    try {
      final List<GlassesItem> loaded = await _glassesApi.fetchGlasses();
      if (!mounted) return;
      setState(() { _items = loaded; });
      _entryCtrl.forward(from: 0);
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
      setState(() { _isLoading = false; });
    }
  }

  // ── Logique originale ──────────────────────────────────────────
  void _toggleFavorite(int id) {
    setState(() {
      _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    });
  }

  Future<void> _buyNow(GlassesItem item) async {
    await CartController.instance.ensureLoaded();
    await CartController.instance.addItem(
        OrderItem.fromGlasses(item, quantity: 1));
    if (!mounted) return;
    _showSnack('${item.name} added to cart',
        icon: Icons.check_circle_outline, color: _C.success);
  }

  Future<void> _openTryOn([GlassesItem? item]) async {
    final GlassesItem? selected =
        item ?? (_filteredItems.isNotEmpty ? _filteredItems.first : null);
    if (selected == null) {
      if (!mounted) return;
      _showSnack('No glasses available yet.', icon: Icons.info_outline);
      return;
    }
    try {
      final GlassesItem enriched =
          await _glassesApi.fetchTryOnPayload(selected);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TryOnPage(item: enriched)));
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _redirectToLogin(message: e.toString());
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not load try-on data.',
          icon: Icons.warning_amber_rounded, color: _C.warning);
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TryOnPage(item: selected)));
    }
  }

  Future<void> _redirectToLogin({String? message}) async {
    await TokenStore.instance.clearTokens();
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      _showSnack(message,
          icon: Icons.warning_amber_rounded, color: _C.error);
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showSnack(String msg,
      {IconData icon = Icons.info_outline, Color color = _C.electric}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _C.textPrim, fontSize: 13))),
      ]),
      backgroundColor: _C.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.6), width: 1)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      // ── AppBar ────────────────────────────────────────────────
      appBar: _buildAppBar(),

      // ── Corps : IndexedStack = navbar persistante ─────────────
      body: IndexedStack(
        index: _selectedNav,
        children: [
          // Tab 0 — Home
          _HomeTab(
            pulseAnim: _pulseAnim,
            fadeAnim: _fadeAnim,
            isLoading: _isLoading,
            error: _error,
            items: _items,
            filteredItems: _filteredItems,
            recentlyTried: _recentlyTried,
            categories: _categories,
            selectedCategory: _selectedCategory,
            searchQuery: _searchQuery,
            searchController: _searchController,
            favorites: _favorites,
            onRefresh: _fetchGlasses,
            onCategoryChanged: (c) => setState(() => _selectedCategory = c),
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onSearchClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            onToggleFavorite: _toggleFavorite,
            onTryOn: _openTryOn,
            onBuyNow: _buyNow,
          ),

          // Tab 1 — Try-On (placeholder inline, TryOnPage s'ouvre en push)
          _TryOnTab(onOpen: () => _openTryOn()),

          // Tab 2 — Explore
          const ExplorePage(),

          // Tab 3 — Favorites
          FavoritesPage(
            allItems: _items,
            favoriteIds: _favorites,
            onToggleFavorite: _toggleFavorite,
            onTryTap: _openTryOn,
          ),

          // Tab 4 — Profile
          const ProfilePage(),
        ],
      ),

      // ── Bottom Navigation persistante ─────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar custom ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1,
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, _C.electric, Colors.transparent]))),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: SizedBox(
          width: 32, height: 32,
          child: CustomPaint(painter: _MiniGlassesPainter()),
        ),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('VTON GLASSES', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 3)),
        Text('3D VIRTUAL TRY-ON', style: TextStyle(fontSize: 9,
            color: _C.electric, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1),
            color: _C.surface),
          child: const CartBadgeIcon(),
        ),
        _AppBarBtn(
          icon: Icons.notifications_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsPage())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Bottom Nav custom ─────────────────────────────────────────
  Widget _buildBottomNav() {
    final List<_NavItem> items = const [
      _NavItem(Icons.home_outlined,       Icons.home_rounded,       'Home'),
      _NavItem(Icons.videocam_outlined,   Icons.videocam_rounded,   'Try-On'),
      _NavItem(Icons.explore_outlined,    Icons.explore_rounded,    'Explore'),
      _NavItem(Icons.favorite_outline,    Icons.favorite_rounded,   'Favorites'),
      _NavItem(Icons.person_outline,      Icons.person_rounded,     'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.deepNavy,
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4),
              blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final _NavItem nav = items[i];
              final bool sel = _selectedNav == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedNav = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? _C.electric.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: sel
                        ? Border.all(
                            color: _C.electric.withOpacity(0.3), width: 1)
                        : null,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Icône Try-On = mini lunettes
                    if (i == 1)
                      SizedBox(width: 22, height: 11,
                        child: CustomPaint(painter: _MiniGlassesPainter(
                          color: sel ? _C.electric : _C.chromeDim)))
                    else
                      Icon(sel ? nav.filledIcon : nav.outlineIcon,
                          color: sel ? _C.electric : _C.chromeDim, size: 22),
                    const SizedBox(height: 4),
                    Text(nav.label, style: TextStyle(
                      fontSize: 10, letterSpacing: 0.3,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? _C.electric : _C.chromeDim)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 0 — HOME CONTENT
// ═══════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Animation<double> fadeAnim;
  final bool isLoading;
  final String? error;
  final List<GlassesItem> items;
  final List<GlassesItem> filteredItems;
  final List<GlassesItem> recentlyTried;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final TextEditingController searchController;
  final Set<int> favorites;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<int> onToggleFavorite;
  final Future<void> Function([GlassesItem?]) onTryOn;
  final Future<void> Function(GlassesItem) onBuyNow;

  const _HomeTab({
    required this.pulseAnim, required this.fadeAnim,
    required this.isLoading, required this.error,
    required this.items, required this.filteredItems,
    required this.recentlyTried, required this.categories,
    required this.selectedCategory, required this.searchQuery,
    required this.searchController, required this.favorites,
    required this.onRefresh, required this.onCategoryChanged,
    required this.onSearchChanged, required this.onSearchClear,
    required this.onToggleFavorite, required this.onTryOn,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double featuredCardWidth = width < 380 ? width * 0.72 : width * 0.62;

    return Stack(children: [
      // Grille hexagonale
      Positioned.fill(child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) =>
            CustomPaint(painter: _HexGridPainter(pulseAnim.value)),
      )),
      // Halo
      Positioned(top: -80, right: -60,
        child: Container(width: 280, height: 280,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _C.electric.withOpacity(0.08), Colors.transparent,
            ])),
        ),
      ),

      Positioned.fill(
        child: _buildBody(featuredCardWidth),
      ),
    ]);
  }

  Widget _buildLoading() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: const [
      SizedBox(width: 32, height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(_C.electric))),
      SizedBox(height: 14),
      Text('Chargement des lunettes…',
          style: TextStyle(color: _C.textSec, fontSize: 13, letterSpacing: 0.5)),
    ]));
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _C.electric, backgroundColor: _C.surface,
      child: ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 140),
          EmptyState(
            title: 'No glasses found',
            subtitle: 'Pull to refresh and try again.'),
        ],
      ),
    );
  }

  Widget _buildBody(double featuredCardWidth) {
    if (isLoading) return _buildLoading();
    if (error != null) return ErrorState(error: error!, onRetry: onRefresh);
    if (items.isEmpty) return _buildEmpty();

    return FadeTransition(
      opacity: fadeAnim,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: _C.electric,
        backgroundColor: _C.surface,
        child: ListView(
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            HeroCard(onStartTryOn: () => onTryOn()),
            const SizedBox(height: 18),

            _SearchBar(
              controller: searchController,
              query: searchQuery,
              onChanged: onSearchChanged,
              onClear: onSearchClear,
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 36,
              child: ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final String cat = categories[index];
                  final bool sel = cat == selectedCategory;
                  return _CategoryChip(
                    label: cat,
                    selected: sel,
                    onTap: () => onCategoryChanged(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            _SectionLabel(
              title: 'Featured Glasses',
              badge: '\${filteredItems.length} items',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: filteredItems.isEmpty
                  ? const EmptyState(
                      title: 'No glasses found',
                      subtitle: 'Try another search or category.')
                  : ListView.separated(
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final GlassesItem item = filteredItems[index];
                        final bool isFav = favorites.contains(item.id);
                        return FeaturedCard(
                          item: item,
                          width: featuredCardWidth,
                          isFavorite: isFav,
                          onTap: () => onTryOn(item),
                          onFavoriteTap: () => onToggleFavorite(item.id),
                          onTryTap: () => onTryOn(item),
                          onBuyTap: () => onBuyNow(item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 22),

            const _SectionLabel(title: 'Recently Tried'),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                itemCount: recentlyTried.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final GlassesItem item = recentlyTried[index];
                  return RecentTryCard(
                    item: item,
                    onTryAgain: () => onTryOn(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1 — TRY-ON PLACEHOLDER (la vraie page s'ouvre en push)
// ═══════════════════════════════════════════════════════════════════
class _TryOnTab extends StatelessWidget {
  final VoidCallback onOpen;
  const _TryOnTab({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.35),
                blurRadius: 24, offset: const Offset(0, 8))]),
          child: const Icon(Icons.videocam_rounded,
              color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('3D Virtual Try-On',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: _C.textPrim, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        const Text('Essayez vos lunettes en réalité augmentée',
            style: TextStyle(fontSize: 13, color: _C.textSec),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0078CC), _C.electric, Color(0xFF00C8FF)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.35),
                  blurRadius: 20, offset: const Offset(0, 6))]),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('LANCER LE TRY-ON',
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800, letterSpacing: 2)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════

class _AppBarBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _C.surface, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border, width: 1)),
        child: Icon(icon, color: _C.chrome, size: 18),
      ),
    );
  }
}

// ── Barre de recherche ────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.query,
      required this.onChanged, required this.onClear});

  @override State<_SearchBar> createState() => _SearchBarState();
}
class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused ? [BoxShadow(
              color: _C.electric.withOpacity(0.16), blurRadius: 16,
              spreadRadius: 2)] : []),
        child: TextField(
          controller: widget.controller,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: _C.textPrim, fontSize: 14),
          cursorColor: _C.electric,
          onChanged: widget.onChanged,
          onSubmitted: widget.onChanged,
          decoration: InputDecoration(
            hintText: 'Search by frame, brand, style…',
            hintStyle: const TextStyle(color: Color(0xFF3A4A5A), fontSize: 14),
            prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded,
                  color: _focused ? _C.electric : _C.chromeDim, size: 20)),
            suffixIcon: widget.query.isNotEmpty
                ? GestureDetector(onTap: widget.onClear,
                    child: const Padding(padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.close_rounded,
                          color: _C.chromeDim, size: 18)))
                : null,
            filled: true, fillColor: _C.deepNavy,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _C.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _C.border, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _C.electric, width: 1.5)),
          ),
        ),
      ),
    );
  }
}

// ── Chip catégorie ────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(
              colors: [Color(0xFF0078CC), _C.electric],
              begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
          color: selected ? null : _C.deepNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _C.electric.withOpacity(0.5) : _C.border,
              width: 1),
          boxShadow: selected ? [BoxShadow(
              color: _C.electric.withOpacity(0.25), blurRadius: 10,
              offset: const Offset(0, 2))] : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : _C.textSec,
          letterSpacing: 0.3)),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title; final String? badge;
  const _SectionLabel({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.electric, Color(0xFF0070B8)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: _C.textPrim, letterSpacing: 0.3)),
      const Spacer(),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _C.electric.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.electric.withOpacity(0.3), width: 1)),
          child: Text(badge!, style: const TextStyle(fontSize: 10,
              color: _C.electric, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
    ]);
  }
}

// ── NavItem data class ────────────────────────────────────────────
class _NavItem {
  final IconData outlineIcon, filledIcon;
  final String label;
  const _NavItem(this.outlineIcon, this.filledIcon, this.label);
}

// ── Mini lunettes logo ────────────────────────────────────────────
class _MiniGlassesPainter extends CustomPainter {
  final Color color;
  const _MiniGlassesPainter({this.color = _C.electric});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final fp = Paint()
      ..shader = LinearGradient(colors: [_C.chrome, color, _C.chrome],
        begin: Alignment.centerLeft, end: Alignment.centerRight)
        .createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 ..strokeCap = StrokeCap.round;

    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, h * .05, w * .40, h * .88),
        const Radius.circular(5)), fp);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .58, h * .05, w * .40, h * .88),
        const Radius.circular(5)), fp);
    canvas.drawPath(
      Path()..moveTo(w*.42,h*.35)
        ..cubicTo(w*.46,h*.12,w*.54,h*.12,w*.58,h*.35),
      Paint()..color=_C.chrome..style=PaintingStyle.stroke
        ..strokeWidth=1.4..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(w/2, h*.5), 1.5,
        Paint()..color = color);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Grille hexagonale ─────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.electric.withOpacity(0.018 * opacity)
      ..style = PaintingStyle.stroke ..strokeWidth = 0.5;
    const r = 40.0; const dx = r * 1.732; const dy = r * 1.5;
    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final off = (row % 2 == 0) ? 0.0 : dx / 2;
      for (double x = -r + off; x < size.width + r; x += dx) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (pi / 180) * (60 * i - 30);
          final pt = Offset(x + r * cos(a), y + r * sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close(); canvas.drawPath(path, paint);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}