import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedType = 'all';
              break;
            case 1:
              _selectedType = 'instrument';
              break;
            case 2:
              _selectedType = 'stage';
              break;
            case 3:
              _selectedType = 'studio';
              break;
          }
          _loadFavorites();
        });
      }
    });
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getFavorites(
      type: _selectedType == 'all' ? null : _selectedType,
    );
    setState(() {
      _favorites = result['favorites'] ?? [];
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(Map<String, dynamic> favorite) async {
    final result = await ApiService.removeFromFavorites(
      itemType: favorite['itemType'],
      itemId: favorite['itemId'],
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Удалено из избранного'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    if (result['success']) {
      await _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text(
          'Таңдаулылар',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFavorites,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Инструменты'),
            Tab(text: 'Сцены'),
            Tab(text: 'Студии'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE94560)),
              )
              : _favorites.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Таңдаулылар жоқ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Таңдаулыларға бірдеңе қосыңыз',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  return _buildFavoriteCard(favorite);
                },
              ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    final itemData = favorite['itemData'] as Map<String, dynamic>? ?? {};
    final itemType = favorite['itemType'] as String? ?? '';

    final name = itemData['name'] as String? ?? 'Без названия';
    final description = itemData['description'] as String? ?? '';
    final images = (itemData['images'] as List?)?.cast<String>() ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final pricePerHour = (itemData['pricePerHour'] as num?)?.toDouble() ?? 0.0;
    final pricePerDay = (itemData['pricePerDay'] as num?)?.toDouble();
    final rating = (itemData['rating'] as num?)?.toDouble() ?? 0.0;
    final location = itemData['location'] as String? ?? '';
    final category = itemData['category'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 180,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFE94560),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 180,
                            color: const Color(0xFF0F3460),
                            child: Icon(
                              _getTypeIcon(itemType),
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                    )
                    : Container(
                      height: 180,
                      color: const Color(0xFF0F3460),
                      child: Center(
                        child: Icon(
                          _getTypeIcon(itemType),
                          color: const Color(0xFFE94560),
                          size: 60,
                        ),
                      ),
                    ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(favorite),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE94560),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTypeLabel(itemType),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rating > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getCategoryText(category),
                      style: TextStyle(
                        color: const Color(0xFFE94560).withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pricePerHour > 0)
                            Text(
                              '${pricePerHour.toInt()} ₸/час',
                              style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (pricePerDay != null && pricePerDay > 0)
                            Text(
                              '${pricePerDay.toInt()} ₸/день',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to detail page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Брондау'),
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'instrument':
        return Icons.music_note;
      case 'stage':
        return Icons.theater_comedy;
      case 'studio':
        return Icons.mic;
      default:
        return Icons.category;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'stage':
        return 'Сахна';
      case 'instrument':
        return 'Аспаптар';
      case 'studio':
        return 'Студиялар';
      default:
        return type;
    }
  }

  String _getCategoryText(String category) {
    // Translate category names
    final categoryMap = {
      'Гитары': 'Гитары',
      'Клавишные': 'Клавишные',
      'Ударные': 'Ударные',
      'Духовые': 'Духовые',
      'Струнные': 'Струнные',
      'Бас': 'Бас',
    };
    return categoryMap[category] ?? category;
  }
}
