import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _allBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    final result = await ApiService.getUserBookings();
    if (mounted) {
      setState(() {
        final raw = result['bookings'] as List? ?? [];
        _allBookings = raw.map((b) => Booking.fromJson(b)).toList();
        _loading = false;
      });
    }
  }

  List<Booking> get _pending => _allBookings
      .where((b) => b.isPending)
      .toList();

  List<Booking> get _active => _allBookings
      .where((b) => b.isConfirmed && b.endDate.isAfter(DateTime.now()))
      .toList();

  List<Booking> get _past => _allBookings
      .where((b) => b.isCompleted || (b.isConfirmed && b.isPast))
      .toList();

  List<Booking> get _cancelled => _allBookings.where((b) => b.isCancelled).toList();

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Брондауды болдырмау', style: TextStyle(color: Colors.white)),
        content: Text(
          'Брондауды болдырмауға сенімдісіз бе?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Жоқ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Болдырмау', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.cancelBooking(booking.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] ? Colors.orange : Colors.red,
      ));
      if (result['success'] == true) _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: CustomAppBar(
        title: 'Брондауларым',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadBookings,
          ),
        ],
        bottomWidget: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: const Color(0xFFE94560),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Күтуде (${_pending.length})'),
            Tab(text: 'Белсенді (${_active.length})'),
            Tab(text: 'Өткен (${_past.length})'),
            Tab(text: 'Болдырылмаған (${_cancelled.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending, showCancel: true, isPendingTab: true),
                _buildList(_active, showCancel: true),
                _buildList(_past),
                _buildList(_cancelled),
              ],
            ),
    );
  }

  Widget _buildList(List<Booking> bookings, {bool showCancel = false, bool isPendingTab = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.hourglass_empty_rounded : Icons.calendar_today_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? 'Растауды күтетін брондаулар жоқ' : 'Брондаулар жоқ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE94560),
      backgroundColor: const Color(0xFF16213E),
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: bookings.length + (isPendingTab ? 1 : 0),
        itemBuilder: (_, i) {
          if (isPendingTab && i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Бұл брондаулар сатушының растауын күтуде. Растаудан кейін "Белсенді" табқа өтеді.',
                      style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final booking = bookings[isPendingTab ? i - 1 : i];
          return _BookingCard(
            booking: booking,
            showCancel: showCancel,
            onCancel: () => _cancelBooking(booking),
          );
        },
      ),
    );
  }
}

// ─── BOOKING CARD ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool showCancel;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.showCancel,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed': return const Color(0xFF00D9A5);
      case 'pending':   return const Color(0xFFFFB347);
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red.shade400;
      default:          return Colors.white54;
    }
  }

  IconData get _typeIcon {
    switch (booking.itemType) {
      case 'instrument': return Icons.music_note;
      case 'stage':      return Icons.theater_comedy;
      case 'studio':     return Icons.mic;
      default:           return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'ru');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: _statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.itemTypeText,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                      Text(
                        'ID: ${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}...',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    booking.statusText,
                    style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(Icons.calendar_today, 'Басталу', fmt.format(booking.startDate)),
                const SizedBox(height: 8),
                _row(Icons.event_available, 'Аяқталу', fmt.format(booking.endDate)),
                const SizedBox(height: 8),
                _row(
                  Icons.access_time,
                  'Ұзақтығы',
                  '${booking.duration} ${booking.durationType == 'day' ? 'күн' : 'сағат'}',
                ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Жалпы сома', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                    Text(
                      '${booking.totalPrice.toInt()} ₸',
                      style: const TextStyle(color: Color(0xFFE94560), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel button
          if (showCancel)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFE94560)),
                  label: const Text('Брондауды болдырмау', style: TextStyle(color: Color(0xFFE94560), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: const Color(0xFFE94560).withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE94560)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
