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

class _StudiosScreenState extends State<StudiosScreen> {
  List<Studio> _allStudios = [];
  List<Studio> _filteredStudios = [];
  bool _isLoading = false;
  bool _isGridView = false;

  String _searchQuery = '';
  String _selectedType = 'Все';
  String _sortBy = 'popular';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {'name': 'Все', 'icon': Icons.apps},
    {'name': 'Звукозапись', 'icon': Icons.mic},
    {'name': 'Репетиция', 'icon': Icons.music_note},
    {'name': 'Подкасты', 'icon': Icons.podcasts},
    {'name': 'Стриминг', 'icon': Icons.live_tv},
    {'name': 'Сведение', 'icon': Icons.equalizer},
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

    await Future.delayed(const Duration(milliseconds: 500));

    final sampleStudios = [
      Studio(
        id: '1',
        name: 'Pro Sound Studio',
        type: 'Звукозапись',
        description:
            'Профессиональная студия звукозаписи с лучшим оборудованием. Опытные звукорежиссеры помогут создать идеальный звук.',
        pricePerHour: 3000,
        pricePerDay: 20000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.9,
        reviewsCount: 187,
        location: 'Москва, Центр',
        address: 'ул. Маросейка, д. 7',
        areaSquareMeters: 50,
        hasEngineer: true,
        hasInstruments: true,
        hasSoundproofing: true,
        hasAirConditioning: true,
        equipment: 'SSL Console, Neumann U87, Pro Tools',
        amenities: [
          'Звукорежиссер',
          'Микрофоны Neumann',
          'Pro Tools HD',
          'Мониторы Genelec',
          'Пианино',
          'Гитарные усилители',
          'Кухня',
        ],
        ownerId: 'owner1',
        ownerName: 'Pro Sound Records',
        createdAt: DateTime.now(),
      ),
      Studio(
        id: '2',
        name: 'Rock Rehearsal Space',
        type: 'Репетиция',
        description:
            'Просторная репетиционная база с полным комплектом оборудования для рок-групп.',
        pricePerHour: 800,
        pricePerDay: 5000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.7,
        reviewsCount: 143,
        location: 'Москва, Сокол',
        address: 'Ленинградский проспект, д. 45',
        areaSquareMeters: 60,
        hasEngineer: false,
        hasInstruments: true,
        hasSoundproofing: true,
        hasAirConditioning: false,
        equipment: 'Барабаны Pearl, Усилители Marshall, PA система',
        amenities: [
          'Ударная установка',
          'Гитарные усилители',
          'Бас-усилитель',
          'PA система',
          'Микрофоны',
          'Кабели',
        ],
        ownerId: 'owner2',
        ownerName: 'RockBase',
        createdAt: DateTime.now(),
      ),
      Studio(
        id: '3',
        name: 'Podcast Hub',
        type: 'Подкасты',
        description:
            'Современная студия для записи подкастов с видео-оборудованием и профессиональным звуком.',
        pricePerHour: 2000,
        pricePerDay: 12000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.8,
        reviewsCount: 92,
        location: 'Москва, Красные Ворота',
        address: 'ул. Мясницкая, д. 15',
        areaSquareMeters: 35,
        hasEngineer: true,
        hasInstruments: false,
        hasSoundproofing: true,
        hasAirConditioning: true,
        equipment: 'Rode Podcaster, Zoom H6, Sony A7S III',
        amenities: [
          '3 камеры',
          'Подкаст-микрофоны',
          'Зеленый фон',
          'Освещение',
          'Звукорежиссер',
          'Монтаж включен',
        ],
        ownerId: 'owner3',
        ownerName: 'Media Production',
        createdAt: DateTime.now(),
      ),
      Studio(
        id: '4',
        name: 'Live Stream Studio',
        type: 'Стриминг',
        description:
            'Студия для живых трансляций с профессиональным видео и звуковым оборудованием.',
        pricePerHour: 2500,
        pricePerDay: 15000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.6,
        reviewsCount: 78,
        location: 'Москва, Тверская',
        address: 'ул. Тверская, д. 20',
        areaSquareMeters: 45,
        hasEngineer: true,
        hasInstruments: false,
        hasSoundproofing: true,
        hasAirConditioning: true,
        equipment: 'BlackMagic ATEM, OBS, Stream Deck',
        amenities: [
          'Прямой эфир',
          '4 камеры',
          'Трансляция на YouTube/Twitch',
          'Оператор',
          'Зеленый экран',
          'RGB освещение',
        ],
        ownerId: 'owner4',
        ownerName: 'StreamPro',
        createdAt: DateTime.now(),
      ),
      Studio(
        id: '5',
        name: 'Mix & Master Lab',
        type: 'Сведение',
        description:
            'Студия сведения и мастеринга с акустической обработкой премиум-класса.',
        pricePerHour: 4000,
        pricePerDay: 25000,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 5.0,
        reviewsCount: 156,
        location: 'Москва, Парк Культуры',
        address: 'Зубовский бульвар, д. 4',
        areaSquareMeters: 40,
        hasEngineer: true,
        hasInstruments: false,
        hasSoundproofing: true,
        hasAirConditioning: true,
        equipment: 'Neve Console, UAD Apollo, Focal Twin6',
        amenities: [
          'Опытный звукорежиссер',
          'Аналоговое оборудование',
          'Плагины UAD',
          'Референсные мониторы',
          'Акустическая обработка',
        ],
        ownerId: 'owner5',
        ownerName: 'MasterSound',
        createdAt: DateTime.now(),
      ),
      Studio(
        id: '6',
        name: 'Jam Session Room',
        type: 'Репетиция',
        description:
            'Уютная репетиционная комната для малых составов и акустических сессий.',
        pricePerHour: 600,
        pricePerDay: 3500,
        imageUrls: ['https://via.placeholder.com/400x300'],
        rating: 4.5,
        reviewsCount: 64,
        location: 'Москва, Чистые Пруды',
        address: 'Чистопрудный бульвар, д. 12',
        areaSquareMeters: 25,
        hasEngineer: false,
        hasInstruments: true,
        hasSoundproofing: true,
        hasAirConditioning: false,
        equipment: 'Комбо-усилители, Микрофоны, Миксер',
        amenities: [
          'Гитарный усилитель',
          'Комбо для клавиш',
          'Микрофоны Shure',
          'Аудиоинтерфейс',
          'Wi-Fi',
        ],
        ownerId: 'owner6',
        ownerName: 'Jam Club',
        createdAt: DateTime.now(),
      ),
    ];

    setState(() {
      _allStudios = sampleStudios;
      _filteredStudios = sampleStudios;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredStudios = _allStudios.where((studio) {
        bool matchesType = _selectedType == 'Все' || studio.type == _selectedType;
        bool matchesSearch = _searchQuery.isEmpty ||
            studio.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            studio.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            studio.equipment.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesType && matchesSearch;
      }).toList();

      switch (_sortBy) {
        case 'price_low':
          _filteredStudios.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case 'price_high':
          _filteredStudios.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
          break;
        case 'rating':
          _filteredStudios.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'popular':
        default:
          _filteredStudios.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
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
                'Студии',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Запись, репетиция, производство',
                style: TextStyle(
                  color: Color(0xFFE94560),
                  fontSize: 14,
                ),
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
            child: const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 24,
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
            setState(() => _searchQuery = value);
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Поиск студий...',
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
                'Найдено: ${_filteredStudios.length}',
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
                    child: Text('Популярные', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Цена: низкая', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Цена: высокая', style: TextStyle(color: Colors.white)),
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
        return 'Цена ↑';
      case 'price_high':
        return 'Цена ↓';
      case 'rating':
        return 'Рейтинг';
      case 'popular':
      default:
        return 'Популярные';
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredStudios.length,
      itemBuilder: (context, index) => _buildStudioListCard(_filteredStudios[index]),
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
      itemCount: _filteredStudios.length,
      itemBuilder: (context, index) => _buildStudioGridCard(_filteredStudios[index]),
    );
  }

  Widget _buildStudioListCard(Studio studio) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudioDetailsScreen(studio: studio)),
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
                imageUrl: studio.imageUrls.isNotEmpty
                    ? studio.imageUrls[0]
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
                  child: const Icon(Icons.mic, color: Colors.white54, size: 40),
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
                          studio.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (studio.hasEngineer)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9A5).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.engineering, color: Color(0xFF00D9A5), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Инженер',
                                  style: TextStyle(
                                    color: Color(0xFF00D9A5),
                                    fontSize: 10,
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
                      studio.name,
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
                      studio.type,
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
                            studio.location,
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
                          '${studio.pricePerHour.toInt()} ₽',
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/час',
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

  Widget _buildStudioGridCard(Studio studio) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudioDetailsScreen(studio: studio)),
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
                    imageUrl: studio.imageUrls.isNotEmpty
                        ? studio.imageUrls[0]
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
                      child: const Icon(Icons.mic, color: Colors.white54, size: 40),
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
                if (studio.hasEngineer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9A5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.engineering, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Инженер',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
                    studio.name,
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
                        studio.rating.toStringAsFixed(1),
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
                          '${studio.pricePerHour.toInt()} ₽/час',
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
            'Студии не найдены',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
