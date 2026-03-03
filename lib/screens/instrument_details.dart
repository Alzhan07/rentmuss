import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/instrument.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../widgets/availability_calendar.dart';
import 'payment_screen.dart';
import 'chat_screen.dart';

class InstrumentDetailsScreen extends StatefulWidget {
  final Instrument instrument;

  const InstrumentDetailsScreen({
    super.key,
    required this.instrument,
  });

  @override
  State<InstrumentDetailsScreen> createState() =>
      _InstrumentDetailsScreenState();
}

class _InstrumentDetailsScreenState extends State<InstrumentDetailsScreen> {
  int _selectedImageIndex = 0;
  bool _isFavorite = false;
  int _rentalHours = 3;
  bool _isCheckingFavorite = true;
  bool _descExpanded = false;

  // Reviews state
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  bool _hasReviewed = false;
  String? _userReviewId;
  double _averageRating = 0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final result = await ApiService.getReviews(
      itemId: widget.instrument.id,
      itemType: 'instrument',
    );
    final check = await ApiService.checkUserReview(
      itemId: widget.instrument.id,
      itemType: 'instrument',
    );
    if (mounted) {
      setState(() {
        _reviews = result['reviews'] ?? [];
        _averageRating = (result['averageRating'] ?? 0).toDouble();
        _totalReviews = result['total'] ?? 0;
        _hasReviewed = check['hasReviewed'] ?? false;
        _userReviewId = check['review']?['_id'];
        _loadingReviews = false;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    final result = await ApiService.checkIsFavorite(
      itemType: 'instrument',
      itemId: widget.instrument.id,
    );
    if (mounted) {
      setState(() {
        _isFavorite = result['isFavorite'] ?? false;
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      
      final result = await ApiService.removeFromFavorites(
        itemType: 'instrument',
        itemId: widget.instrument.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Таңдаулылардан жойылды'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      if (result['success']) {
        setState(() => _isFavorite = false);
      }
    } else {
      
      final result = await ApiService.addToFavorites(
        itemType: 'instrument',
        itemId: widget.instrument.id,
        itemData: {
          'name': widget.instrument.name,
          'description': widget.instrument.description,
          'images': widget.instrument.imageUrls,
          'pricePerHour': widget.instrument.pricePerHour,
          'pricePerDay': widget.instrument.pricePerDay,
          'rating': widget.instrument.rating,
          'location': widget.instrument.location,
          'category': widget.instrument.category,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Таңдаулыларға қосылды'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      if (result['success']) {
        setState(() => _isFavorite = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageGallery(),
                const SizedBox(height: 20),
                _buildMainInfo(),
                const SizedBox(height: 20),
                _buildPriceSection(),
                const SizedBox(height: 20),
                if (widget.instrument.hourlyAvailable) ...[
                  _buildRentalCalculator(),
                  const SizedBox(height: 20),
                ],
                _buildFeaturesSection(),
                const SizedBox(height: 20),
                _buildDescriptionSection(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AvailabilityCalendar(
                    itemId: widget.instrument.id,
                    itemType: 'instrument',
                  ),
                ),
                const SizedBox(height: 20),
                _buildOwnerInfo(),
                const SizedBox(height: 20),
                _buildReviewsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: const Color(0xFF16213E),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A2E),
                border: Border.all(
                  color: const Color(0xFFE94560).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _toggleFavorite,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(
                    color: _isFavorite
                        ? const Color(0xFFE94560).withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorite ? const Color(0xFFE94560) : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
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
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.instrument.imageUrls.isNotEmpty
        ? widget.instrument.imageUrls
        : ['https://via.placeholder.com/400x300'];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _selectedImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
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
                  child: const Icon(Icons.music_note, color: Colors.white54, size: 80),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _selectedImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _selectedImageIndex == index
                        ? const Color(0xFFE94560)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConditionColor(widget.instrument.condition),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getConditionLabel(widget.instrument.condition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  widget.instrument.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.instrument.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.instrument.brand} • ${widget.instrument.model}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 4),
              Text(
                widget.instrument.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.instrument.reviewsCount} пікір)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.instrument.location,
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
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94560).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.instrument.hourlyAvailable ? 'Жалға алу бағасы' : 'Күндік баға',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (widget.instrument.hourlyAvailable)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.instrument.pricePerHour.toInt()} ₸',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text(' /сағат', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.instrument.pricePerDay.toInt()} ₸',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text(' /күн', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
            ],
          ),
          if (widget.instrument.hourlyAvailable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Бір тәулікте', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${widget.instrument.pricePerDay.toInt()} ₸',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRentalCalculator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Жалға алу калькуляторы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Сағат саны:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                      onPressed: () {
                        if (_rentalHours > 1) {
                          setState(() {
                            _rentalHours--;
                          });
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_rentalHours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() {
                          _rentalHours++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE94560).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Төлем құны:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(widget.instrument.pricePerHour * _rentalHours).toInt()} ₸',
                  style: const TextStyle(
                    color: Color(0xFFE94560),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    if (widget.instrument.features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Не кіреді',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.instrument.features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00D9A5),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сипаттама',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.instrument.description,
            maxLines: _descExpanded ? null : 3,
            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (widget.instrument.description.length > 120)
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _descExpanded ? 'Жасыру ▲' : 'Толығырақ ▼',
                  style: const TextStyle(
                    color: Color(0xFFE94560),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE94560), Color(0xFFFF6B85)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Жалға беруші',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.instrument.ownerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.message, color: Color(0xFFE94560), size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    receiverId: widget.instrument.ownerId,
                    receiverName: widget.instrument.ownerName,
                    itemId: widget.instrument.id,
                    itemType: 'instrument',
                    itemName: widget.instrument.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + rating summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пікірлер',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_totalReviews > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_averageRating  ·  $_totalReviews пікір',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
              if (!_hasReviewed)
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.rate_review, color: Color(0xFFE94560), size: 18),
                  label: const Text('Пікір қосу', style: TextStyle(color: Color(0xFFE94560), fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Reviews list
          if (_loadingReviews)
            const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          else if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Әлі пікірлер жоқ.\nБірінші болыңыз!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), height: 1.6),
                ),
              ),
            )
          else
            ...List.generate(_reviews.length, (i) {
              final r = Review.fromJson(_reviews[i]);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReviewCard(r),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final isOwn = review.id == _userReviewId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwn ? const Color(0xFFE94560).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.initials,
                    style: const TextStyle(color: Color(0xFFE94560), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.username,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE94560).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Сіз', style: TextStyle(color: Color(0xFFE94560), fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFD700),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(review.createdAt),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete own review
              if (isOwn)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: 0.4), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteReview(review.id),
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Пікір қосу', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Star selector
              const Text('Бағалау', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setModal(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      i < selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD700),
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 20),

              // Comment field
              const Text('Пікір', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Тәжірибеңізбен бөлісіңіз...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE94560)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setModal(() => isSubmitting = true);
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    final result = await ApiService.createReview(
                      itemId: widget.instrument.id,
                      itemType: 'instrument',
                      rating: selectedRating,
                      comment: commentController.text.trim(),
                    );

                    navigator.pop();
                    messenger.showSnackBar(SnackBar(
                      content: Text(result['message'] ?? ''),
                      backgroundColor: result['success'] ? const Color(0xFF00D9A5) : Colors.red,
                    ));

                    if (result['success'] == true) _loadReviews();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    disabledBackgroundColor: const Color(0xFFE94560).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Жіберу', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ApiService.deleteReview(reviewId);
    messenger.showSnackBar(SnackBar(
      content: Text(result['message'] ?? ''),
      backgroundColor: result['success'] ? Colors.orange : Colors.red,
    ));
    if (result['success'] == true) _loadReviews();
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.instrument.hourlyAvailable
                      ? 'От ${widget.instrument.pricePerHour.toInt()} ₸/сағат'
                      : '${widget.instrument.pricePerDay.toInt()} ₸/күн',
                  style: const TextStyle(
                    color: Color(0xFFE94560),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.instrument.hourlyAvailable)
                  Text(
                    'или ${widget.instrument.pricePerDay.toInt()} ₸/күн',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  
                  _showBookingDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Брондау',
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
      ),
    );
  }

  Future<void> _showBookingDialog() async {
    // Load booked dates before opening dialog
    final bookedDates = await ApiService.getBookedDates(
      itemId: widget.instrument.id,
      itemType: 'instrument',
    );
    final bookedKeys = bookedDates
        .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
        .toSet();

    bool isDayBooked(DateTime day) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return bookedKeys.contains(key);
    }

    if (!mounted) return;

    String bookingType = 'day';
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;
    DateTime? selectedHourDate;
    int selectedHours = 2;
    int rentalDays = 1;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double calculateTotal() {
              if (bookingType == 'hour') {
                return widget.instrument.pricePerHour * selectedHours;
              }
              if (selectedStartDate != null && selectedEndDate != null) {
                final days = selectedEndDate!.difference(selectedStartDate!).inDays;
                rentalDays = days > 0 ? days : 1;
                return widget.instrument.pricePerDay * rentalDays;
              }
              return widget.instrument.pricePerDay;
            }

            Future<void> selectStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                selectableDayPredicate: (day) => !isDayBooked(day),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFE94560),
                        onPrimary: Colors.white,
                        surface: Color(0xFF16213E),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  selectedStartDate = picked;
                  if (selectedEndDate == null || selectedEndDate!.isBefore(picked)) {
                    selectedEndDate = picked.add(const Duration(days: 1));
                  }
                });
              }
            }

            Future<void> selectEndDate() async {
              if (selectedStartDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Алдымен басталу күнін таңдаңыз'),
                    backgroundColor: Color(0xFFE94560),
                  ),
                );
                return;
              }

              final picked = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? selectedStartDate!.add(const Duration(days: 1)),
                firstDate: selectedStartDate!,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                selectableDayPredicate: (day) => !isDayBooked(day),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFE94560),
                        onPrimary: Colors.white,
                        surface: Color(0xFF16213E),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() => selectedEndDate = picked);
              }
            }

            Future<void> submitBooking() async {
              if (bookingType == 'hour') {
                if (selectedHourDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Күнді таңдаңыз'),
                    backgroundColor: Color(0xFFE94560),
                  ));
                  return;
                }
              } else if (selectedStartDate == null || selectedEndDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Күндерді таңдаңыз'),
                    backgroundColor: Color(0xFFE94560),
                  ),
                );
                return;
              }

              setModalState(() => isLoading = true);

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                final result = await ApiService.createBooking(
                  itemId: widget.instrument.id,
                  itemType: 'instrument',
                  startDate: bookingType == 'hour' ? selectedHourDate! : selectedStartDate!,
                  endDate: bookingType == 'hour'
                      ? selectedHourDate!.add(Duration(hours: selectedHours))
                      : selectedEndDate!,
                  duration: bookingType == 'hour' ? selectedHours : rentalDays,
                  durationType: bookingType == 'hour' ? 'hour' : 'day',
                  pricePerUnit: bookingType == 'hour' ? widget.instrument.pricePerHour : widget.instrument.pricePerDay,
                  totalPrice: calculateTotal(),
                );

                if (!mounted) return;

                if (result['success'] == true && result['booking'] != null) {
                  final booking = Booking.fromJson(result['booking']);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        booking: booking,
                        itemName: widget.instrument.name,
                      ),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Қате'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Қате: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isLoading = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Брондау',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(widget.instrument.name,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                  const SizedBox(height: 20),

                  // Booking type toggle (only if hourly rental is enabled)
                  if (widget.instrument.hourlyAvailable) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => bookingType = 'day'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: bookingType == 'day' ? const Color(0xFFE94560) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Күн бойынша', textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: bookingType == 'day' ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => bookingType = 'hour'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: bookingType == 'hour' ? const Color(0xFFE94560) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Сағат бойынша', textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: bookingType == 'hour' ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Hourly booking form
                  if (bookingType == 'hour') ...[
                    const Text('Күн таңдаңыз',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          selectableDayPredicate: (day) => !isDayBooked(day),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFE94560),
                                onPrimary: Colors.white,
                                surface: Color(0xFF16213E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setModalState(() => selectedHourDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                            const SizedBox(width: 12),
                            Text(
                              selectedHourDate == null
                                  ? 'Күнді таңдаңыз'
                                  : DateFormat('dd.MM.yyyy').format(selectedHourDate!),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Сағат саны:',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                            onPressed: () { if (selectedHours > 1) setModalState(() => selectedHours--); },
                          ),
                          Text('$selectedHours сағат',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            onPressed: () { if (selectedHours < 24) setModalState(() => selectedHours++); },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9A5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D9A5).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Барлығы', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('$selectedHours сағат × ${widget.instrument.pricePerHour.toInt()} ₸',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                            ],
                          ),
                          Text('${calculateTotal().toInt()} ₸',
                              style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Daily booking form
                    const Text('Басталу күні',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: selectStartDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                            const SizedBox(width: 12),
                            Text(
                              selectedStartDate == null
                                  ? 'Күнді таңдау'
                                  : DateFormat('dd.MM.yyyy').format(selectedStartDate!),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Аяқталу күні',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: selectEndDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                            const SizedBox(width: 12),
                            Text(
                              selectedEndDate == null
                                  ? 'Күнді таңдау'
                                  : DateFormat('dd.MM.yyyy').format(selectedEndDate!),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedStartDate != null && selectedEndDate != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9A5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D9A5).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Барлығы', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('$rentalDays күн × ${widget.instrument.pricePerDay.toInt()} ₸',
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                              ],
                            ),
                            Text('${calculateTotal().toInt()} ₸',
                                style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Брондауды растау',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
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
