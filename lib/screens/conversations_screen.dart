import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  static const _bg     = Color(0xFF1A1A2E);
  static const _card   = Color(0xFF16213E);
  static const _accent = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = result['conversations'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _conversations.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _accent,
                          backgroundColor: _card,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _conversations.length,
                            itemBuilder: (ctx, i) => _buildConversationTile(_conversations[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Хабарламалар',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Сатушылармен сөйлесулер',
                    style: TextStyle(color: _accent, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.6), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(dynamic conv) {
    final otherUser = conv['otherUser'];
    final name = otherUser?['username'] ?? 'Пайдаланушы';
    final lastMsg = conv['lastMessage'];
    final content = lastMsg?['content'] ?? '';
    final isMine = lastMsg?['isMine'] ?? false;
    final createdAt = lastMsg?['createdAt'] != null
        ? DateTime.tryParse(lastMsg['createdAt'])
        : null;
    final unread = (conv['unread'] ?? 0) as int;
    final itemName = conv['itemName'];
    final receiverId = otherUser?['_id'] ?? '';
    final itemId = conv['itemId'];
    final itemType = conv['itemType'];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: receiverId,
              receiverName: name,
              itemId: itemId,
              itemType: itemType,
              itemName: itemName,
            ),
          ),
        );
        _load(); // Refresh unread counts on return
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread > 0
                ? _accent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accent, Color(0xFFFF6B85)]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            color: unread > 0 ? _accent : Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  if (itemName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      itemName,
                      style: TextStyle(color: _accent.withValues(alpha: 0.7), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isMine)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all_rounded,
                              size: 14, color: Colors.white.withValues(alpha: 0.35)),
                        ),
                      Expanded(
                        child: Text(
                          content,
                          style: TextStyle(
                            color: unread > 0
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                            fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 50, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          Text('Хабарламалар жоқ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Сатушыға хабарлама жіберіңіз',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    if (msgDay == today) return '$h:$m';
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Кеше';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }
}
