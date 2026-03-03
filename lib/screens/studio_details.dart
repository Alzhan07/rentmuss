import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/studio.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../widgets/availability_calendar.dart';
import 'payment_screen.dart';
import 'chat_screen.dart';

class StudioDetailsScreen extends StatefulWidget {
  final Studio studio;

  const StudioDetailsScreen({
    super.key,
    required this.studio,
  });

  @override
  State<StudioDetailsScreen> createState() => _StudioDetailsScreenState();
}

class _StudioDetailsScreenState extends State<StudioDetailsScreen> {
  int _selectedImageIndex = 0;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  int _rentalHours = 2;
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
      itemId: widget.studio.id,
      itemType: 'studio',
    );
    final check = await ApiService.checkUserReview(
      itemId: widget.studio.id,
      itemType: 'studio',
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
      itemType: 'studio',
      itemId: widget.studio.id,
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
        itemType: 'studio',
        itemId: widget.studio.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Таңдаулылардан жойылды'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ));
      if (result['success']) setState(() => _isFavorite = false);
    } else {
      final result = await ApiService.addToFavorites(
        itemType: 'studio',
        itemId: widget.studio.id,
        itemData: {
          'name': widget.studio.name,
          'description': widget.studio.description,
          'images': widget.studio.imageUrls,
          'pricePerHour': widget.studio.pricePerHour,
          'pricePerDay': widget.studio.pricePerDay,
          'rating': widget.studio.rating,
          'location': widget.studio.location,
          'equipment': widget.studio.equipment,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Таңдаулыларға қосылды'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ));
      if (result['success']) setState(() => _isFavorite = true);
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
                if (widget.studio.hourlyAvailable) ...[
                  _buildRentalCalculator(),
                  const SizedBox(height: 20),
                ],
                _buildFacilitiesSection(),
                const SizedBox(height: 20),
                _buildEquipmentSection(),
                const SizedBox(height: 20),
                _buildAmenitiesSection(),
                const SizedBox(height: 20),
                _buildDescriptionSection(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AvailabilityCalendar(
                    itemId: widget.studio.id,
                    itemType: 'studio',
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
            onTap: _isCheckingFavorite ? null : _toggleFavorite,
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
                child: _isCheckingFavorite
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
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
    final images = widget.studio.imageUrls.isNotEmpty
        ? widget.studio.imageUrls
        : <String>[];

    if (images.isEmpty) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF16213E)]),
        ),
        child: const Icon(Icons.mic, color: Colors.white24, size: 80),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _selectedImageIndex = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF16213E)]),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white54, size: 80),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE94560), Color(0xFFFF6B85)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.studio.type,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.studio.name,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 4),
              Text(
                widget.studio.rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.studio.reviewsCount} пікір)',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.straighten, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.studio.areaSquareMeters.toInt()} м²',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.studio.location,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
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
    final hourlyAvailable = widget.studio.hourlyAvailable;
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
          BoxShadow(color: const Color(0xFFE94560).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Жалға алу бағасы', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hourlyAvailable
                        ? '${widget.studio.pricePerHour.toInt()} ₸'
                        : '${widget.studio.pricePerDay.toInt()} ₸',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hourlyAvailable ? ' /сағат' : ' /күн',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          if (hourlyAvailable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Бір тәулікте', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${widget.studio.pricePerDay.toInt()} ₸',
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
          const Text('Жалға алу калькуляторы',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Сағат саны:', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                      onPressed: () { if (_rentalHours > 1) setState(() => _rentalHours--); },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_rentalHours',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _rentalHours++),
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
                const Text('Төлем құны:',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  '${(widget.studio.pricePerHour * _rentalHours).toInt()} ₸',
                  style: const TextStyle(color: Color(0xFFE94560), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ерекшеліктері',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFacilityCard(Icons.engineering, 'Инженер', widget.studio.hasEngineer)),
              const SizedBox(width: 12),
              Expanded(child: _buildFacilityCard(Icons.music_note, 'Аспаптар', widget.studio.hasInstruments)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFacilityCard(Icons.hearing, 'Изоляция', widget.studio.hasSoundproofing)),
              const SizedBox(width: 12),
              Expanded(child: _buildFacilityCard(Icons.ac_unit, 'Кондиционер', widget.studio.hasAirConditioning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(IconData icon, String label, bool available) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available ? const Color(0xFF00D9A5).withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available ? const Color(0xFF00D9A5).withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: available ? const Color(0xFF00D9A5) : Colors.white54, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: available ? const Color(0xFF00D9A5) : Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? const Color(0xFF00D9A5) : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    if (widget.studio.equipment.isEmpty) return const SizedBox.shrink();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE94560), Color(0xFFFF6B85)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_input_component, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Жабдықтар',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.studio.equipment,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    if (widget.studio.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Қосымша',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.studio.amenities.map((amenity) {
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
                    const Icon(Icons.check_circle, color: Color(0xFF00D9A5), size: 18),
                    const SizedBox(width: 8),
                    Text(amenity, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
          const Text('Сипаттама',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            widget.studio.description,
            maxLines: _descExpanded ? null : 3,
            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, height: 1.6),
          ),
          if (widget.studio.description.length > 120)
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE94560), Color(0xFFFF6B85)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apartment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Студия иесі', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.studio.ownerName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(
                  receiverId: widget.studio.ownerId,
                  receiverName: widget.studio.ownerName,
                  itemId: widget.studio.id,
                  itemType: 'studio',
                  itemName: widget.studio.name,
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  // ── Reviews ──────────────────────────────────

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Пікірлер',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_totalReviews > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_averageRating  ·  $_totalReviews пікір',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
              if (!_hasReviewed)
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.rate_review, color: Color(0xFFE94560), size: 18),
                  label: const Text('Пікір қосу',
                      style: TextStyle(color: Color(0xFFE94560), fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingReviews)
            const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          else if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Әлі пікірлер жоқ.\nБірінші болыңыз!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), height: 1.6),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwn
              ? const Color(0xFFE94560).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.initials,
                    style: const TextStyle(
                        color: Color(0xFFE94560), fontSize: 16, fontWeight: FontWeight.bold),
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
                        Text(review.username,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE94560).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Сіз',
                                style: TextStyle(color: Color(0xFFE94560), fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD700),
                          size: 14,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(review.createdAt),
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.white.withOpacity(0.4), size: 20),
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
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, height: 1.5),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Text('Пікір қосу',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
              const Text('Пікір', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Тәжірибеңізбен бөлісіңіз...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE94560)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setModal(() => isSubmitting = true);
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await ApiService.createReview(
                      itemId: widget.studio.id,
                      itemType: 'studio',
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
                    disabledBackgroundColor: const Color(0xFFE94560).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Жіберу',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  // ── Bottom sheet ─────────────────────────────

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5)),
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
                  widget.studio.hourlyAvailable
                      ? '${widget.studio.pricePerHour.toInt()} ₸/сағатынан'
                      : '${widget.studio.pricePerDay.toInt()} ₸/күніне',
                  style: const TextStyle(color: Color(0xFFE94560), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.studio.hourlyAvailable)
                  Text(
                    'немесе ${widget.studio.pricePerDay.toInt()} ₸/күніне',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _showBookingDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Брондау',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBookingDialog() async {
    final bookedDates = await ApiService.getBookedDates(
      itemId: widget.studio.id,
      itemType: 'studio',
    );
    final bookedKeys = bookedDates
        .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
        .toSet();

    bool isDayBooked(DateTime day) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return bookedKeys.contains(key);
    }

    if (!mounted) return;

    final hourlyAvailable = widget.studio.hourlyAvailable;
    String bookingType = hourlyAvailable ? 'hour' : 'day';
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double calculateTotal() {
              if (bookingType == 'hour') {
                return widget.studio.pricePerHour * selectedHours;
              }
              if (selectedStartDate != null && selectedEndDate != null) {
                final days = selectedEndDate!.difference(selectedStartDate!).inDays;
                rentalDays = days > 0 ? days : 1;
                return widget.studio.pricePerDay * rentalDays;
              }
              return widget.studio.pricePerDay;
            }

            Future<void> selectHourDate() async {
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
            }

            Future<void> selectStartDate() async {
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Алдымен басталу күнін таңдаңыз'),
                  backgroundColor: Color(0xFFE94560),
                ));
                return;
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? selectedStartDate!.add(const Duration(days: 1)),
                firstDate: selectedStartDate!,
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
              if (picked != null) setModalState(() => selectedEndDate = picked);
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
                setModalState(() => isLoading = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final endHourDate = selectedHourDate!.add(Duration(hours: selectedHours));
                  final result = await ApiService.createBooking(
                    itemId: widget.studio.id,
                    itemType: 'studio',
                    startDate: selectedHourDate!,
                    endDate: endHourDate,
                    duration: selectedHours,
                    durationType: 'hour',
                    pricePerUnit: widget.studio.pricePerHour,
                    totalPrice: calculateTotal(),
                  );
                  if (!mounted) return;
                  if (result['success'] == true && result['booking'] != null) {
                    final booking = Booking.fromJson(result['booking']);
                    navigator.pop();
                    navigator.push(MaterialPageRoute(
                      builder: (_) => PaymentScreen(booking: booking, itemName: widget.studio.name),
                    ));
                  } else {
                    messenger.showSnackBar(SnackBar(
                      content: Text(result['message'] ?? 'Қате'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('Қате: $e'),
                    backgroundColor: Colors.red,
                  ));
                } finally {
                  if (mounted) setModalState(() => isLoading = false);
                }
              } else {
                if (selectedStartDate == null || selectedEndDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Күндерді таңдаңыз'),
                    backgroundColor: Color(0xFFE94560),
                  ));
                  return;
                }
                setModalState(() => isLoading = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final result = await ApiService.createBooking(
                    itemId: widget.studio.id,
                    itemType: 'studio',
                    startDate: selectedStartDate!,
                    endDate: selectedEndDate!,
                    duration: rentalDays,
                    durationType: 'day',
                    pricePerUnit: widget.studio.pricePerDay,
                    totalPrice: calculateTotal(),
                  );
                  if (!mounted) return;
                  if (result['success'] == true && result['booking'] != null) {
                    final booking = Booking.fromJson(result['booking']);
                    navigator.pop();
                    navigator.push(MaterialPageRoute(
                      builder: (_) => PaymentScreen(booking: booking, itemName: widget.studio.name),
                    ));
                  } else {
                    messenger.showSnackBar(SnackBar(
                      content: Text(result['message'] ?? 'Қате'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('Қате: $e'),
                    backgroundColor: Colors.red,
                  ));
                } finally {
                  if (mounted) setModalState(() => isLoading = false);
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
                  const SizedBox(height: 8),
                  Text(widget.studio.name,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                  const SizedBox(height: 20),
                  if (hourlyAvailable) ...[
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
                              onTap: () => setModalState(() => bookingType = 'hour'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: bookingType == 'hour' ? const Color(0xFFE94560) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text('Сағаттық',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: bookingType == 'hour' ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => bookingType = 'day'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: bookingType == 'day' ? const Color(0xFFE94560) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text('Күндік',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: bookingType == 'day' ? Colors.white : Colors.white54,
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
                  if (bookingType == 'hour') ...[
                    const Text('Күнді таңдаңыз',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: selectHourDate,
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
                                  ? 'Күнді таңдау'
                                  : DateFormat('dd.MM.yyyy').format(selectedHourDate!),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Сағат саны:',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                                  if (selectedHours > 1) setModalState(() => selectedHours--);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('$selectedHours',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                onPressed: () => setModalState(() => selectedHours++),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Жалпы сомасы:',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('$selectedHours сағат × ${widget.studio.pricePerHour.toInt()} ₸',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                          Text('${calculateTotal().toInt()} ₸',
                              style: const TextStyle(
                                  color: Color(0xFFE94560), fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ] else ...[
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
                          color: const Color(0xFFE94560).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE94560).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Жалпы сомасы:',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('$rentalDays күн × ${widget.studio.pricePerDay.toInt()} ₸',
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                            Text('${calculateTotal().toInt()} ₸',
                                style: const TextStyle(
                                    color: Color(0xFFE94560), fontSize: 22, fontWeight: FontWeight.bold)),
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
                        disabledBackgroundColor: const Color(0xFFE94560).withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Брондауды растау',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
