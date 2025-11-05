import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'login.dart';
import 'favorites.dart';
import 'admin.dart';
import 'seller.dart';
import 'seller_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  File? _imageFile;
  XFile? _webImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getUserProfile();
    if (result['success'] == true && result['user'] != null) {
      setState(() {
        _user = User.fromJson(result['user']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = image;
        } else {
          _imageFile = File(image.path);
        }
      });


      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Загрузка аватара на веб пока не поддерживается'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Загрузка аватара...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Upload avatar
        final result = await ApiService.uploadAvatar(_imageFile!);

        if (result['success'] == true) {
          // Clear local image and reload user data from server
          setState(() {
            _imageFile = null;
            _webImage = null;
          });

          await _loadUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Аватар успешно обновлен'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Ошибка загрузки аватара'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Құпия сөзді өзгерту',
              style: TextStyle(color: Colors.white),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ескі құпия сөз',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Ескі құпия сөзді енгізіңіз'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Жаңа құпия сөз',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator:
                        (value) =>
                            (value?.length ?? 0) < 6
                                ? 'Кем дегенде 6 таңба болуы керек'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Құпия сөзді растаңыз',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator:
                        (value) =>
                            value != newPasswordController.text
                                ? 'Құпия сөздер сәйкес келмейді'
                                : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Бас тарту',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final result = await ApiService.changePassword(
                      oldPassword: oldPasswordController.text,
                      newPassword: newPasswordController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor:
                              result['success'] ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                ),
                child: const Text('Сақтау'),
              ),
            ],
          ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE94560),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildAvatarImage(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE94560),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.fullName ?? 'Пайдаланушы',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'Email көрсетілмеген',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        if (_user?.role != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(_user!.role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(_user!.role),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                        _buildMenuCard(
                          icon: Icons.favorite,
                          title: 'Таңдаулылар',
                          subtitle: 'Сіздің сақталған алаңдарыңыз',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                        ),
                        if (_user?.isAdmin == true)
                          _buildMenuCard(
                            icon: Icons.admin_panel_settings,
                            title: 'Админ-панель',
                            subtitle: 'Сатушылардың өтінімдерін басқару',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminScreen(),
                                ),
                              );
                            },
                          ),
                        if (_user?.canApplyForSeller == true)
                          _buildMenuCard(
                            icon: Icons.store,
                            title: 'Сатушы болу',
                            subtitle: 'Сатушы болуға өтінім беру',
                            onTap: _applyForSeller,
                          ),
                        if (_user?.sellerApplication?.status ==
                            SellerApplicationStatus.pending)
                          _buildMenuCard(
                            icon: Icons.pending,
                            title: 'Өтініміңіз қаралуда',
                            subtitle: 'Администратор жауабын күтіңіз',
                            onTap: () {},
                          ),
                        if (_user?.isSeller == true)
                          _buildMenuCard(
                            icon: Icons.store,
                            title: 'Менің дүкенім',
                            subtitle:
                                _user?.sellerInfo?.shopName ??
                                'Дүкенді басқару',
                            onTap: () {
                              Navigator.pushNamed(context, '/seller');
                            },
                          ),
                        _buildMenuCard(
                          icon: Icons.lock_outline,
                          title: 'Құпия сөзді өзгерту',
                          subtitle: 'Қауіпсіздік үшін құпия сөзді жаңартыңыз',
                          onTap: _changePassword,
                        ),
                        _buildMenuCard(
                          icon: Icons.edit,
                          title: 'Профильді өзгерту',
                          subtitle: 'Жеке ақпаратты өзгерту',
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          icon: Icons.notifications_outlined,
                          title: 'Хабарламалар',
                          subtitle: 'Хабарламаларды реттеңіз',
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          icon: Icons.help_outline,
                          title: 'Көмек',
                          subtitle: 'FAQ және қолдау',
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                await ApiService.logout();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                foregroundColor: const Color(0xFFE94560),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFFE94560),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Шығу',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Future<void> _applyForSeller() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SellerFormScreen()),
    );

    if (result == true) {
      await _loadUserData();
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE94560);
      case UserRole.seller:
        return const Color(0xFF533483);
      case UserRole.user:
      default:
        return const Color(0xFF0F3460);
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.seller:
        return 'Сатушы';
      case UserRole.user:
      default:
        return 'Пайдаланушы';
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF0F3460),
      child: const Icon(Icons.person, size: 60, color: Color(0xFFE94560)),
    );
  }

  Widget _buildAvatarImage() {
    // Priority: local file > web image > server avatar > default
    if (kIsWeb && _webImage != null) {
      return Image.network(
        _webImage!.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildServerOrDefaultAvatar(),
      );
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
      );
    } else {
      return _buildServerOrDefaultAvatar();
    }
  }

  Widget _buildServerOrDefaultAvatar() {
    if (_user?.avatar != null && _user!.avatar!.isNotEmpty) {
      return Image.network(
        _user!.avatar!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFE94560), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.5),
          size: 16,
        ),
      ),
    );
  }
}
