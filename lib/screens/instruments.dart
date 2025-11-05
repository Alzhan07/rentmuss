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
    with SingleTickerProviderStateMixin {
  List<Instrument> _allInstruments = [];
  List<Instrument> _filteredInstruments = [];
  bool _isLoading = false;
  bool _isGridView = false;

  String _searchQuery = '';
  String _selectedCategory = 'Барлығы';
  String _sortBy = 'popular';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Барлығы', 'icon': Icons.apps},
    {'name': 'Гитаралар', 'icon': Icons.music_note},
    {'name': 'Пернетақталы', 'icon': Icons.piano},
    {'name': 'Ұрмалы', 'icon': Icons.album},
    {'name': 'Үрмелі', 'icon': Icons.graphic_eq},
    {'name': 'Шекті', 'icon': Icons.music_note_outlined},
    {'name': 'Бас', 'icon': Icons.headphones},
  ];

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstruments() async {
    setState(() => _isLoading = true);

    // Тестовые данные с изображениями
    final sampleInstruments = [
      Instrument(
        id: 'sample1',
        name: 'Fender Stratocaster',
        category: 'Гитаралар',
        brand: 'Fender',
        model: 'American Professional II',
        description: 'Классикалық дыбысы бар тарихи Fender гитарасы.',
        pricePerHour: 800,
        pricePerDay: 3500,
        imageUrls: [
          'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?w=800',
        ],
        rating: 4.9,
        reviewsCount: 127,
        location: 'Алматы, Орталық',
        condition: 'Керемет',
        features: [
          '3 сингл датчигі',
          'Клен мойын',
          'Қапшық жинақта бар',
          'Күшейткіш',
        ],
        ownerId: 'sample_owner1',
        ownerName: 'Музыка орталығы "Гармония"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: 'sample2',
        name: 'Yamaha P-125',
        category: 'Пернетақталы',
        brand: 'Yamaha',
        model: 'P-125',
        description:
            'Салмақталған пернетақтасы және шынайы дыбысы бар сандық пианино.',
        pricePerHour: 600,
        pricePerDay: 2500,
        imageUrls: [
          'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?w=800',
        ],
        rating: 4.8,
        reviewsCount: 89,
        location: 'Алматы, Достық',
        condition: 'Керемет',
        features: ['88 перне', 'Педальдар жинақта бар', 'Құлаққаптар', 'Тұғыр'],
        ownerId: 'sample_owner2',
        ownerName: 'Студия "Дыбыс"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: 'sample3',
        name: 'Pearl Export Series',
        category: 'Ұрмалы',
        brand: 'Pearl',
        model: 'Export EXX725S',
        description:
            '5 барабаннан және тарелкалардан тұратын кәсіби барабан жинағы.',
        pricePerHour: 1200,
        pricePerDay: 5000,
        imageUrls: [
          'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=800',
        ],
        rating: 4.7,
        reviewsCount: 56,
        location: 'Алматы, Сайран',
        condition: 'Жақсы',
        features: [
          '5 барабан',
          'Zildjian тарелкалары',
          'Тіреулер мен педальдар',
          'Барабан таяқшалары',
        ],
        ownerId: 'sample_owner3',
        ownerName: 'Репетиция базасы "Рокот"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: 'sample4',
        name: 'Gibson Les Paul',
        category: 'Гитаралар',
        brand: 'Gibson',
        model: 'Les Paul Standard',
        description:
            'Күшті дыбысы және премиум әрлеуі бар классикалық рок-гитара.',
        pricePerHour: 1500,
        pricePerDay: 6000,
        imageUrls: [
          'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=800',
        ],
        rating: 5.0,
        reviewsCount: 234,
        location: 'Алматы, Орталық',
        condition: 'Керемет',
        features: [
          '2 хамбакер',
          'Қызыл ағаш корпусы',
          'Marshall күшейткіші',
          'Премиум қапшық',
        ],
        ownerId: 'sample_owner4',
        ownerName: 'RockStore',
        createdAt: DateTime.now(),
      ),
    ];

    try {
      final response = await ApiService.getAllInstruments(
        category: _selectedCategory != 'Барлығы' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response['success']) {
        final instrumentsData = response['instruments'] as List;
        if (instrumentsData.isNotEmpty) {
          final serverInstruments =
              instrumentsData.map((data) {
                return Instrument.fromJson(data);
              }).toList();

          setState(() {
            _allInstruments = [...sampleInstruments, ...serverInstruments];
            _filteredInstruments = [...sampleInstruments, ...serverInstruments];
            _isLoading = false;
          });

          _applyFilters();
          return;
        }
      }
    } catch (e) {
      print('Error loading instruments: $e');
    }

    // Если не удалось загрузить с сервера или нет данных, показываем тестовые
    setState(() {
      _allInstruments = sampleInstruments;
      _filteredInstruments = sampleInstruments;
      _isLoading = false;
    });
    _applyFilters();

    // Старые закомментированные тестовые данные
    /*
    final oldSampleInstruments = [
      Instrument(
        id: '1',
        name: 'Fender Stratocaster',
        category: 'Гитарлар',
        brand: 'Fender',
        model: 'American Professional II',
        description:
            'Классикалық дыбысы бар тарихи Fender гитарасы.',
        pricePerHour: 800,
        pricePerDay: 3500,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.9,
        reviewsCount: 127,
        location: 'Мәскеу, Тверская',
        condition: 'өте жақсы',
        features: [
          '3 сингл датчигі',
          'Клен мойын',
          'Қапшық (кейс) жинақта бар',
          'Күшейткіш (усилитель)',
        ],
        ownerId: 'owner1',
        ownerName: 'Музыка орталығы "Гармония"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: '2',
        name: 'Yamaha P-125',
        category: 'Клавишалар',
        brand: 'Yamaha',
        model: 'P-125',
        description:
            'Салмақталған пернетақтасы және шынайы дыбысы бар сандық пианино.',
        pricePerHour: 600,
        pricePerDay: 2500,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.8,
        reviewsCount: 89,
        location: 'Мәскеу, Арбат',
        condition: 'өте жақсы',
        features: [
          '88 перне',
          'Педальдар жинақта бар',
          'Құлаққаптар',
          'Тұғыр (подставка)',
        ],
        ownerId: 'owner2',
        ownerName: 'Студия "Дыбыс"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: '3',
        name: 'Pearl Export Series',
        category: 'Ұрмалы аспаптар',
        brand: 'Pearl',
        model: 'Export EXX725S',
        description:
            '5 барабаннан және тарелкалардан тұратын кәсіби барабан жинағы.',
        pricePerHour: 1200,
        pricePerDay: 5000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.7,
        reviewsCount: 56,
        location: 'Мәскеу, Сокол',
        condition: 'жақсы',
        features: [
          '5 барабан',
          'Zildjian тарелкалары',
          'Тіреулер мен педальдар',
          'Барабан таяқшалары',
        ],
        ownerId: 'owner3',
        ownerName: 'Репетиция базасы "Рокот"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: '4',
        name: 'Gibson Les Paul',
        category: 'Гитарлар',
        brand: 'Gibson',
        model: 'Les Paul Standard',
        description:
            'Күшті дыбысы және премиум әрлеуі бар классикалық рок-гитара.',
        pricePerHour: 1500,
        pricePerDay: 6000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 5.0,
        reviewsCount: 234,
        location: 'Мәскеу, Орталық',
        condition: 'жаңа',
        features: [
          '2 хамбакер',
          'Қызыл ағаш корпусы',
          'Marshall күшейткіші',
          'Премиум қапшық',
        ],
        ownerId: 'owner4',
        ownerName: 'RockStore',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: '5',
        name: 'Yamaha YAS-280',
        category: 'Үрмелі аспаптар',
        brand: 'Yamaha',
        model: 'YAS-280',
        description:
            'Керемет дыбысы бар бастапқы деңгейдегі альт-саксофон.',
        pricePerHour: 700,
        pricePerDay: 3000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.6,
        reviewsCount: 43,
        location: 'Мәскеу, Мәдениет саябағы',
        condition: 'жақсы',
        features: [
          'Алтын түсті қаптама',
          'Қапшық жинақта бар',
          'Тростар',
          'Мундштук',
        ],
        ownerId: 'owner5',
        ownerName: 'Джаз клубы "Blue Note"',
        createdAt: DateTime.now(),
      ),
      Instrument(
        id: '6',
        name: 'Fender Precision Bass',
        category: 'Бас-гитарлар',
        brand: 'Fender',
        model: 'Player Series',
        description: 'Терең әрі таза дыбысы бар классикалық бас-гитара.',
        pricePerHour: 900,
        pricePerDay: 4000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.8,
        reviewsCount: 92,
        location: 'Мәскеу, Курская',
        condition: 'өте жақсы',
        features: [
          'Сплит-звукосниматель',
          'Клен мойын',
          'Бас күшейткіші',
          'Кабель',
        ],
        ownerId: 'owner6',
        ownerName: 'Bass House',
        createdAt: DateTime.now(),
      ),
    ];
    */
  }

  void _applyFilters() {
    setState(() {
      _filteredInstruments =
          _allInstruments.where((instrument) {
            bool matchesCategory =
                _selectedCategory == 'Барлығы' ||
                instrument.category == _selectedCategory;

            bool matchesSearch =
                _searchQuery.isEmpty ||
                instrument.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                instrument.brand.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                instrument.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            return matchesCategory && matchesSearch;
          }).toList();

      switch (_sortBy) {
        case 'price_low':
          _filteredInstruments.sort(
            (a, b) => a.pricePerHour.compareTo(b.pricePerHour),
          );
          break;
        case 'price_high':
          _filteredInstruments.sort(
            (a, b) => b.pricePerHour.compareTo(a.pricePerHour),
          );
          break;
        case 'rating':
          _filteredInstruments.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'popular':
        default:
          _filteredInstruments.sort(
            (a, b) => b.reviewsCount.compareTo(a.reviewsCount),
          );
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
            _buildCategoryFilters(),
            const SizedBox(height: 16),
            _buildSortAndViewToggle(),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE94560),
                        ),
                      )
                      : _filteredInstruments.isEmpty
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
                'Аспаптар',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Мінсіз аспапты табыңыз',
                style: TextStyle(color: Color(0xFFE94560), fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
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
            hintText: 'Аспаптарды іздеу...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'] as String;
              });
              _loadInstruments();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? const LinearGradient(
                          colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
                        )
                        : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] as String,
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
                'Табылды: ${_filteredInstruments.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                  _applyFilters();
                },
                color: const Color(0xFF16213E),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'popular',
                        child: Text(
                          'Танымал',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'price_low',
                        child: Text(
                          'Баға: төмен',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'price_high',
                        child: Text(
                          'Баға: жоғары',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rating',
                        child: Text(
                          'Рейтинг',
                          style: TextStyle(color: Colors.white),
                        ),
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
                  color:
                      !_isGridView ? const Color(0xFFE94560) : Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = false;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _isGridView ? const Color(0xFFE94560) : Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = true;
                  });
                },
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
        return 'Баға ↑';
      case 'price_high':
        return 'Баға ↓';
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
      itemCount: _filteredInstruments.length,
      itemBuilder: (context, index) {
        return _buildInstrumentListCard(_filteredInstruments[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredInstruments.length,
      itemBuilder: (context, index) {
        return _buildInstrumentGridCard(_filteredInstruments[index]);
      },
    );
  }

  Widget _buildInstrumentListCard(Instrument instrument) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => InstrumentDetailsScreen(instrument: instrument),
          ),
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
                imageUrl:
                    instrument.imageUrls.isNotEmpty
                        ? instrument.imageUrls[0]
                        : 'https://via.placeholder.com/150x150',
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE94560),
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 40,
                      ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(instrument.condition),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getConditionLabel(instrument.condition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          instrument.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instrument.name,
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
                      '${instrument.brand} • ${instrument.model}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.5),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            instrument.location,
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
                          '${instrument.pricePerHour.toInt()} ₸',
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

  Widget _buildInstrumentGridCard(Instrument instrument) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => InstrumentDetailsScreen(instrument: instrument),
          ),
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
                    imageUrl:
                        instrument.imageUrls.isNotEmpty
                            ? instrument.imageUrls[0]
                            : 'https://via.placeholder.com/200x150',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE94560),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 40,
                          ),
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
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          instrument.rating.toStringAsFixed(1),
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
                    instrument.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instrument.brand,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${instrument.pricePerHour.toInt()} ₸/сағат',
                              style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Аспаптар табылмады',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Фильтрлерді өзгертуге тырысыңыз',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'new':
        return const Color(0xFF00D9A5);
      case 'excellent':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF2196F3);
      case 'fair':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  String _getConditionLabel(String condition) {
    switch (condition) {
      case 'new':
        return 'ЖАҢА';
      case 'excellent':
        return 'КЕРЕМЕТ';
      case 'good':
        return 'ЖАҚСЫ';
      case 'fair':
        return 'ОРТАША';
      default:
        return condition.toUpperCase();
    }
  }
}
