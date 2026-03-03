import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddStudioScreen extends StatefulWidget {
  final Map<String, dynamic>? studio; // null = create, non-null = edit

  const AddStudioScreen({Key? key, this.studio}) : super(key: key);

  @override
  State<AddStudioScreen> createState() => _AddStudioScreenState();
}

class _AddStudioScreenState extends State<AddStudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _sizeController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _hourlyEnabled = false;
  String _selectedType = 'recording';

  bool _hasMicrophones = false;
  bool _hasMixingConsole = false;
  bool _hasMonitors = false;
  bool _hasInstruments = false;

  bool _hasSoundproofing = false;
  bool _hasAirConditioning = false;
  bool _hasWiFi = false;
  bool _hasParking = false;
  bool _hasKitchen = false;

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  final List<XFile> _webImages = [];
  List<String> _existingImageUrls = [];

  bool get _isEditing => widget.studio != null;

  static const _bg = Color(0xFF1A1A2E);
  static const _accent = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  @override
  void initState() {
    super.initState();
    final item = widget.studio;
    if (item != null) {
      _nameController.text = item['name'] ?? '';
      _locationController.text = item['location'] ?? item['address'] ?? '';
      _sizeController.text = (item['areaSquareMeters'] ?? item['size'] ?? '').toString();
      final day = (item['pricePerDay'] ?? 0).toDouble();
      final hourly = (item['pricePerHour'] ?? 0).toDouble();
      _hourlyEnabled = hourly > 0;
      if (_hourlyEnabled) {
        _pricePerHourController.text = hourly.toInt().toString();
      } else {
        _pricePerDayController.text = day > 0 ? day.toInt().toString() : '';
      }
      _descriptionController.text = item['description'] ?? '';
      _existingImageUrls = List<String>.from(item['imageUrls'] ?? []);
      // equipment stored as String in DB
      final equipStr = item['equipment']?.toString() ?? '';
      final equipment = equipStr.isNotEmpty ? equipStr.split(', ') : <String>[];
      final amenities = List<String>.from(item['amenities'] ?? []);
      _hasMicrophones = equipment.contains('Микрофондар');
      _hasMixingConsole = equipment.contains('Микшер пульті');
      _hasMonitors = equipment.contains('Мониторлар');
      _hasInstruments = item['hasInstruments'] == true || equipment.contains('Музыкалық аспаптар');
      _hasSoundproofing = item['hasSoundproofing'] == true || amenities.contains('Дыбыс изоляциясы');
      _hasAirConditioning = item['hasAirConditioning'] == true || amenities.contains('Кондиционер');
      _hasWiFi = amenities.contains('WiFi');
      _hasParking = amenities.contains('Тұрақ');
      _hasKitchen = amenities.contains('Асхана');
      const validTypes = ['recording', 'rehearsal', 'podcast', 'live_streaming', 'mixing'];
      final t = item['type'] ?? 'recording';
      _selectedType = validTypes.contains(t) ? t : 'recording';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sizeController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _descriptionController.dispose();
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
      (url.isEmpty || url.startsWith('http')) ? url : 'https://rentmuss-production.up.railway.app$url';

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
          type: 'studios',
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

      final equipment = <String>[];
      if (_hasMicrophones) equipment.add('Микрофондар');
      if (_hasMixingConsole) equipment.add('Микшер пульті');
      if (_hasMonitors) equipment.add('Мониторлар');
      if (_hasInstruments) equipment.add('Музыкалық аспаптар');

      final amenities = <String>[];
      if (_hasSoundproofing) amenities.add('Дыбыс изоляциясы');
      if (_hasAirConditioning) amenities.add('Кондиционер');
      if (_hasWiFi) amenities.add('WiFi');
      if (_hasParking) amenities.add('Тұрақ');
      if (_hasKitchen) amenities.add('Асхана');

      final data = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'location': _locationController.text.trim(),
        'address': _locationController.text.trim(),
        'areaSquareMeters': double.parse(_sizeController.text),
        'pricePerDay': _hourlyEnabled
            ? double.parse(_pricePerHourController.text) * 24 * 0.85
            : double.parse(_pricePerDayController.text),
        'pricePerHour': _hourlyEnabled ? double.parse(_pricePerHourController.text) : 0.0,
        'description': _descriptionController.text.trim(),
        'equipment': equipment.join(', '),
        'hasInstruments': _hasInstruments,
        'hasSoundproofing': _hasSoundproofing,
        'hasAirConditioning': _hasAirConditioning,
        'amenities': amenities,
        'imageUrls': imageUrls,
      };

      final Map<String, dynamic> response;
      if (_isEditing) {
        final id = widget.studio!['_id'] ?? widget.studio!['id'];
        response = await ApiService.updateStudio(id, data);
      } else {
        response = await ApiService.createStudio(data);
      }

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing ? 'Студия жаңартылды!' : 'Студия қосылды!'),
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

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 20) : null,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
          // Custom header
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
                      child: const Icon(Icons.mic_outlined, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Студияны өңдеу' : 'Студияны қосу',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isEditing ? 'Ақпаратты жаңартыңыз' : 'Жаңа студия жарнамасы',
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

          // Form body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Images
                  _buildSectionLabel('Суреттер', Icons.photo_library_outlined),
                  const SizedBox(height: 12),
                  _buildImageSection(imageCount, existingCount),
                  const SizedBox(height: 24),

                  // Basic info
                  _buildSectionLabel('Негізгі ақпарат', Icons.info_outline),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Атауы',
                      hint: 'Мысалы: Жазу студиясы "Әуен"',
                      icon: Icons.mic_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Атауын енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildStudioTypeDropdown(),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Орналасқан жері',
                      hint: 'Мысалы: Алматы, Толе би 123',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Орналасқан жерін енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sizeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Ауданы (м²)',
                      hint: 'Студияның көлемі',
                      icon: Icons.crop_square_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Көлемін енгізіңіз';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Дұрыс мәнді енгізіңіз';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Pricing
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

                  // Description
                  _buildSectionLabel('Сипаттамасы', Icons.description_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Сипаттама',
                      hint: 'Студияның толық сипаттамасын енгізіңіз',
                    ),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Сипаттаманы енгізіңіз' : null,
                  ),
                  const SizedBox(height: 24),

                  // Equipment
                  _buildSectionLabel('Жабдықтар', Icons.headset_outlined),
                  const SizedBox(height: 12),
                  _buildToggleGrid([
                    _ToggleItem('Микрофондар', Icons.mic_none_outlined, _hasMicrophones, () => setState(() => _hasMicrophones = !_hasMicrophones)),
                    _ToggleItem('Микшер пульті', Icons.tune_outlined, _hasMixingConsole, () => setState(() => _hasMixingConsole = !_hasMixingConsole)),
                    _ToggleItem('Мониторлар', Icons.monitor_outlined, _hasMonitors, () => setState(() => _hasMonitors = !_hasMonitors)),
                    _ToggleItem('Муз. аспаптар', Icons.piano_outlined, _hasInstruments, () => setState(() => _hasInstruments = !_hasInstruments)),
                  ]),
                  const SizedBox(height: 24),

                  // Amenities
                  _buildSectionLabel('Ыңғайлылықтар', Icons.apartment_outlined),
                  const SizedBox(height: 12),
                  _buildToggleGrid([
                    _ToggleItem('Дыбыс изоляциясы', Icons.volume_off_outlined, _hasSoundproofing, () => setState(() => _hasSoundproofing = !_hasSoundproofing)),
                    _ToggleItem('Кондиционер', Icons.ac_unit_outlined, _hasAirConditioning, () => setState(() => _hasAirConditioning = !_hasAirConditioning)),
                    _ToggleItem('WiFi', Icons.wifi_outlined, _hasWiFi, () => setState(() => _hasWiFi = !_hasWiFi)),
                    _ToggleItem('Тұрақ', Icons.local_parking_outlined, _hasParking, () => setState(() => _hasParking = !_hasParking)),
                    _ToggleItem('Асхана', Icons.kitchen_outlined, _hasKitchen, () => setState(() => _hasKitchen = !_hasKitchen)),
                  ]),
                  const SizedBox(height: 32),

                  // Submit
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

  static const _studioTypes = {
    'recording': 'Дыбыс жазу',
    'rehearsal': 'Репетиция',
    'podcast': 'Подкасттар',
    'live_streaming': 'Стриминг',
    'mixing': 'Мәлімет',
  };

  Widget _buildStudioTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F3460),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          items: _studioTypes.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 15)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedType = v ?? 'recording'),
          selectedItemBuilder: (context) => _studioTypes.entries.map((e) {
            return Row(
              children: [
                const Icon(Icons.mic_outlined, color: Colors.white38, size: 20),
                const SizedBox(width: 10),
                Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            );
          }).toList(),
        ),
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
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
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

  Widget _buildToggleGrid(List<_ToggleItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: items.map((item) {
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: item.value ? _accent.withValues(alpha: 0.15) : _surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.value ? _accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(item.icon, color: item.value ? _accent : Colors.white38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.value ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: item.value ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.value)
                  const Icon(Icons.check_circle, color: _accent, size: 16),
              ],
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
                _isEditing ? 'Сақтау' : 'Студияны қосу',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _ToggleItem {
  final String label;
  final IconData icon;
  final bool value;
  final VoidCallback onTap;

  const _ToggleItem(this.label, this.icon, this.value, this.onTap);
}
