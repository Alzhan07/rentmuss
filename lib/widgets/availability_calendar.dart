import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AvailabilityCalendar extends StatefulWidget {
  final String itemId;
  final String itemType;

  const AvailabilityCalendar({
    super.key,
    required this.itemId,
    required this.itemType,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  Set<String> _bookedDates = {};
  bool _loading = true;
  DateTime _displayMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    setState(() => _loading = true);
    final dates = await ApiService.getBookedDates(
      itemId: widget.itemId,
      itemType: widget.itemType,
    );
    setState(() {
      _bookedDates = dates.map((d) => _key(d)).toSet();
      _loading = false;
    });
  }

  String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isBooked(DateTime day) => _bookedDates.contains(_key(day));
  bool _isPast(DateTime day) => day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  void _prevMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));
  void _nextMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Қолжетімділік',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE94560)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('MMMM yyyy', 'ru').format(_displayMonth),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          
          Row(
            children: ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жк']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          
          _buildCalendarGrid(),
          const SizedBox(height: 16),

          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF00D9A5), 'Бос'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFE94560), 'Брондалған'),
              const SizedBox(width: 20),
              _legend(Colors.white24, 'Өтіп кеткен'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    
    int startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox());
              }

              final day = DateTime(_displayMonth.year, _displayMonth.month, dayNum);
              final booked = _isBooked(day);
              final past = _isPast(day);
              final isToday = _key(day) == _key(DateTime.now());

              Color bg;
              Color textColor;

              if (past) {
                bg = Colors.transparent;
                textColor = Colors.white24;
              } else if (booked) {
                bg = const Color(0xFFE94560).withValues(alpha: 0.2);
                textColor = const Color(0xFFE94560);
              } else {
                bg = const Color(0xFF00D9A5).withValues(alpha: 0.1);
                textColor = const Color(0xFF00D9A5);
              }

              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.white54, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}
