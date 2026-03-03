import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddStageScreen extends StatefulWidget {
  final Map<String, dynamic>? stage; // null = create, non-null = edit

  const AddStageScreen({Key? key, this.stage}) : super(key: key);

  @override
  State<AddStageScreen> createState() => _AddStageScreenState();
}

class _AddStageScreenState extends State<AddStageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _sizeController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _hourlyEnabled = false;
  bool _hasLightingSystem = false;
  bool _hasSoundSystem = false;
  bool _hasBackstage = false;
  bool _hasParking = false;
  String _selectedType = 'outdoor';

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  final List<XFile> _webImages = [];
  List<String> _existingImageUrls = [];

  bool get _isEditing => widget.stage != null;

  static const _bg = Color(0xFF1A1A2E);
  static const _accent = Color(0xFFE94560);
  static const _surface = Color(0xFF0F3460);

  @override
  void initState() {
    super.initState();
    final item = widget.stage;
    if (item != null) {
      _nameController.text = item['name'] ?? '';
      _locationController.text = item['location'] ?? item['address'] ?? '';
      _capacityController.text = (item['capacity'] ?? '').toString();
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
      final facilities = List<String>.from(item['facilities'] ?? item['amenities'] ?? []);
      _hasLightingSystem = item['hasLighting'] == true || facilities.contains('Жарықтандыру жүйесі');
      _hasSoundSystem = item['hasSound'] == true || facilities.contains('Дыбыс жүйесі');
      _hasBackstage = item['hasBackstage'] == true || facilities.contains('Бэкстейдж');
      _hasParking = item['hasParking'] == true || facilities.contains('Тұрақ');
      const validTypes = ['concert', 'theater', 'club', 'outdoor', 'small', 'medium', 'large'];
      final t = item['type'] ?? 'outdoor';
      _selectedType = validTypes.contains(t) ? t : 'outdoor';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
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
          type: 'stages',
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

      final facilities = <String>[];
      if (_hasLightingSystem) facilities.add('Жарықтандыру жүйесі');
      if (_hasSoundSystem) facilities.add('Дыбыс жүйесі');
      if (_hasBackstage) facilities.add('Бэкстейдж');
      if (_hasParking) facilities.add('Тұрақ');

      final data = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'location': _locationController.text.trim(),
        'address': _locationController.text.trim(),
        'capacity': int.parse(_capacityController.text),
        'areaSquareMeters': double.parse(_sizeController.text),
        'pricePerDay': _hourlyEnabled
            ? double.parse(_pricePerHourController.text) * 24 * 0.85
            : double.parse(_pricePerDayController.text),
        'pricePerHour': _hourlyEnabled ? double.parse(_pricePerHourController.text) : 0.0,
        'description': _descriptionController.text.trim(),
        'hasSound': _hasSoundSystem,
        'hasLighting': _hasLightingSystem,
        'hasBackstage': _hasBackstage,
        'hasParking': _hasParking,
        'amenities': facilities,
        'imageUrls': imageUrls,
      };

      final Map<String, dynamic> response;
      if (_isEditing) {
        final id = widget.stage!['_id'] ?? widget.stage!['id'];
        response = await ApiService.updateStage(id, data);
      } else {
        response = await ApiService.createStage(data);
      }

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing ? 'Сахна жаңартылды!' : 'Сахна қосылды!'),
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
                      child: const Icon(Icons.theater_comedy_outlined, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Сахнаны өңдеу' : 'Сахнаны қосу',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isEditing ? 'Ақпаратты жаңартыңыз' : 'Жаңа сахна жарнамасы',
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
                      hint: 'Мысалы: Ашық сахна Саябақта',
                      icon: Icons.theater_comedy_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Атауын енгізіңіз' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTypeDropdown(),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Орналасқан жері',
                      hint: 'Мысалы: Алматы, Орталық саябағы',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Орналасқан жерін енгізіңіз' : null,
                  ),
                  const SizedBox(height: 24),

                  // Capacity & size
                  _buildSectionLabel('Өлшемдер', Icons.straighten_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _capacityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Сыйымдылығы',
                            hint: 'Адам саны',
                            icon: Icons.people_outline,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Енгізіңіз';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Дұрыс мән';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sizeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Ауданы (м²)',
                            hint: 'Шаршы метр',
                            icon: Icons.crop_square_outlined,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Енгізіңіз';
                            final n = double.tryParse(v);
                            if (n == null || n <= 0) return 'Дұрыс мән';
                            return null;
                          },
                        ),
                      ),
                    ],
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
                      hint: 'Сахнаның толық сипаттамасын енгізіңіз',
                    ),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Сипаттаманы енгізіңіз' : null,
                  ),
                  const SizedBox(height: 24),

                  // Facilities
                  _buildSectionLabel('Қол жетімді мүмкіндіктер', Icons.checklist_outlined),
                  const SizedBox(height: 12),
                  _buildFacilitiesGrid(),
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

  static const _stageTypes = {
    'outdoor': 'Ашық сахна',
    'concert': 'Концерт залы',
    'theater': 'Театр сахнасы',
    'club': 'Клуб сахнасы',
    'small': 'Шағын сахна',
    'medium': 'Орта сахна',
    'large': 'Үлкен сахна',
  };

  Widget _buildTypeDropdown() {
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
          items: _stageTypes.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 15)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedType = v ?? 'outdoor'),
          hint: Row(
            children: [
              const Icon(Icons.category_outlined, color: Colors.white38, size: 20),
              const SizedBox(width: 10),
              Text('Сахна түрі', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
          selectedItemBuilder: (context) => _stageTypes.entries.map((e) {
            return Row(
              children: [
                const Icon(Icons.category_outlined, color: Colors.white38, size: 20),
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

  Widget _buildFacilitiesGrid() {
    final facilities = [
      {'label': 'Жарықтандыру жүйесі', 'icon': Icons.light_mode_outlined, 'value': _hasLightingSystem, 'key': 'light'},
      {'label': 'Дыбыс жүйесі', 'icon': Icons.speaker_outlined, 'value': _hasSoundSystem, 'key': 'sound'},
      {'label': 'Бэкстейдж', 'icon': Icons.door_back_door_outlined, 'value': _hasBackstage, 'key': 'backstage'},
      {'label': 'Тұрақ', 'icon': Icons.local_parking_outlined, 'value': _hasParking, 'key': 'parking'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: facilities.map((f) {
        final isOn = f['value'] as bool;
        return GestureDetector(
          onTap: () {
            setState(() {
              switch (f['key']) {
                case 'light': _hasLightingSystem = !_hasLightingSystem; break;
                case 'sound': _hasSoundSystem = !_hasSoundSystem; break;
                case 'backstage': _hasBackstage = !_hasBackstage; break;
                case 'parking': _hasParking = !_hasParking; break;
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isOn ? _accent.withValues(alpha: 0.15) : _surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOn ? _accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  f['icon'] as IconData,
                  color: isOn ? _accent : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isOn ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOn)
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
                _isEditing ? 'Сақтау' : 'Сахнаны қосу',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
