import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/instrument.dart';
import '../models/stage.dart';
import '../models/studio.dart';
import '../services/api_service.dart';
import 'instrument_details.dart';
import 'stage_details.dart';
import 'studio_details.dart';
import 'instruments.dart';
import 'stages.dart';
import 'studios.dart';
import 'conversations_screen.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isLoading = false;
  late TabController _catalogTabController;

  List<Map<String, dynamic>> _instruments = [];
  List<Map<String, dynamic>> _stages = [];
  List<Map<String, dynamic>> _studios = [];

  static const _bg = Color(0xFF1A1A2E);
  static const _card = Color(0xFF16213E);
  static const _accent = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  @override
  void initState() {
    super.initState();
    _catalogTabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _catalogTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAllInstruments(),
        ApiService.getAllStages(),
        ApiService.getAllStudios(),
      ]);
      setState(() {
        _instruments = List<Map<String, dynamic>>.from(results[0]['instruments'] ?? []);
        _stages = List<Map<String, dynamic>>.from(results[1]['stages'] ?? []);
        _studios = List<Map<String, dynamic>>.from(results[2]['studios'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _absoluteUrl(String url) {
    if (url.isEmpty || url.startsWith('http')) return url;
    return 'https://rentmuss-production.up.railway.app$url';
  }

  Widget _getSelectedScreen() {
    switch (_currentIndex) {
      case 1: return _buildCatalogScreen();
      case 2: return const ConversationsScreen();
      case 3: return const ProfileScreen();
      default: return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: _getSelectedScreen()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x77E94560),
                  Color(0xFFE94560),
                  Color(0x77E94560),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: _accent,
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Басты бет'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'Каталог'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Хабарламалар'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Профиль'),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CATALOG SCREEN
  // ─────────────────────────────────────────────
  Widget _buildCatalogScreen() {
    const tabIcons = [Icons.piano_rounded, Icons.theater_comedy_rounded, Icons.mic_rounded];
    const tabLabels = ['Аспаптар', 'Сахналар', 'Студиялар'];

    return Column(
      children: [
        Container(
          color: _card,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: AnimatedBuilder(
            animation: _catalogTabController.animation!,
            builder: (context, _) {
              final idx = _catalogTabController.index;
              return Row(
                children: List.generate(3, (i) {
                  final active = i == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _catalogTabController.animateTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(
                                  colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: active ? null : _bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? const Color(0xFFE94560)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE94560).withValues(alpha: 0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tabIcons[i],
                              color: active ? Colors.white : Colors.white38,
                              size: 18,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tabLabels[i],
                              style: TextStyle(
                                color: active ? Colors.white : Colors.white38,
                                fontSize: 11,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        Container(
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x77E94560),
                Color(0xFFE94560),
                Color(0x77E94560),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _catalogTabController,
            children: const [
              InstrumentsScreen(),
              StagesScreen(),
              StudiosScreen(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  HOME CONTENT
  // ─────────────────────────────────────────────
  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroHeader()),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator(color: _accent)),
                )
              : (_instruments.isEmpty && _stages.isEmpty && _studios.isEmpty)
                  ? _buildEmptyState()
                  : _buildSections(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ── Hero header ──────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Stack(
        children: [
          // Background music notes decoration
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.music_note, size: 100, color: Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            right: 40,
            bottom: 0,
            child: Icon(Icons.queue_music, size: 70, color: Colors.white.withValues(alpha: 0.04)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.headphones, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'RentMus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Аспаптар, сахналар және студияларды жалға алыңыз',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7)),
                tooltip: 'Жаңарту',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
              const SizedBox(width: 12),
              Text(
                'Аспаптар, сахналар, студиялар...',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sections ─────────────────────────────────
  Widget _buildSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_instruments.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildSectionHeader('🎸 Аспаптар', 0),
          const SizedBox(height: 14),
          _buildHorizontalList(_instruments, 'instrument', 0),
        ],
        if (_stages.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildSectionHeader('🎭 Сахналар', 1),
          const SizedBox(height: 14),
          _buildHorizontalList(_stages, 'stage', 1),
        ],
        if (_studios.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildSectionHeader('🎤 Студиялар', 2),
          const SizedBox(height: 14),
          _buildHorizontalList(_studios, 'studio', 2),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int catalogTab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              _catalogTabController.animateTo(catalogTab);
              setState(() => _currentIndex = 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Барлығы', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: _accent, size: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> items, String type, int catalogTab) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final urls = (item['imageUrls'] as List?)?.cast<String>() ?? [];
          final imageUrl = urls.isNotEmpty ? _absoluteUrl(urls[0]) : '';
          final name = item['name'] ?? '';
          final price = (item['pricePerHour'] ?? 0).toDouble();
          final location = item['location'] ?? '';
          final rating = (item['rating'] ?? 0).toDouble();
          return _buildItemCard(
            imageUrl: imageUrl,
            name: name,
            price: price,
            location: location,
            rating: rating,
            type: type,
            onTap: () {
              try {
                if (type == 'instrument') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => InstrumentDetailsScreen(instrument: Instrument.fromJson(item)),
                  ));
                } else if (type == 'stage') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StageDetailsScreen(stage: Stage.fromJson(item)),
                  ));
                } else {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudioDetailsScreen(studio: Studio.fromJson(item)),
                  ));
                }
              } catch (_) {
                _catalogTabController.animateTo(catalogTab);
                setState(() => _currentIndex = 1);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildItemCard({
    required String imageUrl,
    required String name,
    required double price,
    required String location,
    required double rating,
    required String type,
    required VoidCallback onTap,
  }) {
    final typeIcon = type == 'instrument' ? Icons.piano : type == 'stage' ? Icons.theater_comedy : Icons.mic;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _card,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Image
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 240,
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _cardPlaceholder(typeIcon),
                  errorWidget: (_, __, ___) => _cardPlaceholder(typeIcon),
                )
              else
                _cardPlaceholder(typeIcon),

              // Bottom gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    ),
                  ),
                ),
              ),

              // Rating chip top-right
              if (rating > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom info
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white60, size: 11),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${price.toInt()} ₸/сағ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardPlaceholder(IconData icon) {
    return Container(
      height: 240,
      width: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
        ),
      ),
      child: Icon(icon, color: Colors.white24, size: 60),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_off_outlined, size: 56, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            'Әзірге ештеңе жоқ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Сатушылар мазмұн қосқанда мұнда пайда болады',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: _accent, size: 18),
                  SizedBox(width: 8),
                  Text('Жаңарту', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
