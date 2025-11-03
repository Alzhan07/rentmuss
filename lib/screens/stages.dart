import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/stage.dart';
import '../services/api_service.dart';
import 'stage_details.dart';

class StagesScreen extends StatefulWidget {
  const StagesScreen({super.key});

  @override
  State<StagesScreen> createState() => _StagesScreenState();
}

class _StagesScreenState extends State<StagesScreen> {
  List<Stage> _allStages = [];
  List<Stage> _filteredStages = [];
  bool _isLoading = false;
  bool _isGridView = false;

  String _searchQuery = '';
  String _selectedType = 'Все';
  String _sortBy = 'popular';
  int _minCapacity = 0;
  int _maxCapacity = 10000;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {'name': 'Барлығы', 'icon': Icons.apps},
    {'name': 'Концерттік', 'icon': Icons.music_note},
    {'name': 'Театралды', 'icon': Icons.theater_comedy},
    {'name': 'Клубтық', 'icon': Icons.nightlife},
    {'name': 'Ашық', 'icon': Icons.wb_sunny},
    {'name': 'Кіші', 'icon': Icons.people_outline},
    {'name': 'Үлкен', 'icon': Icons.groups},
  ];

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final sampleStages = [
      Stage(
        id: '1',
        name: 'Үлкен Арена "Олимп"',
        type: 'Концерттік',
        description:
            'Қазіргі заманғы жабдықтар мен тамаша акустикасы бар кәсіби концерт алаңы. Үлкен концерттер мен іс-шараларға өте қолайлы.',
        pricePerHour: 15000,
        pricePerDay: 100000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.9,
        reviewsCount: 156,
        location: 'Мәскеу, Орталық',
        address: 'Тверская көш., 10 үй',
        capacity: 2000,
        areaSquareMeters: 500,
        hasSound: true,
        hasLighting: true,
        hasBackstage: true,
        hasParking: true,
        amenities: [
          'Кәсіби дыбыс жүйесі',
          'Жарық шоулары',
          '5 грим бөлмесі',
          'Жерасты автотұрағы',
          'Кейтеринг қызметі',
          'VIP-аймақтар',
        ],
        ownerId: 'owner1',
        ownerName: 'Концерт залы "Олимп"',
        createdAt: DateTime.now(),
      ),
      Stage(
        id: '2',
        name: 'Театр сахнасы "Алтын маска"',
        type: 'Театрлық',
        description:
            'Бай тарихы бар классикалық театр сахнасы. Театр қойылымдарына арналған тамаша акустика мен атмосфера.',
        pricePerHour: 8000,
        pricePerDay: 50000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.8,
        reviewsCount: 89,
        location: 'Мәскеу, Арбат',
        address: 'Арбат, 25 үй',
        capacity: 500,
        areaSquareMeters: 200,
        hasSound: true,
        hasLighting: true,
        hasBackstage: true,
        hasParking: false,
        amenities: [
          'Театрлық дыбыс жүйесі',
          'Классикалық жарықтандыру',
          '3 грим бөлмесі',
          'Оркестр шұңқыры',
          'Реквизиттер',
        ],
        ownerId: 'owner2',
        ownerName: 'Театр "Алтын маска"',
        createdAt: DateTime.now(),
      ),
      Stage(
        id: '3',
        name: 'Клуб "Neon Nights"',
        type: 'Клубтық',
        description:
            'Кәсіби дыбыс және жарық жабдықтары бар заманауи клуб залы. Концерттер мен кештер өткізуге өте ыңғайлы.',
        pricePerHour: 12000,
        pricePerDay: 70000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.7,
        reviewsCount: 234,
        location: 'Мәскеу, Таганка',
        address: 'Народная көш., 5 үй',
        capacity: 800,
        areaSquareMeters: 300,
        hasSound: true,
        hasLighting: true,
        hasBackstage: true,
        hasParking: true,
        amenities: [
          'DJ-жабдық',
          'LED-экрандар',
          'Түтін машинасы',
          '2 грим бөлмесі',
          'Бар',
          'Би алаңы',
        ],
        ownerId: 'owner3',
        ownerName: 'Neon Entertainment',
        createdAt: DateTime.now(),
      ),
      Stage(
        id: '4',
        name: 'Ашық сахна "Горький саябағы"',
        type: 'Ашық',
        description:
            'Жазғы концерттер мен фестивальдерге арналған саябақтағы ашық алаң. Өзен жағалауына көрінісі бар әдемі орын.',
        pricePerHour: 10000,
        pricePerDay: 60000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.6,
        reviewsCount: 112,
        location: 'Мәскеу, Горький саябағы',
        address: 'Крымский Вал көш., 9 үй',
        capacity: 1500,
        areaSquareMeters: 400,
        hasSound: true,
        hasLighting: true,
        hasBackstage: false,
        hasParking: true,
        amenities: [
          'Ашық аспан астында',
          'Сыртқы дыбыс жүйесі',
          'Жарық мачталары',
          'Артистерге арналған автотұрақ',
          'Жылжымалы грим бөлмелер',
        ],
        ownerId: 'owner4',
        ownerName: 'Горький саябағы',
        createdAt: DateTime.now(),
      ),
      Stage(
        id: '5',
        name: 'Кіші сахна "Камерлік зал"',
        type: 'Кіші',
        description:
            'Шағын концерттер мен іс-шараларға арналған жайлы камерлік зал. Тамаша акустика және жылы атмосфера.',
        pricePerHour: 5000,
        pricePerDay: 30000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.8,
        reviewsCount: 67,
        location: 'Мәскеу, Кузнецкий Мост',
        address: 'Кузнецкий Мост, 12 үй',
        capacity: 150,
        areaSquareMeters: 80,
        hasSound: true,
        hasLighting: true,
        hasBackstage: true,
        hasParking: false,
        amenities: [
          'Камерлік дыбыс жүйесі',
          'Жайлы жарықтандыру',
          '1 грим бөлмесі',
          'Steinway роялі',
          'Кафе',
        ],
        ownerId: 'owner5',
        ownerName: 'Мәдениет орталығы',
        createdAt: DateTime.now(),
      ),
      Stage(
        id: '6',
        name: 'Мега Арена "Стадион"',
        type: 'Үлкен',
        description:
            'Ауқымды шоулар мен фестивальдер өткізуге арналған үлкен концерт алаңы. 10000 көрерменге дейін сыйымдылығы бар.',
        pricePerHour: 25000,
        pricePerDay: 150000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 5.0,
        reviewsCount: 298,
        location: 'Мәскеу, Лужники',
        address: 'Лужники жағалауы, 24 үй',
        capacity: 10000,
        areaSquareMeters: 1000,
        hasSound: true,
        hasLighting: true,
        hasBackstage: true,
        hasParking: true,
        amenities: [
          'Стадиондық дыбыс жүйесі',
          'Алып LED-экрандар',
          '10 грим бөлмесі',
          'Үлкен автотұрақ',
          'Медпункт',
          'Қауіпсіздік қызметі',
          'Кейтеринг',
        ],
        ownerId: 'owner6',
        ownerName: 'Спорт кешені "Лужники"',
        createdAt: DateTime.now(),
      ),
    ];


    setState(() {
      _allStages = sampleStages;
      _filteredStages = sampleStages;
    });

    try {
      final response = await ApiService.getAllStages(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response['success']) {
        final stagesData = response['stages'] as List;
        final serverStages = stagesData.map((data) {
          return Stage(
            id: data['_id'] is String ? data['_id'] : data['_id']['\$oid'],
            name: data['name'] ?? '',
            type: 'Концерттік',
            description: data['description'] ?? '',
            pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
            pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
            imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            rating: (data['rating'] ?? 0).toDouble(),
            reviewsCount: data['reviewsCount'] ?? 0,
            location: data['location'] ?? '',
            address: data['location'] ?? '',
            capacity: data['capacity'] ?? 0,
            areaSquareMeters: (data['size'] ?? 0).toDouble(),
            hasSound: (data['facilities'] as List?)?.contains('Дыбыстық жүйе') ?? false,
            hasLighting: (data['facilities'] as List?)?.contains('Жарықтандыру жүйесі') ?? false,
            hasBackstage: (data['facilities'] as List?)?.contains('Бэкстейдж') ?? false,
            hasParking: (data['facilities'] as List?)?.contains('Тұрақ') ?? false,
            amenities: (data['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            ownerId: data['ownerId'] ?? '',
            ownerName: data['ownerName'] ?? '',
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          );
        }).toList();

        setState(() {
          _allStages = [...sampleStages, ...serverStages];
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error loading stages from server: $e');
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredStages = _allStages.where((stage) {
        bool matchesType = _selectedType == 'Барлығы' || stage.type == _selectedType;
        bool matchesSearch = _searchQuery.isEmpty ||
            stage.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            stage.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            stage.location.toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchesCapacity =
            stage.capacity >= _minCapacity && stage.capacity <= _maxCapacity;

        return matchesType && matchesSearch && matchesCapacity;
      }).toList();

      switch (_sortBy) {
        case 'price_low':
          _filteredStages.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case 'price_high':
          _filteredStages.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
          break;
        case 'capacity_low':
          _filteredStages.sort((a, b) => a.capacity.compareTo(b.capacity));
          break;
        case 'capacity_high':
          _filteredStages.sort((a, b) => b.capacity.compareTo(a.capacity));
          break;
        case 'rating':
          _filteredStages.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'popular':
        default:
          _filteredStages.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTypeFilters(),
            const SizedBox(height: 16),
            _buildSortAndViewToggle(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE94560)),
                    )
                  : _filteredStages.isEmpty
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сахналар',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Мінсіз алаңды табыңыз',
                style: TextStyle(
                  color: Color(0xFFE94560),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Сахналарды іздеу...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type['name'];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = type['name'] as String);
              _applyFilters();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(type['icon'] as IconData, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    type['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  Widget _buildSortAndViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Табылды: ${_filteredStages.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _applyFilters();
                },
                color: const Color(0xFF16213E),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _getSortLabel(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'popular',
                    child: Text('Танымал', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Бағасы: төмен', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Бағасы: жоғары', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'capacity_low',
                    child: Text('Сыйымдылығы: төмен', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'capacity_high',
                    child: Text('Сыйымдылығы: жоғары', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Text('Рейтинг', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.view_list,
                  color: !_isGridView ? const Color(0xFFE94560) : Colors.white54,
                ),
                onPressed: () => setState(() => _isGridView = false),
              ),
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _isGridView ? const Color(0xFFE94560) : Colors.white54,
                ),
                onPressed: () => setState(() => _isGridView = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':
        return 'Бағасы: төмен ↑';
      case 'price_high':
        return 'Бағасы: жоғары ↓';
      case 'capacity_low':
        return 'Сыйымдылығы: төмен ↑';
      case 'capacity_high':
        return 'Сыйымдылығы: жоғары ↓';
      case 'rating':
        return 'Рейтинг';
      case 'popular':
      default:
        return 'Танымал';
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredStages.length,
      itemBuilder: (context, index) => _buildStageListCard(_filteredStages[index]),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredStages.length,
      itemBuilder: (context, index) => _buildStageGridCard(_filteredStages[index]),
    );
  }

  Widget _buildStageListCard(Stage stage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StageDetailsScreen(stage: stage)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: stage.imageUrls.isNotEmpty
                    ? stage.imageUrls[0]
                    : 'https://via.placeholder.com/150x150',
                width: 120,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE94560)),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                    ),
                  ),
                  child: const Icon(Icons.theater_comedy, color: Colors.white54, size: 40),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          stage.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: Color(0xFFE94560), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${stage.capacity}',
                                style: const TextStyle(
                                  color: Color(0xFFE94560),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.type,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white.withOpacity(0.5), size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stage.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${stage.pricePerHour.toInt()} ₸',
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/сағат',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildStageGridCard(Stage stage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StageDetailsScreen(stage: stage)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: stage.imageUrls.isNotEmpty
                        ? stage.imageUrls[0]
                        : 'https://via.placeholder.com/200x150',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE94560)),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                        ),
                      ),
                      child: const Icon(Icons.theater_comedy, color: Colors.white54, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${stage.capacity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        stage.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${stage.pricePerHour.toInt()} ₸/сағат',
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.5),
                        size: 14,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Сахналар табылмады',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Фильтрлерді өзгертіп көріңіз немесе басқа іздеу сөзін қолданыңыз.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Фильтрлер',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Алаңның сыйымдылығы',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: RangeValues(
                      _minCapacity.toDouble(),
                      _maxCapacity.toDouble(),
                    ),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: const Color(0xFFE94560),
                    inactiveColor: Colors.white.withOpacity(0.2),
                    labels: RangeLabels(
                      _minCapacity.toString(),
                      _maxCapacity.toString(),
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        _minCapacity = values.start.toInt();
                        _maxCapacity = values.end.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_minCapacity адамнан',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$_maxCapacity адамға дейін',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Фильтрлерді қолдану',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
