import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'add_instrument.dart';
import 'add_stage.dart';
import 'add_studio.dart';

class SellerScreen extends StatefulWidget {
  const SellerScreen({Key? key}) : super(key: key);

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _instruments = [];
  List<dynamic> _stages = [];
  List<dynamic> _studios = [];

  bool _isLoadingInstruments = true;
  bool _isLoadingStages = true;
  bool _isLoadingStudios = true;

  String _shopName = 'Менің дүкенім';
  String _shopDescription = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadInstruments(),
      _loadStages(),
      _loadStudios(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getUserProfile();
      if (result['success'] == true && result['user'] != null) {
        final sellerInfo = result['user']['sellerInfo'];
        if (sellerInfo != null && mounted) {
          setState(() {
            _shopName = sellerInfo['shopName'] ?? 'Менің дүкенім';
            _shopDescription = sellerInfo['shopDescription'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadInstruments() async {
    setState(() => _isLoadingInstruments = true);
    try {
      final response = await ApiService.getMyInstruments();
      if (mounted) {
        setState(() {
          _instruments = response['success'] == true
              ? (response['instruments'] ?? [])
              : [];
          _isLoadingInstruments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInstruments = false);
    }
  }

  Future<void> _loadStages() async {
    setState(() => _isLoadingStages = true);
    try {
      final response = await ApiService.getMyStages();
      if (mounted) {
        setState(() {
          _stages = response['success'] == true
              ? (response['stages'] ?? [])
              : [];
          _isLoadingStages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStages = false);
    }
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoadingStudios = true);
    try {
      final response = await ApiService.getMyStudios();
      if (mounted) {
        setState(() {
          _studios = response['success'] == true
              ? (response['studios'] ?? [])
              : [];
          _isLoadingStudios = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudios = false);
    }
  }

  Future<void> _deleteItem({
    required String id,
    required String label,
    required Future<Map<String, dynamic>> Function(String) deleteFn,
    required VoidCallback onSuccess,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Жою', style: TextStyle(color: Colors.white)),
        content: Text(
          '$label жойылсын ба?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Бас тарту',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Жою'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await deleteFn(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['success'] == true ? '$label жойылды' : 'Қате: ${response['message']}',
          ),
          backgroundColor:
              response['success'] == true ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (response['success'] == true) onSuccess();
    }
  }

  String _absoluteUrl(String url) {
    if (url.isEmpty || url.startsWith('http')) return url;
    return 'https://rentmuss-production.up.railway.app$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeader()),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInstrumentsList(),
                  _buildStagesList(),
                  _buildStudiosList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + refresh
              Row(
                children: [
                  _iconBtn(
                    Icons.arrow_back_ios_new,
                    () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _iconBtn(Icons.refresh_rounded, _loadAll),
                ],
              ),
              const SizedBox(height: 20),

              // Shop identity
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE94560),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFE94560),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (_shopDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _shopDescription,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _buildStat(Icons.piano_rounded, _instruments.length, 'Аспап'),
                  const SizedBox(width: 10),
                  _buildStat(Icons.theater_comedy_rounded, _stages.length, 'Сахна'),
                  const SizedBox(width: 10),
                  _buildStat(Icons.mic_rounded, _studios.length, 'Студия'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE94560), size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── TAB BAR ─────────────────

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFFE94560),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Аспаптар'),
            Tab(text: 'Сахналар'),
            Tab(text: 'Студиялар'),
          ],
        ),
      ),
    );
  }

  // ───────────────── FAB ─────────────────

  Widget _buildFab() {
    const labels = ['Аспап қосу', 'Сахна қосу', 'Студия қосу'];
    const routes = ['/add-instrument', '/add-stage', '/add-studio'];
    const icons = [Icons.piano_rounded, Icons.theater_comedy_rounded, Icons.mic_rounded];
    final idx = _tabController.index;

    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, routes[idx]);
        if (result == true) _loadAll();
      },
      backgroundColor: const Color(0xFFE94560),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: Icon(icons[idx]),
      label: Text(labels[idx],
          style: const TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // ───────────────── LISTS ─────────────────

  Widget _buildInstrumentsList() {
    if (_isLoadingInstruments) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94560)),
      );
    }
    if (_instruments.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.piano_rounded,
        message: 'Аспаптар жоқ',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadInstruments,
      color: const Color(0xFFE94560),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _instruments.length,
        itemBuilder: (context, index) {
          final item = _instruments[index];
          final id = item['_id'] is String
              ? item['_id']
              : item['_id']?['\$oid'];
          return _buildItemCard(
            item: item,
            icon: Icons.piano_rounded,
            subtitle: '${item['brand'] ?? ''} • ${item['category'] ?? ''}',
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddInstrumentScreen(instrument: item),
                ),
              );
              if (result == true) _loadInstruments();
            },
            onDelete: () => _deleteItem(
              id: id,
              label: item['name'] ?? 'Аспап',
              deleteFn: ApiService.deleteInstrument,
              onSuccess: _loadInstruments,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStagesList() {
    if (_isLoadingStages) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94560)),
      );
    }
    if (_stages.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.theater_comedy_rounded,
        message: 'Сахналар жоқ',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadStages,
      color: const Color(0xFFE94560),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final item = _stages[index];
          final id = item['_id'] is String
              ? item['_id']
              : item['_id']?['\$oid'];
          return _buildItemCard(
            item: item,
            icon: Icons.theater_comedy_rounded,
            subtitle: '${item['location'] ?? ''} • ${item['capacity'] ?? ''} адам',
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStageScreen(stage: item),
                ),
              );
              if (result == true) _loadStages();
            },
            onDelete: () => _deleteItem(
              id: id,
              label: item['name'] ?? 'Сахна',
              deleteFn: ApiService.deleteStage,
              onSuccess: _loadStages,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudiosList() {
    if (_isLoadingStudios) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94560)),
      );
    }
    if (_studios.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.mic_rounded,
        message: 'Студиялар жоқ',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadStudios,
      color: const Color(0xFFE94560),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _studios.length,
        itemBuilder: (context, index) {
          final item = _studios[index];
          final id = item['_id'] is String
              ? item['_id']
              : item['_id']?['\$oid'];
          return _buildItemCard(
            item: item,
            icon: Icons.mic_rounded,
            subtitle: '${item['location'] ?? ''} • ${item['areaSquareMeters'] ?? ''} м²',
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStudioScreen(studio: item),
                ),
              );
              if (result == true) _loadStudios();
            },
            onDelete: () => _deleteItem(
              id: id,
              label: item['name'] ?? 'Студия',
              deleteFn: ApiService.deleteStudio,
              onSuccess: _loadStudios,
            ),
          );
        },
      ),
    );
  }

  // ───────────────── ITEM CARD ─────────────────

  Widget _buildItemCard({
    required dynamic item,
    required IconData icon,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final urls = (item['imageUrls'] as List?)?.cast<String>() ?? [];
    final imageUrl = urls.isNotEmpty ? _absoluteUrl(urls[0]) : '';
    final price = item['pricePerHour'];
    final name = item['name'] ?? 'Атауы жоқ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(icon),
                        errorWidget: (_, __, ___) => _imagePlaceholder(icon),
                      )
                    : _imagePlaceholder(icon),
                // Bottom gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                // Price chip
                if (price != null)
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$price ₸/сағат',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      _actionBtn(
                        Icons.edit_outlined,
                        const Color(0xFF4FC3F7),
                        onEdit,
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        Icons.delete_outline_rounded,
                        const Color(0xFFE94560),
                        onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _imagePlaceholder(IconData icon) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
        ),
      ),
      child: Icon(icon, color: Colors.white12, size: 52),
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, size: 52, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"+" батырмасын басып қосыңыз',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
