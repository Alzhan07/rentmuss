import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/instrument.dart';
import '../services/api_service.dart';
import 'instrument_details.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen>
    with TickerProviderStateMixin {

  // ─── Data ────────────────────────────────────────────────────────────────
  List<Instrument> _allInstruments      = [];
  List<Instrument> _filteredInstruments = [];
  bool _isLoading  = false;
  bool _isGridView = false;

  String _searchQuery       = '';
  String _selectedCategory  = 'Барлығы';
  String _sortBy            = 'popular';

  final TextEditingController _searchController = TextEditingController();

  // ─── Animation controllers ───────────────────────────────────────────────
  late AnimationController _staggerCtrl;   // card entrance
  late AnimationController _shimmerCtrl;   // skeleton shimmer

  // ─── Theme ───────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1A1A2E);
  static const _card    = Color(0xFF16213E);
  static const _accent  = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  // ─── Categories ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Барлығы',     'icon': Icons.apps},
    {'name': 'Гитаралар',   'icon': Icons.music_note},
    {'name': 'Пернетақталы','icon': Icons.piano},
    {'name': 'Ұрмалы',      'icon': Icons.album},
    {'name': 'Үрмелі',      'icon': Icons.graphic_eq},
    {'name': 'Шекті',       'icon': Icons.music_note_outlined},
    {'name': 'Бас',         'icon': Icons.headphones},
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadInstruments();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _shimmerCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadInstruments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllInstruments(
        category: _selectedCategory != 'Барлығы' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (response['success'] == true) {
        final list = (response['instruments'] as List)
            .map((d) => Instrument.fromJson(d))
            .toList();
        setState(() {
          _allInstruments      = list;
          _filteredInstruments = list;
          _isLoading           = false;
        });
        _staggerCtrl.forward(from: 0);
      } else {
        setState(() {
          _allInstruments = _filteredInstruments = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _allInstruments = _filteredInstruments = [];
        _isLoading = false;
      });
    }
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredInstruments = _allInstruments.where((i) {
        final matchCat    = _selectedCategory == 'Барлығы' || i.category == _selectedCategory;
        final q           = _searchQuery.toLowerCase();
        final matchSearch = q.isEmpty ||
            i.name.toLowerCase().contains(q) ||
            i.brand.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q);
        return matchCat && matchSearch;
      }).toList();

      switch (_sortBy) {
        case 'price_low':  _filteredInstruments.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour)); break;
        case 'price_high': _filteredInstruments.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour)); break;
        case 'rating':     _filteredInstruments.sort((a, b) => b.rating.compareTo(a.rating)); break;
        default:           _filteredInstruments.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
      }
    });
    _staggerCtrl.forward(from: 0);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _conditionColor(String c) {
    switch (c) {
      case 'Керемет':        return const Color(0xFF4CAF50);
      case 'Жақсы':          return const Color(0xFF2196F3);
      case 'Қанағаттанарлық':return const Color(0xFFFF9800);
      default:               return Colors.grey;
    }
  }

  String _conditionLabel(String c) {
    switch (c) {
      case 'Керемет':        return 'КЕРЕМЕТ';
      case 'Жақсы':          return 'ЖАҚСЫ';
      case 'Қанағаттанарлық':return 'ОРТАША';
      default:               return c.toUpperCase();
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':  return 'Баға ↑';
      case 'price_high': return 'Баға ↓';
      case 'rating':     return 'Рейтинг';
      default:           return 'Танымал';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
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
            _buildCategoryFilters(),
            const SizedBox(height: 14),
            _buildSortRow(),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
                  : _filteredInstruments.isEmpty
                      ? _buildEmptyState()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                          child: _isGridView
                              ? _buildGridView(key: const ValueKey('grid'))
                              : _buildListView(key: const ValueKey('list')),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
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
            child: const Icon(Icons.piano, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Аспаптар',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Мінсіз аспапты табыңыз',
                    style: TextStyle(color: _accent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────
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
          onChanged: (v) {
            setState(() => _searchQuery = v);
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Аспаптарды іздеу...',
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

  // ─── Category chips ───────────────────────────────────────────────────────
  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, index) {
          final cat        = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat['name'] as String);
              _loadInstruments();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [_accent, Color(0xFFFF6B85)])
                    : null,
                color: isSelected ? null : _surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'] as IconData, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Sort row ─────────────────────────────────────────────────────────────
  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredInstruments.length} нәтиже',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (v) {
                  setState(() => _sortBy = v);
                  _applyFilters();
                },
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
                  const PopupMenuItem(value: 'popular',    child: Text('Танымал',     style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'price_low',  child: Text('Баға: төмен', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'price_high', child: Text('Баға: жоғары',style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'rating',     child: Text('Рейтинг',     style: TextStyle(color: Colors.white))),
                ],
              ),
              const SizedBox(width: 8),
              _viewToggleBtn(Icons.view_list_rounded, !_isGridView, () => setState(() => _isGridView = false)),
              const SizedBox(width: 4),
              _viewToggleBtn(Icons.grid_view_rounded, _isGridView,  () => setState(() => _isGridView = true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  // ─── Shimmer skeleton ─────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, __) {
          final t = _shimmerCtrl.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (t - 0.4).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.4).clamp(0.0, 1.0),
                ],
                colors: const [
                  Color(0xFF16213E),
                  Color(0xFF1F2F50),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft:    Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(0.6),
                      const SizedBox(height: 8),
                      _shimmerLine(0.4),
                      const SizedBox(height: 8),
                      _shimmerLine(0.35),
                      const SizedBox(height: 14),
                      _shimmerLine(0.25),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerLine(double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  // ─── Stagger wrapper ──────────────────────────────────────────────────────
  Widget _staggered(int index, Widget child) {
    final maxVisible = 10;
    final stagger     = (index / maxVisible).clamp(0.0, 0.6);
    final end         = (stagger + 0.55).clamp(0.0, 1.0);
    final animation   = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(stagger, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (_, ch) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  // ─── List view ────────────────────────────────────────────────────────────
  Widget _buildListView({Key? key}) {
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredInstruments.length,
      itemBuilder: (_, i) => _staggered(i, _PressCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstrumentDetailsScreen(instrument: _filteredInstruments[i]),
          ),
        ),
        child: _listCardContent(_filteredInstruments[i]),
      )),
    );
  }

  Widget _listCardContent(Instrument inst) {
    final condColor = _conditionColor(inst.condition);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft:    Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: inst.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: inst.imageUrls[0],
                    width:  110,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: condColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: condColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _conditionLabel(inst.condition),
                          style: TextStyle(color: condColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        inst.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inst.name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${inst.brand} · ${inst.model}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.35), size: 12),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        inst.location,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '${inst.pricePerHour.toInt()} ₸',
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
    );
  }

  // ─── Grid view ────────────────────────────────────────────────────────────
  Widget _buildGridView({Key? key}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   2,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredInstruments.length,
      itemBuilder: (_, i) => _staggered(i, _PressCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstrumentDetailsScreen(instrument: _filteredInstruments[i]),
          ),
        ),
        child: _gridCardContent(_filteredInstruments[i]),
      )),
    );
  }

  Widget _gridCardContent(Instrument inst) {
    final condColor = _conditionColor(inst.condition);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _card,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            inst.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: inst.imageUrls[0],
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

            // Condition badge
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: condColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _conditionLabel(inst.condition),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Rating
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
                    Text(inst.rating.toStringAsFixed(1),
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
                    Text(
                      inst.name,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inst.brand,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${inst.pricePerHour.toInt()} ₸',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
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
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 50, color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Аспаптар табылмады',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Фильтрлерді өзгертіп көріңіз',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _imgPlaceholder(double w, double h) {
    return Container(
      width:  w == double.infinity ? null : w,
      height: h == double.infinity ? null : h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 40),
    );
  }
}

// ─── Press-scale card wrapper ─────────────────────────────────────────────────
class _PressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressCard({required this.child, required this.onTap});

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve:    Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
