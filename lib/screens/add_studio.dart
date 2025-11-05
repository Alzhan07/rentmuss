import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddStudioScreen extends StatefulWidget {
  const AddStudioScreen({Key? key}) : super(key: key);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Қате: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty && _webImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Кем дегенде бір сурет қосыңыз')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> imageUrls = [];

      if (kIsWeb) {
        if (_webImages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Веб-нұсқада суреттерді жүктеу әзірше қолдау көрсетілмейді',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      } else {
        if (_selectedImages.isNotEmpty) {
          final uploadResponse = await ApiService.uploadImages(
            type: 'studios',
            images: _selectedImages,
          );

          if (uploadResponse['success']) {
            imageUrls = List<String>.from(uploadResponse['imageUrls'] ?? []);
          } else {
            throw Exception(
              uploadResponse['message'] ?? 'Суреттерді жүктеу қатесі',
            );
          }
        }
      }

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
        'location': _locationController.text.trim(),
        'size': double.parse(_sizeController.text),
        'pricePerHour': double.parse(_pricePerHourController.text),
        'pricePerDay': double.parse(_pricePerDayController.text),
        'description': _descriptionController.text.trim(),
        'equipment': equipment,
        'amenities': amenities,
        'imageUrls': imageUrls,
      };

      final response = await ApiService.createStudio(data);

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Студия қосылды!')));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Қосуда қате орын алды!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Қате: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Студияны қосу')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Суреттер',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              (_selectedImages.length + _webImages.length) < 5
                                  ? _pickImages
                                  : null,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Сурет қосу'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Кем дегенде 1, ең көбі 5 сурет',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isEmpty && _webImages.isEmpty)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('Сурет қосылмаған')),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              kIsWeb
                                  ? _webImages.length
                                  : _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        kIsWeb
                                            ? Image.network(
                                              _webImages[index].path,
                                              fit: BoxFit.cover,
                                            )
                                            : Image.file(
                                              _selectedImages[index],
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
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
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Атауы',
                hintText: 'Мысалы: дыбыс жазатын студия "Әуен"',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Атауын енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Орналасқан жері',
                hintText: 'Мысалы: Алматы қаласы, Толе би көшесі, 123',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Орналасқан жерін енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Көлемі (м²)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Көлемін енгізіңіз';
                }
                final size = double.tryParse(value);
                if (size == null || size <= 0) {
                  return 'Дұрыс мәнді енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricePerHourController,
              decoration: const InputDecoration(
                labelText: 'Сағаттық баға (₸)',
                border: OutlineInputBorder(),
                prefixText: '₸ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Сағаттық бағаны енгізіңіз';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Дұрыс бағаны енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricePerDayController,
              decoration: const InputDecoration(
                labelText: 'Күндік баға (₸)',
                border: OutlineInputBorder(),
                prefixText: '₸ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Күндік бағаны енгізіңіз';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Дұрыс бағаны енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Сипаттама',
                hintText: 'Студияның толық сипаттамасын енгізіңіз',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Сипаттаманы енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Жабдықтар:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Микрофондар'),
              value: _hasMicrophones,
              onChanged: (value) {
                setState(() => _hasMicrophones = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Микшер пульті'),
              value: _hasMixingConsole,
              onChanged: (value) {
                setState(() => _hasMixingConsole = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Мониторлар'),
              value: _hasMonitors,
              onChanged: (value) {
                setState(() => _hasMonitors = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Музыкалық құралдар'),
              value: _hasInstruments,
              onChanged: (value) {
                setState(() => _hasInstruments = value ?? false);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Ыңғайлылықтар:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Дыбыс изоляциясы'),
              value: _hasSoundproofing,
              onChanged: (value) {
                setState(() => _hasSoundproofing = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Кондиционер'),
              value: _hasAirConditioning,
              onChanged: (value) {
                setState(() => _hasAirConditioning = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('WiFi'),
              value: _hasWiFi,
              onChanged: (value) {
                setState(() => _hasWiFi = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Тұрақ'),
              value: _hasParking,
              onChanged: (value) {
                setState(() => _hasParking = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Асхана'),
              value: _hasKitchen,
              onChanged: (value) {
                setState(() => _hasKitchen = value ?? false);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'Студияны қосу',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
