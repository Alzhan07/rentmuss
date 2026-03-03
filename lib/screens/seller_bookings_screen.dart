import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

const Color _bg = Color(0xFF1A1A2E);
const Color _card = Color(0xFF16213E);
const Color _accent = Color(0xFFE94560);

class SellerBookingsScreen extends StatefulWidget {
  const SellerBookingsScreen({super.key});

  @override
  State<SellerBookingsScreen> createState() => _SellerBookingsScreenState();
}

class _SellerBookingsScreenState extends State<SellerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _pending = [];
  List<Booking> _active = [];
  List<Booking> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getSellerBookings();
    if (result['success'] == true) {
      final all = (result['bookings'] as List)
          .map((j) => Booking.fromJson(j))
          .toList();
      setState(() {
        _pending = all.where((b) => b.isPending).toList();
        _active = all.where((b) => b.isConfirmed).toList();
        _history = all.where((b) => b.isCompleted || b.isCancelled).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(Booking booking) async {
    final result = await ApiService.updateBookingStatus(booking.id, 'confirmed');
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бронирование подтверждено'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Қате орын алды'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(Booking booking) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Бас тарту себебі',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Себебін жазыңыз...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Себебін жазыңыз' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Болдырмау',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Бас тарту'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final result = await ApiService.updateBookingStatus(
      booking.id,
      'cancelled',
      rejectionReason: reasonController.text.trim(),
    );
    reasonController.dispose();
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бронирование отклонено'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Қате орын алды'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: CustomAppBar(
        title: 'Брондаулар',
        bottomWidget: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: _accent,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          tabs: [
            Tab(text: 'Жаңа (${_pending.length})'),
            Tab(text: 'Белсенді (${_active.length})'),
            const Tab(text: 'Тарих'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending, showActions: true),
                _buildList(_active, showActions: false),
                _buildList(_history, showActions: false),
              ],
            ),
    );
  }

  Widget _buildList(List<Booking> bookings, {required bool showActions}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Брондаулар жоқ',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, i) =>
            _buildCard(bookings[i], showActions: showActions),
      ),
    );
  }

  Widget _buildCard(Booking booking, {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: item type badge + status chip
            Row(
              children: [
                _typeBadge(booking.itemTypeText),
                const Spacer(),
                _statusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),

            // Dates
            _infoRow(Icons.calendar_today_rounded,
                '${_fmt(booking.startDate)} — ${_fmt(booking.endDate)}'),
            const SizedBox(height: 6),

            // Duration + price
            _infoRow(
              Icons.access_time_rounded,
              '${booking.duration} ${booking.durationType == 'hour' ? 'сағ' : 'күн'}  •  ${booking.totalPrice.toStringAsFixed(0)} ₸',
            ),

            // Notes
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.notes_rounded, booking.notes!),
            ],

            // Rejection reason
            if (booking.rejectionReason != null &&
                booking.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.rejectionReason!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (showActions) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(booking),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Бас тарту'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _accept(booking),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Қабылдау'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Күтуде';
        break;
      case 'confirmed':
        color = const Color(0xFF2ECC71);
        label = 'Расталған';
        break;
      case 'completed':
        color = Colors.blueAccent;
        label = 'Аяқталған';
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = 'Болдырылмаған';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.white38),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
