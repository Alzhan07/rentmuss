import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'login.dart';
import 'favorites.dart';
import 'admin.dart';
import 'seller_form.dart';
import 'bookings_screen.dart';
import 'seller_bookings_screen.dart';
import 'edit_profile_screen.dart';
import 'moderator_screen.dart';
import 'faq_screen.dart';

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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool oldVisible = false;
          bool newVisible = false;
          bool confirmVisible = false;
          bool loading = false;

          return StatefulBuilder(
            builder: (context, setInner) {
              InputDecoration fieldDecoration({
                required String label,
                required bool visible,
                required VoidCallback onToggle,
                String? hint,
              }) {
                return InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE94560), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Icon + Title
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE94560), Color(0xFF9B1432)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Құпия сөзді өзгерту',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Жаңа құпия сөзіңізді енгізіңіз',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        ),
                        const SizedBox(height: 28),
                        // Fields
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: oldPasswordController,
                                obscureText: !oldVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  label: 'Ескі құпия сөз',
                                  visible: oldVisible,
                                  onToggle: () => setInner(() => oldVisible = !oldVisible),
                                ),
                                validator: (v) => (v?.isEmpty ?? true) ? 'Ескі құпия сөзді енгізіңіз' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: newPasswordController,
                                obscureText: !newVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  label: 'Жаңа құпия сөз',
                                  visible: newVisible,
                                  onToggle: () => setInner(() => newVisible = !newVisible),
                                  hint: '8+ таңба, A-Z, a-z, 0-9, !@#\$',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Жаңа құпия сөзді енгізіңіз';
                                  if (value.length < 8) return 'Кем дегенде 8 таңба болуы керек';
                                  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Кіші әріп (a-z) болуы керек';
                                  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Бас әріп (A-Z) болуы керек';
                                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Сан (0-9) болуы керек';
                                  if (!RegExp('[!@#\$%^&*()\\-_=+\\[\\]{};:\'",.<>\\/\\\\?|`~]').hasMatch(value)) {
                                    return 'Арнайы таңба болуы керек (!@#\$%...)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: confirmPasswordController,
                                obscureText: !confirmVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: fieldDecoration(
                                  label: 'Құпия сөзді растаңыз',
                                  visible: confirmVisible,
                                  onToggle: () => setInner(() => confirmVisible = !confirmVisible),
                                ),
                                validator: (v) => v != newPasswordController.text ? 'Құпия сөздер сәйкес келмейді' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: loading ? null : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                  ),
                                  child: Text(
                                    'Бас тарту',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: loading
                                        ? null
                                        : const LinearGradient(
                                            colors: [Color(0xFFE94560), Color(0xFF9B1432)],
                                          ),
                                    color: loading ? Colors.grey : null,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!.validate()) return;
                                            setInner(() => loading = true);
                                            final result = await ApiService.changePassword(
                                              oldPassword: oldPasswordController.text,
                                              newPassword: newPasswordController.text,
                                            );
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(result['message'] ?? ''),
                                                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Text(
                                            'Сақтау',
                                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
                        const SizedBox(height: 32),

                        // ── Role hero cards (first in list) ─────────────────
                        if (_user?.isAdmin == true)
                          _buildRoleHeroCard(
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'Админ-панель',
                            subtitle: 'Сатушылар, пайдаланушылар және рөлдерді басқару',
                            gradientColors: [const Color(0xFFE94560), const Color(0xFF9B1432)],
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AdminScreen())),
                          ),
                        if (_user?.isModerator == true)
                          _buildRoleHeroCard(
                            icon: Icons.shield_rounded,
                            title: 'Модератор панелі',
                            subtitle: 'Жарнамалар мен апелляцияларды қарау',
                            gradientColors: [const Color(0xFF5B4FE9), const Color(0xFF3730A3)],
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ModeratorScreen())),
                          ),
                        if (_user?.isSeller == true)
                          _buildRoleHeroCard(
                            icon: Icons.storefront_rounded,
                            title: _user?.sellerInfo?.shopName ?? 'Менің дүкенім',
                            subtitle: 'Тізімдерді, брондауларды және кірісті басқару',
                            gradientColors: [const Color(0xFF533483), const Color(0xFF2D1B69)],
                            onTap: () => Navigator.pushNamed(context, '/seller'),
                          ),

                        const SizedBox(height: 8),

                        // ── Regular menu cards ───────────────────────────────
                        if (_user?.isSeller != true) ...[
                          _buildMenuCard(
                            icon: Icons.calendar_month,
                            title: 'Брондауларым',
                            subtitle: 'Брондаулар тарихы',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const BookingsScreen())),
                          ),
                          _buildMenuCard(
                            icon: Icons.favorite,
                            title: 'Таңдаулылар',
                            subtitle: 'Сіздің сақталған алаңдарыңыз',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                          ),
                        ],
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
                            icon: Icons.receipt_long_rounded,
                            title: 'Брондаулар',
                            subtitle: 'Клиент брондауларын басқару',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SellerBookingsScreen())),
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
                          onTap: () async {
                            if (_user == null) return;
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(user: _user!),
                              ),
                            );
                            if (updated == true) _loadUserData();
                          },
                        ),
                        _buildMenuCard(
                          icon: Icons.help_outline,
                          title: 'Көмек',
                          subtitle: 'FAQ және қолдау',
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FaqScreen())),
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
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
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
      case UserRole.moderator:
        return const Color(0xFF5B4FE9);
      case UserRole.seller:
        return const Color(0xFF533483);
      case UserRole.user:
        return const Color(0xFF0F3460);
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.moderator:
        return 'Модератор';
      case UserRole.seller:
        return 'Сатушы';
      case UserRole.user:
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

  Widget _buildRoleHeroCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withValues(alpha: 0.2),
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
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withValues(alpha: 0.5),
          size: 16,
        ),
      ),
    );
  }
}
