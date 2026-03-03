import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Applications tab
  List<Map<String, dynamic>> _applications = [];
  bool _isLoadingApps = true;
  String _filterStatus = 'all';

  // Users tab
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1 && _isLoadingUsers) {
          _loadUsers();
        }
      }
    });
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Applications ────────────────────────────────────────────────────────────

  Future<void> _loadApplications() async {
    setState(() => _isLoadingApps = true);
    final result = await ApiService.getSellerApplications();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _applications = List<Map<String, dynamic>>.from(
          result['applications'] ?? [],
        );
      }
      _isLoadingApps = false;
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
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) _loadApplications();
  }

  void _showReviewDialog(Map<String, dynamic> application, bool approve) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          approve ? 'Өтінімді қабылдайсыз ба?' : 'Өтінімді қабылдамайсыз ба?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сатушы: ${application['username'] ?? 'Имя не указано'}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Дүкен: ${application['sellerApplication']?['shopName'] ?? 'Берілмеген'}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            if (!approve) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Бас тарту себебі',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  hintText: 'Өтінімді қабылдамау себебін көрсетіңіз',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE94560), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Бас тарту',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              String? userId;
              if (application['_id'] is String) {
                userId = application['_id'];
              } else if (application['_id'] is Map) {
                userId = application['_id']['\$oid'];
              }
              if (userId != null) {
                _reviewApplication(
                  userId: userId,
                  approved: approve,
                  rejectionReason: approve ? null : reasonController.text,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Қате: ID табылмады'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

  // ── Users / Moderators ───────────────────────────────────────────────────────

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final result = await ApiService.getAllUsers();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _users =
            List<Map<String, dynamic>>.from(result['users'] ?? []);
      }
      _isLoadingUsers = false;
    });
  }

  Future<void> _toggleModerator(Map<String, dynamic> user) async {
    final isMod = (user['role'] ?? '') == 'moderator';
    final newRole = isMod ? 'user' : 'moderator';
    final name = user['username'] ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          isMod
              ? 'Модераторды алып тастау'
              : 'Модератор тағайындау',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isMod
              ? '$name пайдаланушысынан модератор рөлін алып тастайсыз ба?'
              : '$name пайдаланушысына модератор рөлін тағайындайсыз ба?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Жоқ',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isMod ? Colors.orange : const Color(0xFFE94560),
            ),
            child: Text(isMod ? 'Алып тастау' : 'Тағайындау'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    String? userId;
    if (user['_id'] is String) {
      userId = user['_id'];
    } else if (user['_id'] is Map) {
      userId = user['_id']['\$oid'];
    }
    if (userId == null) return;

    final result = await ApiService.assignRole(userId, newRole);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Орындалды'),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) _loadUsers();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: CustomAppBar(
        title: 'Админ-панель',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadApplications();
              } else {
                _loadUsers();
              }
            },
          ),
        ],
        bottomWidget: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Өтінімдер'),
            Tab(icon: Icon(Icons.people_outline), text: 'Пайдаланушылар'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  // ── Applications tab ─────────────────────────────────────────────────────────

  Widget _buildApplicationsTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _isLoadingApps
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE94560)))
              : _filteredApplications.isEmpty
                  ? _emptyState(Icons.inbox_outlined, 'Өтінімдер табылмады')
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      color: const Color(0xFFE94560),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) =>
                            _buildApplicationCard(_filteredApplications[index]),
                      ),
                    ),
        ),
      ],
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
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: const Color(0xFFE94560),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFFE94560)
            : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final sellerApp = application['sellerApplication'];
    final sellerInfo = application['sellerInfo'];
    final status = sellerApp?['status'] ?? 'none';

    DateTime? appliedAt;
    try {
      final dateValue = sellerApp?['appliedAt'];
      if (dateValue is String) {
        appliedAt = DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue.containsKey('\$date')) {
        final d = dateValue['\$date'];
        appliedAt = d is int
            ? DateTime.fromMillisecondsSinceEpoch(d)
            : DateTime.parse(d as String);
      }
    } catch (_) {}

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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: const Color(0xFFE94560).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFFE94560), size: 24),
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
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application['email'] ?? 'Email берілмеген',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _statusBadge(statusIcon, statusText, statusColor),
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
                  Icons.calendar_today, 'Берілген күні', _formatDate(appliedAt)),
            ],
            if (sellerApp?['rejectionReason'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.error_outline, 'Бас тарту себебі',
                  sellerApp['rejectionReason'],
                  isError: true),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showReviewDialog(application, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Бас тарту'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showReviewDialog(application, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Қабылдау'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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

  // ── Users tab ────────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE94560)));
    }
    if (_users.isEmpty) {
      return _emptyState(Icons.people_outline, 'Пайдаланушылар табылмады');
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFFE94560),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) => _buildUserCard(_users[index]),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'user';
    final isMod = role == 'moderator';
    final isSeller = role == 'seller';

    Color roleColor;
    String roleLabel;
    IconData roleIcon;
    if (isMod) {
      roleColor = const Color(0xFFE94560);
      roleLabel = 'Модератор';
      roleIcon = Icons.shield;
    } else if (isSeller) {
      roleColor = Colors.amber;
      roleLabel = 'Сатушы';
      roleIcon = Icons.store;
    } else {
      roleColor = Colors.blueGrey;
      roleLabel = 'Пайдаланушы';
      roleIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMod
              ? const Color(0xFFE94560).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isMod
                      ? [const Color(0xFFE94560), const Color(0xFFD03050)]
                      : [Colors.blueGrey.shade700, Colors.blueGrey.shade500],
                ),
              ),
              child: Center(
                child: Text(
                  (user['username'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'] ?? '—',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '—',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Role badge
            _statusBadge(roleIcon, roleLabel, roleColor),
            const SizedBox(width: 8),
            // Assign / revoke button
            GestureDetector(
              onTap: () => _toggleModerator(user),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isMod
                      ? Colors.orange.withValues(alpha: 0.15)
                      : const Color(0xFFE94560).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMod
                        ? Colors.orange.withValues(alpha: 0.5)
                        : const Color(0xFFE94560).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMod ? Icons.shield_outlined : Icons.add_moderator,
                      size: 14,
                      color: isMod ? Colors.orange : const Color(0xFFE94560),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMod ? 'Алу' : 'Мод.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isMod ? Colors.orange : const Color(0xFFE94560),
                      ),
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

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _statusBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 20,
            color: isError ? Colors.red : Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: isError ? Colors.red : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 18)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Уақыт берілмеген';
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return 'Қате уақыт';
    }
  }
}
