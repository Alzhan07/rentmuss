import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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
                  'Сатушы: ${application['username']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Дүкен: ${application['sellerInfo']?['shopName'] ?? 'Берілмеген'}',
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
                    ? const Center(
                      child: Text(
                        'Өтінімдер табылмады',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredApplications.length,
                      itemBuilder:
                          (context, index) => _buildApplicationCard(
                            _filteredApplications[index],
                          ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(12),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: const Color(0xFFE94560),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white54),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final sellerApp = application['sellerApplication'];
    final sellerInfo = application['sellerInfo'];

    final status = sellerApp?['status'] ?? 'none';
    final appliedAt = sellerApp?['appliedAt']?['\$date'];
    final createdAt = application['createdAt']?['\$date'];
    final updatedAt = application['updatedAt']?['\$date'];

    final shopName = sellerInfo?['shopName'] ?? 'Берілмеген';
    final shopDescription = sellerInfo?['shopDescription'] ?? 'Сипаттама жоқ';

    return Card(
      color: Colors.white.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, 'Сатушы', application['username']),
            _buildInfoRow(
              Icons.email,
              'Email',
              application['email'] ?? 'Берілмеген',
            ),
            _buildInfoRow(Icons.store, 'Дүкен', shopName),
            _buildInfoRow(Icons.description, 'Сипаттама', shopDescription),

            if (appliedAt != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Өтініш берілді',
                _formatDate(appliedAt),
              ),

            if (createdAt != null)
              _buildInfoRow(
                Icons.date_range,
                'Тіркелген күні',
                _formatDate(createdAt),
              ),

            if (updatedAt != null)
              _buildInfoRow(
                Icons.update,
                'Соңғы жаңарту',
                _formatDate(updatedAt),
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'pending')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReviewDialog(application, true),
                      child: const Text('Қабылдау'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                if (status == 'pending') const SizedBox(width: 8),
                if (status == 'pending')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReviewDialog(application, false),
                      child: const Text('Бас тарту'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateObj) {
    if (dateObj is Map && dateObj.containsKey('\$date')) {
      dateObj = dateObj['\$date'];
    }

    try {
      DateTime date;

      if (dateObj is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateObj);
      } else if (dateObj is String) {
        date = DateTime.tryParse(dateObj) ?? DateTime.now();
      } else {
        return dateObj.toString();
      }

      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return dateObj.toString();
    }
  }
}
