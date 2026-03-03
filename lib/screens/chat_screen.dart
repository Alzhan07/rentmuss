import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? itemId;
  final String? itemType;
  final String? itemName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.itemId,
    this.itemType,
    this.itemName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _bg      = Color(0xFF1A1A2E);
  static const _card    = Color(0xFF16213E);
  static const _accent  = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();
  final FocusNode             _inputFocus = FocusNode();

  List<dynamic> _messages    = [];
  bool          _loading     = true;
  bool          _sending     = false;
  String?       _myId;
  bool          _atBottom    = true;
  int           _newMsgCount = 0;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final max     = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.offset;
    final wasAtBottom = _atBottom;
    _atBottom = (max - current) < 80;
    if (_atBottom && !wasAtBottom) {
      setState(() => _newMsgCount = 0);
    }
  }

  Future<void> _init() async {
    final user = await ApiService.getSavedUser();
    setState(() => _myId = user?.id);
    await _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(silent: true),
    );
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final result = await ApiService.getMessages(widget.receiverId, itemId: widget.itemId);
    if (!mounted) return;

    final newMsgs = result['messages'] as List? ?? [];
    final hadNew  = newMsgs.length > _messages.length && _messages.isNotEmpty;

    setState(() {
      if (hadNew && !_atBottom) _newMsgCount += newMsgs.length - _messages.length;
      _messages = newMsgs;
      _loading  = false;
    });

    if (_atBottom || !silent) _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputCtrl.clear();

    final result = await ApiService.sendMessage(
      receiverId: widget.receiverId,
      content:    text,
      itemId:     widget.itemId,
      itemType:   widget.itemType,
      itemName:   widget.itemName,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (result['success'] == true) {
      await _loadMessages(silent: true);
      _scrollToBottom(force: true);
    } else {
      _inputCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хабарлама жіберілмеді'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom({bool force = false}) {
    if (!force && !_atBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMine(dynamic msg) {
    final id = msg['sender'] is Map ? msg['sender']['_id'] : msg['sender'];
    return id == _myId;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameSenderAsPrev(int i) {
    if (i == 0) return false;
    final cur  = _messages[i];
    final prev = _messages[i - 1];
    final cId  = cur['sender']  is Map ? cur['sender']['_id']  : cur['sender'];
    final pId  = prev['sender'] is Map ? prev['sender']['_id'] : prev['sender'];
    return cId == pId;
  }

  bool _isLastInGroup(int i) {
    if (i == _messages.length - 1) return true;
    final cur  = _messages[i];
    final next = _messages[i + 1];
    final cId  = cur['sender']  is Map ? cur['sender']['_id']  : cur['sender'];
    final nId  = next['sender'] is Map ? next['sender']['_id'] : next['sender'];
    return cId != nId;
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.itemName != null) _buildItemBanner(),
          Expanded(
            child: Stack(
              children: [
                _loading
                    ? const Center(child: CircularProgressIndicator(color: _accent))
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              bool showDate = i == 0;
                              if (!showDate) {
                                final prev = DateTime.tryParse(_messages[i - 1]['createdAt'] ?? '');
                                final curr = DateTime.tryParse(_messages[i]['createdAt'] ?? '');
                                if (prev != null && curr != null) showDate = !_isSameDay(prev, curr);
                              }
                              return Column(
                                children: [
                                  if (showDate) _buildDateDivider(_messages[i]['createdAt']),
                                  _buildBubble(i),
                                ],
                              );
                            },
                          ),

                // "New messages" pill
                if (_newMsgCount > 0)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _scrollToBottom(force: true);
                          setState(() => _newMsgCount = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$_newMsgCount жаңа хабарлама',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      titleWidget: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_accent, Color(0xFFFF6B85)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.itemName != null)
                  Text(
                    widget.itemName!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        border: Border(bottom: BorderSide(color: _accent.withValues(alpha: 0.14))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_typeIcon(), color: _accent, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(),
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.65),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  widget.itemName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String? createdAt) {
    final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
    if (dt == null) return const SizedBox.shrink();

    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);

    final String label;
    if (day == today) {
      label = 'Бүгін';
    } else if (day == today.subtract(const Duration(days: 1))) {
      label = 'Кеше';
    } else {
      label = '${dt.day} ${_monthName(dt.month)} ${dt.year != now.year ? dt.year : ""}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Text(
              label.trim(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
        ],
      ),
    );
  }

  Widget _buildBubble(int index) {
    final msg       = _messages[index];
    final mine      = _isMine(msg);
    final samesPrev = _sameSenderAsPrev(index);
    final isLast    = _isLastInGroup(index);

    final time = msg['createdAt'] != null
        ? _formatTime(DateTime.parse(msg['createdAt']))
        : '';

    return Padding(
      padding: EdgeInsets.only(top: samesPrev ? 2 : 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left avatar (other person)
          if (!mine) ...[
            SizedBox(
              width: 30,
              child: isLast
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accent, Color(0xFFFF6B85)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.receiverName.isNotEmpty
                              ? widget.receiverName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: 28),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: mine
                    ? const LinearGradient(
                        colors: [Color(0xFFE94560), Color(0xFFD03050)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: mine ? null : _card,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(mine ? 18 : (isLast ? 4 : 18)),
                  bottomRight: Radius.circular(mine ? (isLast ? 4 : 18) : 18),
                ),
                border: mine
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.07)),
                boxShadow: [
                  BoxShadow(
                    color: (mine ? _accent : Colors.black)
                        .withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: mine
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.92),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  if (isLast) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: mine
                                ? Colors.white.withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Right spacer (keeps mine bubbles from hugging the edge)
          if (mine) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withValues(alpha: 0.2), width: 1.5),
              ),
              child: const Icon(Icons.waving_hand_rounded, size: 44, color: _accent),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.receiverName}-ға хабарлама жіберіңіз',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Бұл сіздің алғашқы хабарламаңыз болады',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: _card,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _inputFocus,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Хабарлама...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 14.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final active = _inputCtrl.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: _sendMessage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [_accent, Color(0xFFFF6B85)])
              : null,
          color: active ? null : _surface.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: _sending
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.send_rounded,
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.25),
                size: 20,
              ),
      ),
    );
  }

  IconData _typeIcon() {
    switch (widget.itemType) {
      case 'stage':  return Icons.theater_comedy_outlined;
      case 'studio': return Icons.mic_outlined;
      default:       return Icons.piano;
    }
  }

  String _typeLabel() {
    switch (widget.itemType) {
      case 'stage':  return 'САХНА';
      case 'studio': return 'СТУДИЯ';
      default:       return 'АСПАП';
    }
  }

  String _monthName(int m) {
    const months = [
      '', 'қаң', 'ақп', 'нау', 'сәу', 'мам', 'мау',
      'шіл', 'там', 'қыр', 'қаз', 'қар', 'жел',
    ];
    return months[m];
  }

  String _formatTime(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (day == today) return '$h:$m';
    if (day == today.subtract(const Duration(days: 1))) return 'Кеше $h:$m';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')} $h:$m';
  }
}
