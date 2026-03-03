import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int? _openIndex;

  static const _sections = [
    _FaqSection(
      icon: Icons.calendar_month_rounded,
      title: 'Брондау',
      color: Color(0xFFE94560),
      items: [
        _FaqItem(
          q: 'Қалай брондауға болады?',
          a: 'Студия, сахна немесе аспапты таңдаңыз → мәліметтер бетінде "Брондау" батырмасын басыңыз → күндер мен уақытты белгілеңіз → төлем экранына өтіңіз.',
        ),
        _FaqItem(
          q: 'Брондау расталмаса не болады?',
          a: 'Сатушы 24 сағат ішінде қабылдамаса, брондау автоматты түрде болдырылмайды және ақша қайтарылады.',
        ),
        _FaqItem(
          q: 'Брондауды болдырмауға бола ма?',
          a: 'Иә. "Брондауларым" бетінде тиісті брондауды ашып, "Болдырмау" батырмасын басыңыз. Болдырмау саясаты сатушының шарттарына байланысты.',
        ),
        _FaqItem(
          q: 'Брондаудың статустары қандай?',
          a: 'Күтуде — сатушы растауын күтуде.\nБелсенді — сатушы қабылдады, брондау жарамды.\nӨткен — аяқталған брондаулар.\nБолдырылмаған — қабылданбаған немесе болдырылмаған.',
        ),
      ],
    ),
    _FaqSection(
      icon: Icons.payment_rounded,
      title: 'Төлем',
      color: Color(0xFF00D9A5),
      items: [
        _FaqItem(
          q: 'Қандай төлем әдістері бар?',
          a: 'Банк картасы (Visa / Mastercard), Kaspi Pay және QR-код арқылы төлем қолданылады.',
        ),
        _FaqItem(
          q: 'Төлем жасасам бірден брондау расталады ма?',
          a: 'Жоқ. Төлем жасалғаннан кейін брондау "Күтуде" статусында қалады. Сатушы растағаннан кейін ғана "Белсенді" болады.',
        ),
        _FaqItem(
          q: 'Ақшаны қайтару мүмкін бе?',
          a: 'Сатушы брондауды қабылдамаса немесе болдырмаса, толық сома қайтарылады. Қайтару мерзімі 3-5 жұмыс күні.',
        ),
        _FaqItem(
          q: 'Тест карта деректері қандай?',
          a: 'Тест режимінде: 4242 4242 4242 4242, мерзімі 12/26, CVV 123.',
        ),
      ],
    ),
    _FaqSection(
      icon: Icons.storefront_rounded,
      title: 'Сатушыларға',
      color: Color(0xFF533483),
      items: [
        _FaqItem(
          q: 'Сатушы болу үшін не істеу керек?',
          a: 'Профиль → "Сатушы болу" → өтінімді толтырыңыз. Администратор тексергеннен кейін сатушы рөлі беріледі.',
        ),
        _FaqItem(
          q: 'Брондауды қалай қабылдаймын немесе қабылдамаймын?',
          a: '"Брондаулар" бетіне өтіп, тиісті брондауды ашыңыз. "Қабылдау" немесе "Қабылдамау" батырмасын басыңыз. Қабылдамаған жағдайда себебін жазу міндетті.',
        ),
        _FaqItem(
          q: 'Бірнеше тізім қосуға бола ма?',
          a: 'Иә, сатушы ретінде студиялар, сахналар және аспаптар қоса аласыз. Лимит жоқ.',
        ),
        _FaqItem(
          q: 'Тізімді өзгертуге немесе жоюға бола ма?',
          a: 'Иә. Дүкен бетінде тізімнің қасындағы мәзірден өзгерту немесе жою опциясын таңдаңыз.',
        ),
      ],
    ),
    _FaqSection(
      icon: Icons.shield_rounded,
      title: 'Қауіпсіздік',
      color: Color(0xFF5B4FE9),
      items: [
        _FaqItem(
          q: 'Деректерім қорғалған ба?',
          a: 'Барлық деректер шифрланып сақталады. Картаңыздың толық нөмірі серверде сақталмайды.',
        ),
        _FaqItem(
          q: 'Электрондық поштаны қайтарып растауға бола ма?',
          a: 'Иә. Тіркелу кезінде расталмаса, профиль бетінен хат қайта жіберуге болады.',
        ),
        _FaqItem(
          q: 'Шот бұзылса не істеу керек?',
          a: 'Дереу құпия сөзді өзгертіңіз (Профиль → Құпия сөзді өзгерту). Байланыс формасы арқылы қолдау қызметіне хабарлаңыз.',
        ),
      ],
    ),
    _FaqSection(
      icon: Icons.help_outline_rounded,
      title: 'Жалпы сұрақтар',
      color: Color(0xFFFF9800),
      items: [
        _FaqItem(
          q: 'Қолданбаны тегін пайдалануға бола ма?',
          a: 'Иә, тіркелу және шолу тегін. Тек брондау кезінде ғана төлем алынады.',
        ),
        _FaqItem(
          q: 'Таңдаулыларды қалай сақтаймын?',
          a: 'Кез келген тізімнің жанындағы жүрек белгісін басыңыз. Барлық сақталғандар Профиль → "Таңдаулылар" бетінде.',
        ),
        _FaqItem(
          q: 'Сатушымен хабарласу мүмкін бе?',
          a: 'Иә. Тізімнің мәліметтер бетіндегі "Хабарлама жазу" батырмасы арқылы тікелей чатқа кіруге болады.',
        ),
        _FaqItem(
          q: 'Техникалық қолдауға қалай хабарласамын?',
          a: 'Профиль бетінің төменгі жағындағы "Қолдау" арқылы немесе rentmuss@support.kz мекенжайына хат жіберіңіз.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({_FaqSection section, List<({int globalIdx, _FaqItem item})> items})> get _filtered {
    final q = _query.toLowerCase().trim();
    int idx = 0;
    return _sections.map((section) {
      final matchItems = section.items
          .map((item) => (globalIdx: idx++, item: item))
          .where((e) =>
              q.isEmpty ||
              e.item.q.toLowerCase().contains(q) ||
              e.item.a.toLowerCase().contains(q))
          .toList();
      return (section: section, items: matchItems);
    }).where((s) => s.items.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: const CustomAppBar(title: 'Көмек & FAQ'),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: sections.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      for (final s in sections) ...[
                        _buildSectionHeader(s.section),
                        const SizedBox(height: 8),
                        for (final e in s.items)
                          _buildItem(e.globalIdx, e.item, s.section.color),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => setState(() {
          _query = v;
          _openIndex = null;
        }),
        decoration: InputDecoration(
          hintText: 'Сұрақ іздеу...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE94560), size: 20),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() {
                    _searchController.clear();
                    _query = '';
                    _openIndex = null;
                  }),
                  child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.4), size: 18),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(_FaqSection section) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: section.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(section.icon, color: section.color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          section.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int index, _FaqItem item, Color accent) {
    final isOpen = _openIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _openIndex = isOpen ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
            width: isOpen ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.q,
                      style: TextStyle(
                        color: isOpen ? Colors.white : Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: isOpen ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? accent : Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (isOpen) ...[
              Divider(
                height: 1,
                color: accent.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text(
                  item.a,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            '"$_query" бойынша нәтиже жоқ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FaqSection {
  final IconData icon;
  final String title;
  final Color color;
  final List<_FaqItem> items;
  const _FaqSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}
