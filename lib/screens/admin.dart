import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getSellerApplications();
    setState(() {
      if (result['success']) {
        _applications = List<Map<String, dynamic>>.from(
          result['applications'] ?? [],
        );
      }
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_filterStatus == 'all') return _applications;
    return _applications.where((app) {
      final status = app['sellerApplication']?['status'] ?? 'none';
      return status == _filterStatus;
    }).toList();
  }

  Future<void> _reviewApplication({
    required String userId,
    required bool approved,
    String? rejectionReason,
  }) async {
    final result = await ApiService.reviewSellerApplication(
      userId: userId,
      approved: approved,
      rejectionReason: rejectionReason,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Операция орындалды'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      _loadApplications();
    }
  }

  void _showReviewDialog(Map<String, dynamic> application, bool approve) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: Text(
              approve
                  ? 'Өтінімді қабылдайсыз ба?'
                  : 'Өтінімді қабылдамайсыз ба?',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сатушы: ${application['username'] ?? 'Имя не указано'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Дүкен: ${application['sellerApplication']?['shopName'] ?? 'Берілмеген'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                if (!approve) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Бас тарту себебі',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      hintText: 'Өтінімді қабылдамау себебін көрсетіңіз',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE94560),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Бас тарту',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reviewApplication(
                    userId: application['_id']?['\$oid'],
                    approved: approve,
                    rejectionReason: approve ? null : reasonController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: approve ? Colors.green : Colors.red,
                ),
                child: Text(approve ? 'Қабылдау' : 'Бас тарту'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text(
          'Админ-панель',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadApplications,
          ),
        ],
      ),

      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE94560),
                      ),
                    )
                    : _filteredApplications.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Өтінімдер табылмады',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredApplications.length,
                      itemBuilder: (context, index) {
                        return _buildApplicationCard(
                          _filteredApplications[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Барлығы', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Қаралуда', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Қабылданған', 'approved'),
            const SizedBox(width: 8),
            _buildFilterChip('Бас тартылған', 'rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: const Color(0xFFE94560),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color:
            isSelected
                ? const Color(0xFFE94560)
                : Colors.white.withOpacity(0.2),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final sellerApp = application['sellerApplication'];
    final sellerInfo = application['sellerInfo'];

    final status = sellerApp?['status'] ?? 'none';

    // Правильная обработка даты из MongoDB
    DateTime? appliedAt;
    try {
      final dateValue = sellerApp?['appliedAt'];
      if (dateValue != null) {
        if (dateValue is String) {
          appliedAt = DateTime.parse(dateValue);
        } else if (dateValue is Map && dateValue.containsKey('\$date')) {
          final dateData = dateValue['\$date'];
          if (dateData is int) {
            appliedAt = DateTime.fromMillisecondsSinceEpoch(dateData);
          } else if (dateData is String) {
            appliedAt = DateTime.parse(dateData);
          }
        } else if (dateValue is DateTime) {
          appliedAt = dateValue;
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
      appliedAt = null;
    }

    final shopName = sellerInfo?['shopName'] ?? 'Берілмеген';
    final shopDescription =
        sellerInfo?['shopDescription'] ?? 'Сипаттама берілмеген';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Қаралуда';
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Қабылданған';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Бас тартылған';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Белгісіз';
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFFE94560),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application['username'] ?? 'Имя не указано',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application['email'] ?? 'Email берілмеген',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.store, 'Дүкен атауы', shopName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.description, 'Сипаттама', shopDescription),
            if (appliedAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Берілген күні',
                _formatDate(appliedAt),
              ),
            ],
            if (sellerApp?['rejectionReason'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.error_outline,
                'Бас тарту себебі',
                sellerApp['rejectionReason'],
                isError: true,
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(application, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Бас тарту'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(application, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Қабылдау'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isError ? Colors.red : Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isError ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Дата не указана';

    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return 'Неверная дата';
    }
  }
}
