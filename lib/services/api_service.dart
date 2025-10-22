import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ApiService {
  // Замените на ваш реальный URL сервера
  static const String baseUrl = 'http://localhost:5000/api';

  // Получить заголовки с авторизацией
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Регистрация пользователя
  static Future<Map<String, dynamic>> register({
    required String name,
    required String lastName,
    required String password,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'lastName': lastName,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Сохраняем токен
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Регистрация успешна',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Ошибка регистрации',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения к серверу: $e'
      };
    }
  }

  // Вход пользователя
  static Future<Map<String, dynamic>> login({
    required String name,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'lastName': lastName,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Сохраняем токен
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Вход выполнен',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Ошибка входа',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения к серверу: $e'
      };
    }
  }

  // Выход
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Проверка авторизации
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // Получить сохраненного пользователя
  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Получить профиль пользователя
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Обновляем локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        return {
          'success': true,
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': 'Не удалось получить профиль',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения: $e',
      };
    }
  }

  // Подать заявку на продавца
  static Future<Map<String, dynamic>> applyForSeller({
    required String shopName,
    String? shopDescription,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/apply-seller'),
        headers: headers,
        body: jsonEncode({
          'shopName': shopName,
          if (shopDescription != null) 'shopDescription': shopDescription,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Обновляем профиль пользователя
        await getUserProfile();
        return {
          'success': true,
          'message': data['message'] ?? 'Заявка отправлена',
          'sellerApplication': data['sellerApplication'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка отправки заявки',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения: $e',
      };
    }
  }

  // Получить все заявки на продавца (только для админа)
  static Future<Map<String, dynamic>> getSellerApplications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/seller-applications'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'applications': data['applications'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка получения заявок',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения: $e',
      };
    }
  }

  // Одобрить/Отклонить заявку на продавца (только для админа)
  static Future<Map<String, dynamic>> reviewSellerApplication({
    required String userId,
    required bool approved,
    String? rejectionReason,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/review-seller-application/$userId'),
        headers: headers,
        body: jsonEncode({
          'approved': approved,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка обработки заявки',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения: $e',
      };
    }
  }

  // Проверить доступность имени
  static Future<bool> checkNameAvailability(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-name/$name'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== СТАРЫЕ МЕТОДЫ (для совместимости) ==========

  // Загрузить аватар
  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/avatar'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Аватар обновлен',
        'avatarUrl': data['avatarUrl'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка загрузки аватара: $e'};
    }
  }

  // Сменить пароль
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/user/change-password'),
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Пароль успешно изменен',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка смены пароля: $e'};
    }
  }

  // Получить список площадок
  static Future<List<Map<String, dynamic>>> getVenues({
    String? type,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/venues';
      final queryParams = <String, String>{};

      if (type != null) queryParams['type'] = type;
      if (search != null) queryParams['search'] = search;

      if (queryParams.isNotEmpty) {
        url += '?' +
            queryParams.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join('&');
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['venues'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Получить избранные площадки
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Добавить в избранное
  static Future<Map<String, dynamic>> addFavorite(String venueId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$venueId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Добавлено в избранное',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка добавления в избранное: $e',
      };
    }
  }

  // Удалить из избранного
  static Future<Map<String, dynamic>> removeFavorite(String venueId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$venueId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Удалено из избранного',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка удаления из избранного: $e',
      };
    }
  }

  // Обновить профиль
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? lastName,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Обновить локальные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
      }

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Профиль обновлен',
        'user': data['user'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка обновления профиля: $e'};
    }
  }
}
