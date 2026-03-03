import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class ModeratorScreen extends StatefulWidget {
  const ModeratorScreen({super.key});

  @override
  State<ModeratorScreen> createState() => _ModeratorScreenState();
}

class _ModeratorScreenState extends State<ModeratorScreen>
    with SingleTickerProviderStateMixin {
  static const _bg      = Color(0xFF1A1A2E);
  static const _card    = Color(0xFF16213E);
  static const _accent  = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  late TabController _tab;

  List<Map<String, dynamic>> _applications = [];
  List<dynamic> _removed = [];
  List<dynamic> _appeals = [];

  bool _loadingApps     = true;
  bool _loadingRemoved  = true;
  bool _loadingAppeals  = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() {}); });
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadApplications();
    _loadRemoved();
    _loadAppeals();
  }

  Future<void> _loadApplications() async {
    setState(() => _loadingApps = true);
    final r = await ApiService.getSellerApplications();
    if (mounted) {
      setState(() {
        _applications = List<Map<String, dynamic>>.from(r['applications'] ?? []);
        _loadingApps  = false;
      });
    }
  }

  Future<void> _loadRemoved() async {
    setState(() => _loadingRemoved = true);
    final r = await ApiService.moderationGetRemoved();
    if (mounted) setState(() { _removed = r['removed'] ?? []; _loadingRemoved = false; });
  }

  Future<void> _loadAppeals() async {
    setState(() => _loadingAppeals = true);
    final r = await ApiService.moderationGetAppeals();
    if (mounted) setState(() { _appeals = r['appeals'] ?? []; _loadingAppeals = false; });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: CustomAppBar(
        title: 'Модератор панелі',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _card,
            child: TabBar(
              controller: _tab,
              indicatorColor: _accent,
              labelColor: _accent,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(
                  text: 'Өтінімдер',
                  icon: Badge(
                    isLabelVisible: _applications.where((a) => a['sellerApplication']?['status'] == 'pending').isNotEmpty,
                    label: Text('${_applications.where((a) => a['sellerApplication']?['status'] == 'pending').length}'),
                    child: const Icon(Icons.store_outlined, size: 20),
                  ),
                ),
                Tab(
                  text: 'Алынған',
                  icon: Badge(
                    isLabelVisible: _removed.isNotEmpty,
                    label: Text('${_removed.length}'),
                    child: const Icon(Icons.hide_source_outlined, size: 20),
                  ),
                ),
                Tab(
                  text: 'Апелляция',
                  icon: Badge(
                    isLabelVisible: _appeals.isNotEmpty,
                    label: Text('${_appeals.length}'),
                    child: const Icon(Icons.gavel_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildApplicationsTab(),
                _buildRemovedTab(),
                _buildAppealsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Seller applications ──────────────────────────────────────────
  Widget _buildApplicationsTab() {
    if (_loadingApps) return _spinner();
    final pending = _applications.where((a) => a['sellerApplication']?['status'] == 'pending').toList();
    final others  = _applications.where((a) => a['sellerApplication']?['status'] != 'pending').toList();
    final all     = [...pending, ...others];
    if (all.isEmpty) return _empty('Өтінімдер жоқ', Icons.inbox_outlined);
    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: _accent,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: all.length,
        itemBuilder: (_, i) => _appCard(all[i]),
      ),
    );
  }

  Widget _appCard(Map<String, dynamic> app) {
    final sellerApp  = app['sellerApplication'];
    final sellerInfo = app['sellerInfo'];
    final status     = sellerApp?['status'] ?? 'none';

    final Color  statusColor;
    final String statusLabel;
    switch (status) {
      case 'pending':  statusColor = Colors.orange;        statusLabel = 'Қаралуда'; break;
      case 'approved': statusColor = Colors.green;         statusLabel = 'Қабылданды'; break;
      case 'rejected': statusColor = Colors.red;           statusLabel = 'Бас тартылды'; break;
      default:         statusColor = Colors.grey;          statusLabel = 'Белгісіз';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['username'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(app['email'] ?? '',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (sellerInfo?['shopName'] != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            _infoRow(Icons.store, 'Дүкен', sellerInfo['shopName']),
            if (sellerInfo['shopDescription'] != null && sellerInfo['shopDescription'].isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.description, 'Сипаттама', sellerInfo['shopDescription']),
            ],
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectAppDialog(app),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Бас тарту'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewApp(app, true, null),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Қабылдау'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectAppDialog(Map<String, dynamic> app) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Бас тарту себебі', style: TextStyle(color: Colors.white)),
        content: _reasonField(ctrl, 'Себепті жазыңыз...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Жою', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewApp(app, false, ctrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Бас тарту'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewApp(Map<String, dynamic> app, bool approve, String? reason) async {
    final id = app['_id'] is String ? app['_id'] : app['_id']?['\$oid'];
    if (id == null) return;
    final r = await ApiService.reviewSellerApplication(
        userId: id, approved: approve, rejectionReason: reason);
    if (!mounted) return;
    _showSnack(r['message'] ?? '', r['success'] == true);
    if (r['success'] == true) _loadApplications();
  }

  // ─── Tab 2: Removed listings ──────────────────────────────────────────────
  Widget _buildRemovedTab() {
    if (_loadingRemoved) return _spinner();
    if (_removed.isEmpty) return _empty('Алынған жарнамалар жоқ', Icons.check_circle_outline);
    return RefreshIndicator(
      onRefresh: _loadRemoved,
      color: _accent,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _removed.length,
        itemBuilder: (_, i) => _removedCard(_removed[i]),
      ),
    );
  }

  Widget _removedCard(dynamic item) {
    final mod     = item['moderation'] as Map? ?? {};
    final appeal  = mod['appeal'] as Map? ?? {};
    final type    = item['_listingType'] ?? 'instrument';
    final hasAppeal = appeal['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAppeal
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(type), color: Colors.red, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(_typeLabel(type),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                  ],
                ),
              ),
              if (hasAppeal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: const Text('АПЕЛЛЯЦИЯ',
                      style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.info_outline, 'Себеп', mod['removalReason'] ?? '—'),
          if (mod['removedAt'] != null) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.calendar_today_outlined, 'Алынған күн',
                _fmt(mod['removedAt'])),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _doRestore(type, item['_id'].toString()),
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Жариялауға қайтару'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doRestore(String type, String id) async {
    final r = await ApiService.moderationRestore(type, id);
    if (!mounted) return;
    _showSnack(r['message'] ?? '', r['success'] == true);
    if (r['success'] == true) { _loadRemoved(); _loadAppeals(); }
  }

  // ─── Tab 3: Appeals ───────────────────────────────────────────────────────
  Widget _buildAppealsTab() {
    if (_loadingAppeals) return _spinner();
    if (_appeals.isEmpty) return _empty('Апелляциялар жоқ', Icons.gavel_outlined);
    return RefreshIndicator(
      onRefresh: _loadAppeals,
      color: _accent,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appeals.length,
        itemBuilder: (_, i) => _appealCard(_appeals[i]),
      ),
    );
  }

  Widget _appealCard(dynamic item) {
    final mod    = item['moderation'] as Map? ?? {};
    final appeal = mod['appeal'] as Map? ?? {};
    final type   = item['_listingType'] ?? 'instrument';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(type), color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${item['ownerName'] ?? ''} · ${_typeLabel(type)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          _infoRow(Icons.block_outlined, 'Алыну себебі', mod['removalReason'] ?? '—'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.gavel, color: Colors.orange, size: 14),
                  const SizedBox(width: 6),
                  Text('Апелляция мәтіні',
                      style: TextStyle(color: Colors.orange.withValues(alpha: 0.8),
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(appeal['message'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _resolveAppeal(type, item['_id'].toString(), false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Бас тарту'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resolveAppeal(type, item['_id'].toString(), true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Қабылдау'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAppeal(String type, String id, bool restore) async {
    final r = await ApiService.moderationResolveAppeal(type, id, restore);
    if (!mounted) return;
    _showSnack(r['message'] ?? '', r['success'] == true);
    if (r['success'] == true) { _loadAppeals(); _loadRemoved(); }
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────
  Widget _spinner() =>
      const Center(child: CircularProgressIndicator(color: _accent));

  Widget _empty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text(text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                TextSpan(text: value,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reasonField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: _surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'stage':  return Icons.theater_comedy_outlined;
      case 'studio': return Icons.mic_outlined;
      default:       return Icons.piano_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'stage':  return 'Сахна';
      case 'studio': return 'Студия';
      default:       return 'Аспап';
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(v.toString()));
    } catch (_) {
      return v.toString();
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }
}
