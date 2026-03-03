import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddInstrumentScreen extends StatefulWidget {
  final Map<String, dynamic>? instrument; 

  const AddInstrumentScreen({Key? key, this.instrument}) : super(key: key);

  @override
  State<AddInstrumentScreen> createState() => _AddInstrumentScreenState();
}

class _AddInstrumentScreenState extends State<AddInstrumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pricePerDayController = TextEditingController();

  String _selectedCategory = 'Гитаралар';
  String _selectedCondition = 'Керемет';
  bool _isSubmitting = false;
  bool _hourlyEnabled = false;
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  final List<XFile> _webImages = [];
  List<String> _existingImageUrls = [];

  final List<String> _categories = [
    'Гитаралар',
    'Пернетақталы',
    'Ұрмалы',
    'Үрмелі',
    'Шекті',
    'Бас',
  ];

  final List<String> _conditions = ['Керемет', 'Жақсы', 'Қанағаттанарлық'];

  bool get _isEditing => widget.instrument != null;

  static const _bg = Color(0xFF1A1A2E);
  static const _card = Color(0xFF16213E);
  static const _accent = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  @override
  void initState() {
    super.initState();
    final item = widget.instrument;
    if (item != null) {
      _nameController.text = item['name'] ?? '';
      _brandController.text = item['brand'] ?? '';
      _modelController.text = item['model'] ?? '';
      final day = (item['pricePerDay'] ?? 0).toDouble();
      final hourly = (item['pricePerHour'] ?? 0).toDouble();
      _hourlyEnabled = hourly > 0;
      if (_hourlyEnabled) {
        _pricePerHourController.text = hourly.toInt().toString();
      } else {
        _pricePerDayController.text = day > 0 ? day.toInt().toString() : '';
      }
      _descriptionController.text = item['description'] ?? '';
      _locationController.text = item['location'] ?? '';
      if (_categories.contains(item['category'])) {
        _selectedCategory = item['category'];
      }
      if (_conditions.contains(item['condition'])) {
        _selectedCondition = item['condition'];
      }
      _existingImageUrls = List<String>.from(item['imageUrls'] ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          if (kIsWeb) {
            _webImages.addAll(images);
          } else {
            _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
      }
    }
  }

  static String _absUrl(String url) =>
      (url.isEmpty || url.startsWith('http')) ? url : 'http://localhost:5000$url';

  void _removeImage(int index) {
    setState(() {
      if (index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      } else {
        final i = index - _existingImageUrls.length;
        if (kIsWeb) _webImages.removeAt(i);
        else _selectedImages.removeAt(i);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _selectedImages.isEmpty && _webImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Кем дегенде бір сурет қосыңыз')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> newImageUrls = [];

      if (!kIsWeb && _selectedImages.isNotEmpty) {
        final uploadResponse = await ApiService.uploadImages(
          type: 'instruments',
          images: _selectedImages,
        );
        if (uploadResponse['success']) {
          newImageUrls = List<String>.from(uploadResponse['imageUrls'] ?? []);
        } else {
          throw Exception(uploadResponse['message'] ?? 'Суреттерді жүктеу қатесі');
        }
      }

      final imageUrls = _isEditing
          ? [..._existingImageUrls, ...newImageUrls]
          : newImageUrls;

      final data = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'pricePerDay': _hourlyEnabled
            ? double.parse(_pricePerHourController.text) * 24 * 0.85
            : double.parse(_pricePerDayController.text),
        'pricePerHour': _hourlyEnabled ? double.parse(_pricePerHourController.text) : 0.0,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'condition': _selectedCondition,
        'imageUrls': imageUrls,
      };

      final Map<String, dynamic> response;
      if (_isEditing) {
        final id = widget.instrument!['_id'] ?? widget.instrument!['id'];
        response = await ApiService.updateInstrument(id, data);
      } else {
        response = await ApiService.createInstrument(data);
      }

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing ? 'Аспап жаңартылды!' : 'Аспап қосылды!'),
            backgroundColor: _accent,
          ));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Қате орын алды!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? prefix, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 20) : null,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: _surface.withValues(alpha: 0.4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingCount = _existingImageUrls.length;
    final imageCount = existingCount + (kIsWeb ? _webImages.length : _selectedImages.length);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16213E), Color(0xFF0F3460)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.piano, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Аспапты өңдеу' : 'Аспап қосу',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isEditing ? 'Ақпаратты жаңартыңыз' : 'Жаңа аспап жарнамасы',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  
                  _buildSectionLabel('Суреттер', Icons.photo_library_outlined),
                  const SizedBox(height: 12),
                  _buildImageSection(imageCount, existingCount),
                  const SizedBox(height: 24),

                  
                  _buildSectionLabel('Негізгі ақпарат', Icons.info_outline),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Атауы',
                      hint: 'Мысалы: Акустикалық гитара Yamaha',
                      icon: Icons.music_note_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Атауын енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildDarkDropdown<String>(
                    label: 'Санат',
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _brandController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Бренд',
                      hint: 'Мысалы: Yamaha, Fender, Gibson',
                      icon: Icons.label_outline,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Брендін енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _modelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Модель',
                      hint: 'Мысалы: FG800',
                      icon: Icons.tag_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Модельді енгізіңіз' : null,
                  ),
                  const SizedBox(height: 24),

                  
                  _buildSectionLabel('Күйі', Icons.star_outline),
                  const SizedBox(height: 12),
                  _buildConditionSelector(),
                  const SizedBox(height: 24),

                  
                  _buildSectionLabel('Баға', Icons.payments_outlined),
                  const SizedBox(height: 12),
                  _buildHourlyToggle(),
                  if (_hourlyEnabled) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pricePerHourController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Сағат бағасы / ₸', icon: Icons.schedule_outlined),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Бағаны енгізіңіз';
                        final p = double.tryParse(v);
                        if (p == null || p <= 0) return 'Дұрыс баға';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildDayPricePreview(),
                  ] else ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pricePerDayController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Күн бағасы / ₸', icon: Icons.calendar_today_outlined),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Бағаны енгізіңіз';
                        final p = double.tryParse(v);
                        if (p == null || p <= 0) return 'Дұрыс баға';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  
                  _buildSectionLabel('Орналасуы мен сипаттамасы', Icons.place_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Орналасқан жері',
                      hint: 'Мысалы: Алматы, Абай көшесі 150',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Орналасқан жерін енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Сипаттамасы',
                      hint: 'Аспаптың толық сипаттамасын енгізіңіз',
                    ),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Сипаттаманы енгізіңіз' : null,
                  ),
                  const SizedBox(height: 32),

                  
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(int imageCount, int existingCount) {
    return Container(
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$imageCount / 5 сурет',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              GestureDetector(
                onTap: imageCount < 5 ? _pickImages : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: imageCount < 5 ? _accent : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Сурет қосу', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (imageCount == 0)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: _accent.withValues(alpha: 0.4), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: _accent.withValues(alpha: 0.7), size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Суреттерді жүктеу үшін басыңыз',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageCount,
                itemBuilder: (context, index) {
                  Widget imgWidget;
                  if (index < existingCount) {
                    imgWidget = CachedNetworkImage(
                      imageUrl: _absUrl(_existingImageUrls[index]),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24, size: 32),
                    );
                  } else {
                    final i = index - existingCount;
                    imgWidget = kIsWeb
                        ? Image.network(_webImages[i].path, fit: BoxFit.cover)
                        : Image.file(_selectedImages[i], fit: BoxFit.cover);
                  }
                  return Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accent.withValues(alpha: 0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imgWidget,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDarkDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: _card,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon: icon),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString(), style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildConditionSelector() {
    final colors = {
      'Керемет': const Color(0xFF4CAF50),
      'Жақсы': const Color(0xFF2196F3),
      'Қанағаттанарлық': const Color(0xFFFF9800),
    };
    return Row(
      children: _conditions.map((condition) {
        final isSelected = _selectedCondition == condition;
        final color = colors[condition]!;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCondition = condition),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.25) : _surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? color : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    condition,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white60,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHourlyToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _hourlyEnabled ? _accent.withValues(alpha: 0.12) : _surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hourlyEnabled ? _accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, color: _hourlyEnabled ? _accent : Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сағаттық жалдау',
                  style: TextStyle(
                    color: _hourlyEnabled ? Colors.white : Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Клиент сағат бойынша жалдай алады',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _hourlyEnabled,
            onChanged: (v) => setState(() {
              _hourlyEnabled = v;
              if (!v) _pricePerHourController.clear();
            }),
            activeColor: _accent,
          ),
        ],
      ),
    );
  }

  Widget _buildDayPricePreview() {
    final hourly = double.tryParse(_pricePerHourController.text) ?? 0;
    final day = (hourly * 24 * 0.85).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: _accent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Күндік баға (автоматты)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(
                  day > 0 ? '$day ₸' : '—',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('-15%', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                _isEditing ? 'Сақтау' : 'Аспапты қосу',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
