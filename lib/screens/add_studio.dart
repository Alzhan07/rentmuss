import 'package:flutter/material.dart';
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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
      };

      final response = await ApiService.createStudio(data);

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Студия қосылды!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Қосуда қате орын алды!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Студияны қосу'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Студияны қосу', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
