import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final String itemName;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.itemName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = 'card';
  bool _isProcessing = false;
  bool _isDone = false;
  bool _isSuccess = false;
  String _transactionId = '';

  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _cardLastFour {
    final digits = _cardNumberController.text.replaceAll(' ', '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : '';
  }

  bool get _isCardValid {
    if (_selectedMethod != 'card') return true;
    final digits = _cardNumberController.text.replaceAll(' ', '');
    return digits.length == 16 &&
        _cardHolderController.text.trim().isNotEmpty &&
        _expiryController.text.length == 5 &&
        _cvvController.text.length == 3;
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'card' && !_isCardValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Карта деректерін толтырыңыз'),
          backgroundColor: Color(0xFFE94560),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final result = await ApiService.processPayment(
      bookingId: widget.booking.id,
      method: _selectedMethod,
      cardLastFour: _selectedMethod == 'card' ? _cardLastFour : null,
      cardHolder: _selectedMethod == 'card' ? _cardHolderController.text.trim() : null,
    );

    setState(() {
      _isProcessing = false;
      _isDone = true;
      _isSuccess = result['success'] ?? false;
      if (_isSuccess && result['payment'] != null) {
        _transactionId = result['payment']['transactionId'] ?? '';
      }
    });

    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _isDone ? null : const CustomAppBar(title: 'Төлем'),
      body: _isDone ? _buildResultScreen() : _buildPaymentForm(),
    );
  }

  // ─── PAYMENT FORM ────────────────────────────────────────────────────────────

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 28),
          _buildMethodSelector(),
          const SizedBox(height: 28),
          if (_selectedMethod == 'card') _buildCardForm(),
          if (_selectedMethod == 'kaspi') _buildKaspiInfo(),
          if (_selectedMethod == 'qr') _buildQrInfo(),
          const SizedBox(height: 32),
          _buildPayButton(),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  'Деректеріңіз қорғалған',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFE94560), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Тапсырыс',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Объект', widget.itemName),
          _summaryRow('Тип', widget.booking.itemTypeText),
          _summaryRow(
            'Мерзімі',
            '${dateFormat.format(widget.booking.startDate)} — ${dateFormat.format(widget.booking.endDate)}',
          ),
          _summaryRow(
            'Ұзақтығы',
            '${widget.booking.duration} ${widget.booking.durationType == 'day' ? 'күн' : 'сағат'}',
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Барлығы',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.booking.totalPrice.toInt()} ₸',
                style: const TextStyle(color: Color(0xFFE94560), fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Төлем әдісі',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _methodChip('card', Icons.credit_card, 'Карта'),
            const SizedBox(width: 10),
            _methodChip('kaspi', Icons.account_balance_wallet, 'Kaspi'),
            const SizedBox(width: 10),
            _methodChip('qr', Icons.qr_code, 'QR'),
          ],
        ),
      ],
    );
  }

  Widget _methodChip(String value, IconData icon, String label) {
    final selected = _selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE94560).withValues(alpha: 0.15)
                : const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFE94560) : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFFE94560) : Colors.white54, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFFE94560) : Colors.white54,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _buildInput(
          controller: _cardNumberController,
          label: 'Карта нөмірі',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
          maxLength: 19,
        ),
        const SizedBox(height: 16),
        _buildInput(
          controller: _cardHolderController,
          label: 'Карта иесі',
          hint: 'IVAN IVANOV',
          icon: Icons.person,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInput(
                controller: _expiryController,
                label: 'Мерзімі',
                hint: 'MM/YY',
                icon: Icons.date_range,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()],
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInput(
                controller: _cvvController,
                label: 'CVV',
                hint: '•••',
                icon: Icons.lock,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Тест: 4242 4242 4242 4242 | 12/26 | 123',
                  style: TextStyle(color: Colors.blue.withValues(alpha: 0.8), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: const Color(0xFFE94560), size: 20),
            filled: true,
            fillColor: const Color(0xFF16213E),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE94560)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKaspiInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet, color: Color(0xFFFF6B00), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Kaspi Pay арқылы төлем',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Kaspi апптық жүйесінде төлем расталады (имитация)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQrInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.qr_code, size: 160, color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'QR кодын сканерлеңіз',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Кез келген банктің апптық жүйесімен\n(имитация)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          disabledBackgroundColor: const Color(0xFFE94560).withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Өңделуде...',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                  ),
                ],
              )
            : Text(
                'Төлеу — ${widget.booking.totalPrice.toInt()} ₸',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ─── RESULT SCREEN ───────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSuccess
                      ? const Color(0xFF00D9A5).withValues(alpha: 0.15)
                      : const Color(0xFFE94560).withValues(alpha: 0.15),
                ),
                child: Icon(
                  _isSuccess ? Icons.check_circle : Icons.cancel,
                  size: 60,
                  color: _isSuccess ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSuccess ? 'Төлем сәтті өтті!' : 'Төлем қабылданбады',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_isSuccess) ...[
                Text(
                  '${widget.booking.totalPrice.toInt()} ₸',
                  style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _resultRow('Объект', widget.itemName),
                      _resultRow('Транзакция', _transactionId.isEmpty ? '—' : _transactionId),
                      _resultRow('Күн', DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Брондауыңыз сатушының растауын күтуде. Растаудан кейін белсенді болады.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Картаны тексеріп, қайта көріңіз',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isSuccess) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _isDone = false;
                        _animController.reset();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSuccess ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSuccess ? 'Аяқтау' : 'Қайта көру',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INPUT FORMATTERS ────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
