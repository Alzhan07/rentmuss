import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/studio.dart';
import '../services/api_service.dart';
import 'studio_details.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen>
    with SingleTickerProviderStateMixin {
  List<Studio> _allStudios = [];
  List<Studio> _filteredStudios = [];
  bool _isLoading = false;
  bool _isGridView = false;

  String _searchQuery = '';
  String _selectedType = 'Барлығы';
  String _sortBy = 'popular';

  final TextEditingController _searchController = TextEditingController();

  static const _bg      = Color(0xFF1A1A2E);
  static const _card    = Color(0xFF16213E);
  static const _accent  = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);
  static const _teal    = Color(0xFF00D9A5);

  static const _typeToDb = {
    'Дыбыс жазу': 'recording',
    'Репетиция':  'rehearsal',
    'Подкасттар': 'podcast',
    'Стриминг':   'live_streaming',
    'Мәлімет':    'mixing',
  };
  static const _dbToLabel = {
    'recording':     'Дыбыс жазу',
    'rehearsal':     'Репетиция',
    'podcast':       'Подкасттар',
    'live_streaming':'Стриминг',
    'mixing':        'Мәлімет',
  };

  final List<Map<String, dynamic>> _types = [
    {'name': 'Барлығы',    'icon': Icons.apps},
    {'name': 'Дыбыс жазу', 'icon': Icons.mic},
    {'name': 'Репетиция',  'icon': Icons.music_note},
    {'name': 'Подкасттар', 'icon': Icons.podcasts},
    {'name': 'Стриминг',  'icon': Icons.live_tv},
    {'name': 'Мәлімет',   'icon': Icons.equalizer},
  ];

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllStudios(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (response['success'] == true) {
        final studiosData = response['studios'] as List;
        final serverStudios = studiosData
            .map((data) {
              try { return Studio.fromJson(data as Map<String, dynamic>); }
              catch (e) { debugPrint('Studio parse error: $e'); return null; }
            })
            .whereType<Studio>()
            .toList();
        setState(() {
          _allStudios = serverStudios;
          _filteredStudios = serverStudios;
          _isLoading = false;
        });
      } else {
        setState(() { _allStudios = []; _filteredStudios = []; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Error loading studios: $e');
      setState(() { _allStudios = []; _filteredStudios = []; _isLoading = false; });
    }
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredStudios = _allStudios.where((studio) {
        final dbType = _typeToDb[_selectedType];
        final matchType = _selectedType == 'Барлығы' || studio.type == dbType;
        final q = _searchQuery.toLowerCase();
        final matchSearch = q.isEmpty ||
            studio.name.toLowerCase().contains(q) ||
            studio.description.toLowerCase().contains(q) ||
            studio.equipment.toLowerCase().contains(q);
        return matchType && matchSearch;
      }).toList();

      switch (_sortBy) {
        case 'price_low':  _filteredStudios.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour)); break;
        case 'price_high': _filteredStudios.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour)); break;
        case 'rating':     _filteredStudios.sort((a, b) => b.rating.compareTo(a.rating)); break;
        default:           _filteredStudios.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
      }
    });
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':  return 'Баға ↑';
      case 'price_high': return 'Баға ↓';
      case 'rating':     return 'Рейтинг';
      default:           return 'Танымал';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildTypeFilters(),
            const SizedBox(height: 14),
            _buildSortRow(),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _filteredStudios.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                          ? _buildGridView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic_outlined, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Студиялар',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Жазу, репетиция, өндіріс',
                    style: TextStyle(color: _accent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ───────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
          decoration: InputDecoration(
            hintText: 'Студияларды іздеу...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.4), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Type chips ───────────────────────────────
  Widget _buildTypeFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type['name'];
          return GestureDetector(
            onTap: () { setState(() => _selectedType = type['name'] as String); _loadStudios(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [_accent, Color(0xFFFF6B85)])
                    : null,
                color: isSelected ? null : _surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type['icon'] as IconData, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    type['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sort row ─────────────────────────────────
  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredStudios.length} нәтиже',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (v) { setState(() => _sortBy = v); _applyFilters(); },
                color: _card,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(_getSortLabel(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'popular',    child: Text('Танымал',      style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'price_low',  child: Text('Баға: төмен',  style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'price_high', child: Text('Баға: жоғары', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'rating',     child: Text('Рейтинг',      style: TextStyle(color: Colors.white))),
                ],
              ),
              const SizedBox(width: 8),
              _viewToggleBtn(Icons.view_list_rounded, !_isGridView, () => setState(() => _isGridView = false)),
              const SizedBox(width: 4),
              _viewToggleBtn(Icons.grid_view_rounded, _isGridView, () => setState(() => _isGridView = true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? _accent.withValues(alpha: 0.2) : _surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _accent.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Icon(icon, color: active ? _accent : Colors.white38, size: 18),
      ),
    );
  }

  // ── List ─────────────────────────────────────
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStudios.length,
      itemBuilder: (ctx, i) => _listCard(_filteredStudios[i]),
    );
  }

  Widget _listCard(Studio studio) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => StudioDetailsScreen(studio: studio))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: studio.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: studio.imageUrls[0],
                      width: 110,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imgPlaceholder(110, 130),
                      errorWidget: (_, __, ___) => _imgPlaceholder(110, 130),
                    )
                  : _imgPlaceholder(110, 130),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _accent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            (_dbToLabel[studio.type] ?? studio.type).toUpperCase(),
                            style: const TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (studio.hasEngineer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _teal.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.engineering, color: _teal, size: 10),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 13),
                        const SizedBox(width: 3),
                        Text(studio.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(studio.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(_dbToLabel[studio.type] ?? studio.type,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.35), size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(studio.location,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${studio.pricePerHour.toInt()} ₸',
                              style: const TextStyle(color: _accent, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '/сағ',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios, color: _accent, size: 10),
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
    );
  }

  // ── Grid ─────────────────────────────────────
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredStudios.length,
      itemBuilder: (ctx, i) => _gridCard(_filteredStudios[i]),
    );
  }

  Widget _gridCard(Studio studio) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => StudioDetailsScreen(studio: studio))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _card,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              studio.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: studio.imageUrls[0],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imgPlaceholder(double.infinity, double.infinity),
                      errorWidget: (_, __, ___) => _imgPlaceholder(double.infinity, double.infinity),
                    )
                  : _imgPlaceholder(double.infinity, double.infinity),

              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.88)],
                  ),
                ),
              ),

              // Engineer badge top-left
              if (studio.hasEngineer)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.engineering, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text('Инженер',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

              // Rating top-right
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                      const SizedBox(width: 3),
                      Text(studio.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Bottom info
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studio.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(studio.type,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
                            child: Text('${studio.pricePerHour.toInt()} ₸',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 9),
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

  // ── Empty state ──────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 50, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          Text('Студиялар табылмады',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Фильтрлерді өзгертіп көріңіз',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────
  Widget _imgPlaceholder(double w, double h) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h == double.infinity ? null : h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
        ),
      ),
      child: const Icon(Icons.mic_outlined, color: Colors.white24, size: 40),
    );
  }
}
