import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SellerScreen extends StatefulWidget {
  const SellerScreen({Key? key}) : super(key: key);

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _instruments = [];
  List<dynamic> _stages = [];
  List<dynamic> _studios = [];

  bool _isLoadingInstruments = true;
  bool _isLoadingStages = true;
  bool _isLoadingStudios = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadInstruments(),
      _loadStages(),
      _loadStudios(),
    ]);
  }

  Future<void> _loadInstruments() async {
    setState(() => _isLoadingInstruments = true);
    try {
      final response = await ApiService.getMyInstruments();
      if (response['success']) {
        setState(() {
          _instruments = response['instruments'] ?? [];
          _isLoadingInstruments = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingInstruments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки инструментов: $e')),
        );
      }
    }
  }

  Future<void> _loadStages() async {
    setState(() => _isLoadingStages = true);
    try {
      final response = await ApiService.getMyStages();
      if (response['success']) {
        setState(() {
          _stages = response['stages'] ?? [];
          _isLoadingStages = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingStages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки сцен: $e')),
        );
      }
    }
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoadingStudios = true);
    try {
      final response = await ApiService.getMyStudios();
      if (response['success']) {
        setState(() {
          _studios = response['studios'] ?? [];
          _isLoadingStudios = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingStudios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки студий: $e')),
        );
      }
    }
  }

  Future<void> _deleteInstrument(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить этот инструмент?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteInstrument(id);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Инструмент удален')),
          );
          _loadInstruments();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<void> _deleteStage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить эту сцену?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteStage(id);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сцена удалена')),
          );
          _loadStages();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<void> _deleteStudio(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить эту студию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteStudio(id);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Студия удалена')),
          );
          _loadStudios();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои объявления'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Инструменты'),
            Tab(text: 'Сцены'),
            Tab(text: 'Студии'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstrumentsList(),
          _buildStagesList(),
          _buildStudiosList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? route;
          switch (_tabController.index) {
            case 0:
              route = '/add-instrument';
              break;
            case 1:
              route = '/add-stage';
              break;
            case 2:
              route = '/add-studio';
              break;
          }

          if (route != null) {
            final result = await Navigator.pushNamed(context, route);
            if (result == true) {
              _loadData();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInstrumentsList() {
    if (_isLoadingInstruments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_instruments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет инструментов',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInstruments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _instruments.length,
        itemBuilder: (context, index) {
          final instrument = _instruments[index];
          final id = instrument['_id'] is String
              ? instrument['_id']
              : instrument['_id']?['\$oid'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.music_note),
              ),
              title: Text(instrument['name'] ?? 'Без названия'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${instrument['brand']} ${instrument['model']}'),
                  Text(
                    '${instrument['pricePerHour']} ₸/час, ${instrument['pricePerDay']} ₸/день',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteInstrument(id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStagesList() {
    if (_isLoadingStages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.theater_comedy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет сцен',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final id = stage['_id'] is String
              ? stage['_id']
              : stage['_id']?['\$oid'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.theater_comedy),
              ),
              title: Text(stage['name'] ?? 'Без названия'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${stage['location']}'),
                  Text('Вместимость: ${stage['capacity']} человек'),
                  Text(
                    '${stage['pricePerHour']} ₸/час, ${stage['pricePerDay']} ₸/день',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteStage(id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudiosList() {
    if (_isLoadingStudios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет студий',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _studios.length,
        itemBuilder: (context, index) {
          final studio = _studios[index];
          final id = studio['_id'] is String
              ? studio['_id']
              : studio['_id']?['\$oid'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.home_work),
              ),
              title: Text(studio['name'] ?? 'Без названия'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${studio['location']}'),
                  Text('${studio['size']} м²'),
                  Text(
                    '${studio['pricePerHour']} ₸/час, ${studio['pricePerDay']} ₸/день',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteStudio(id),
              ),
            ),
          );
        },
      ),
    );
  }
}
