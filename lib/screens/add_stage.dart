import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddStageScreen extends StatefulWidget {
  const AddStageScreen({Key? key}) : super(key: key);

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
  bool _hasLightingSystem = false;
  bool _hasSoundSystem = false;
  bool _hasBackstage = false;
  bool _hasParking = false;

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final facilities = <String>[];
      if (_hasLightingSystem) facilities.add('Жарықтандыру жүйесі');
      if (_hasSoundSystem) facilities.add('Дыбыс жүйесі');
      if (_hasBackstage) facilities.add('Бэкстейдж');
      if (_hasParking) facilities.add('Тұрақ');

      final data = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'capacity': int.parse(_capacityController.text),
        'size': double.parse(_sizeController.text),
        'pricePerHour': double.parse(_pricePerHourController.text),
        'pricePerDay': double.parse(_pricePerDayController.text),
        'description': _descriptionController.text.trim(),
        'facilities': facilities,
      };

      final response = await ApiService.createStage(data);

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сахна қосылды!')),
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
        title: const Text('Сахнаны қосу'),
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
                hintText: 'Мысалы: Саябақ ішідегі ашық сахна',
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
                hintText: 'Мысалы: Алматы қаласы, Орталық саябағы',
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
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Сыйымдылығы (адам)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Сыйымдылығын енгізіңіз';
                }
                final capacity = int.tryParse(value);
                if (capacity == null || capacity <= 0) {
                  return 'Дұрыс мәнді енгізіңіз';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Сахна көлемі (м²)',
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
                hintText: 'Сахнаның толық сипаттамасын енгізіңіз',
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
              'Қол жетімді ыңғайлылықтар:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Жарықтандыру жүйесі'),
              value: _hasLightingSystem,
              onChanged: (value) {
                setState(() => _hasLightingSystem = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Дыбыс жүйесі'),
              value: _hasSoundSystem,
              onChanged: (value) {
                setState(() => _hasSoundSystem = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Бэкстейдж'),
              value: _hasBackstage,
              onChanged: (value) {
                setState(() => _hasBackstage = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Тұрақ'),
              value: _hasParking,
              onChanged: (value) {
                setState(() => _hasParking = value ?? false);
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
                    : const Text('Сахнаны қосу', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
