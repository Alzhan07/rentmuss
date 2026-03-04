import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://rentmuss-production.up.railway.app/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String _toAbsoluteUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';
    if (relativeUrl.startsWith('http')) return relativeUrl;

    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}$relativeUrl';
  }

  static Map<String, dynamic> _processUserData(Map<String, dynamic> userData) {
    if (userData['avatar'] != null) {
      userData['avatar'] = _toAbsoluteUrl(userData['avatar']);
    }
    return userData;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'requiresVerification': data['requiresVerification'] ?? false,
          'userId': data['userId']?.toString() ?? '',
          'email': data['email'] ?? email,
          'message': data['message'] ?? 'Тіркелу сәтті',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Ошибка регистрации',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения к серверу: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String userId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'code': code}),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          final processedUser = _processUserData(
            Map<String, dynamic>.from(data['user']),
          );
          await prefs.setString('user_data', jsonEncode(processedUser));
        }
        return {'success': true, 'message': data['message'], 'token': data['token']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Код дұрыс емес'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendVerificationCode({
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          final processedUser = _processUserData(
            Map<String, dynamic>.from(data['user']),
          );
          await prefs.setString('user_data', jsonEncode(processedUser));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Вход выполнен',
          'user': _processUserData(Map<String, dynamic>.from(data['user'])),
          'token': data['token'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Ошибка входа'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения к серверу: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

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

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final processedUser = _processUserData(
          Map<String, dynamic>.from(data['user']),
        );
        await prefs.setString('user_data', jsonEncode(processedUser));
        return {'success': true, 'user': processedUser};
      }
      return {'success': false, 'message': 'Не удалось получить профиль'};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

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
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
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
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSellerApplications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/seller-applications'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'applications': data['applications']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка получения заявок',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

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
      ).timeout(const Duration(seconds: 30));

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
      return {'success': false, 'message': 'Ошибка подключения: $e'};
    }
  }

  static Future<bool> checkNameAvailability(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-name/$name'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

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

      if (response.statusCode == 200) {
        
        String avatarUrl = data['avatarUrl'] ?? '';
        if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
          avatarUrl = _toAbsoluteUrl(avatarUrl);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Аватар обновлен',
          'avatarUrl': avatarUrl,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка загрузки аватара',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка загрузки аватара: $e'};
    }
  }

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
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Пароль успешно изменен',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка смены пароля: $e'};
    }
  }

 
  static Future<Map<String, dynamic>> uploadImages({
    required String type,
    required List<File> images,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/listings/upload/$type'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

     
      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath('images', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        
        final imageUrls = List<String>.from(data['imageUrls'] ?? []);
        return {
          'success': true,
          'message': data['message'] ?? 'Изображения загружены',
          'imageUrls': imageUrls,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Ошибка загрузки изображений',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка загрузки изображений: $e'};
    }
  }

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
        url +=
            '?' +
            queryParams.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join('&');
      }

      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['venues'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getFavorites({String? type}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/favorites';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'favorites': List<Map<String, dynamic>>.from(data['favorites'] ?? []),
        };
      }
      return {
        'success': false,
        'message': 'Ошибка получения избранного',
        'favorites': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения: $e',
        'favorites': [],
      };
    }
  }

  static Future<Map<String, dynamic>> addToFavorites({
    required String itemType,
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: headers,
        body: jsonEncode({
          'itemType': itemType,
          'itemId': itemId,
          'itemData': itemData,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Добавлено в избранное',
        'favorite': data['favorite'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка добавления в избранное: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFromFavorites({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove'),
        headers: headers,
        body: jsonEncode({'itemType': itemType, 'itemId': itemId}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Удалено из избранного',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка удаления из избранного: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkIsFavorite({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/check'),
        headers: headers,
        body: jsonEncode({'itemType': itemType, 'itemId': itemId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'isFavorite': data['isFavorite'] ?? false};
      }
      return {'success': false, 'isFavorite': false};
    } catch (e) {
      return {'success': false, 'isFavorite': false};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: jsonEncode({
          if (username != null) 'username': username,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['user'] != null) {
        final processedUser = _processUserData(Map<String, dynamic>.from(data['user']));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(processedUser));
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

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Ошибка отправки кода',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения к серверу: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Ошибка проверки кода',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения к серверу: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Ошибка сброса пароля',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка подключения к серверу: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyInstruments() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/listings/instruments/my'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'instruments': data['instruments'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'instruments': []};
    }
  }

  static Future<Map<String, dynamic>> getMyStages() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/listings/stages/my'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'stages': data['stages'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'stages': []};
    }
  }

  static Future<Map<String, dynamic>> getMyStudios() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/listings/studios/my'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'studios': data['studios'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'studios': []};
    }
  }

  static Future<Map<String, dynamic>> getAllInstruments({
    String? category,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/listings/instruments';
      final queryParams = <String, String>{};

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'instruments': data['instruments'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'instruments': []};
    }
  }

  static Future<Map<String, dynamic>> getAllStages({String? search}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/listings/stages';

      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'stages': data['stages'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'stages': []};
    }
  }

  static Future<Map<String, dynamic>> getAllStudios({String? search}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/listings/studios';

      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'studios': data['studios'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'studios': []};
    }
  }

  static Future<Map<String, dynamic>> createInstrument(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/listings/instruments'),
        headers: headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      return {
        'success': responseData['success'] ?? false,
        'message': responseData['message'] ?? 'Ошибка создания',
        'instrument': responseData['instrument'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> createStage(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/listings/stages'),
        headers: headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      return {
        'success': responseData['success'] ?? false,
        'message': responseData['message'] ?? 'Ошибка создания',
        'stage': responseData['stage'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> createStudio(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/listings/studios'),
        headers: headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      return {
        'success': responseData['success'] ?? false,
        'message': responseData['message'] ?? 'Ошибка создания',
        'studio': responseData['studio'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteInstrument(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/listings/instruments/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Удалено',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteStage(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/listings/stages/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Удалено',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteStudio(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/listings/studios/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Удалено',
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateInstrument(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/listings/instruments/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final d = jsonDecode(response.body);
      return {'success': d['success'] ?? false, 'message': d['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStage(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/listings/stages/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final d = jsonDecode(response.body);
      return {'success': d['success'] ?? false, 'message': d['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStudio(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/listings/studios/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final d = jsonDecode(response.body);
      return {'success': d['success'] ?? false, 'message': d['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }


  static Future<Map<String, dynamic>> createBooking({
    required String itemId,
    required String itemType,
    required DateTime startDate,
    required DateTime endDate,
    required int duration,
    required String durationType,
    required double pricePerUnit,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: jsonEncode({
          'itemId': itemId,
          'itemType': itemType,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'duration': duration,
          'durationType': durationType,
          'pricePerUnit': pricePerUnit,
          'totalPrice': totalPrice,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Қате',
        'booking': data['booking'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserBookings({
    String? status,
    String? itemType,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/bookings/user';
      final queryParams = <String, String>{};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (itemType != null && itemType.isNotEmpty) {
        queryParams['itemType'] = itemType;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'bookings': data['bookings'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> getSellerBookings({
    String? status,
    String? itemType,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/bookings/sales';
      final queryParams = <String, String>{};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (itemType != null && itemType.isNotEmpty) {
        queryParams['itemType'] = itemType;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'bookings': data['bookings'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Қате',
        'booking': data['booking'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'status': status};
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        body['rejectionReason'] = rejectionReason;
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Қате',
        'booking': data['booking'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkAvailability({
    required String itemId,
    required String itemType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final url =
          '$baseUrl/bookings/availability/$itemType/$itemId?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'available': data['available'] ?? false,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'available': false,
        'message': 'Ошибка: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required String method,
    String? cardLastFour,
    String? cardHolder,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/payments/process'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
          'method': method,
          if (cardLastFour != null) 'cardLastFour': cardLastFour,
          if (cardHolder != null) 'cardHolder': cardHolder,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Қате',
        'payment': data['payment'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/history'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'payments': data['payments'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e', 'payments': []};
    }
  }

  static Future<List<DateTime>> getBookedDates({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final url = '$baseUrl/bookings/booked-dates/$itemType/$itemId';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['bookedDates'] as List)
            .map((d) => DateTime.parse(d as String))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  static Future<Map<String, dynamic>> getReviews({
    required String itemId,
    required String itemType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = '$baseUrl/reviews/$itemType/$itemId?limit=$limit&offset=$offset';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'reviews': data['reviews'] ?? [],
        'total': data['total'] ?? 0,
        'averageRating': (data['averageRating'] ?? 0).toDouble(),
      };
    } catch (e) {
      return {'success': false, 'reviews': [], 'total': 0, 'averageRating': 0.0};
    }
  }

  static Future<Map<String, dynamic>> createReview({
    required String itemId,
    required String itemType,
    required int rating,
    required String comment,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: headers,
        body: jsonEncode({'itemId': itemId, 'itemType': itemType, 'rating': rating, 'comment': comment}),
      );
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? '', 'review': data['review']};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/reviews/$reviewId'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkUserReview({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/reviews/check/$itemType/$itemId'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'hasReviewed': data['hasReviewed'] ?? false, 'review': data['review']};
    } catch (e) {
      return {'success': false, 'hasReviewed': false};
    }
  }

  // ==================== MESSAGE METHODS ====================

  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String? itemId,
    String? itemType,
    String? itemName,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: headers,
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
          if (itemId != null) 'itemId': itemId,
          if (itemType != null) 'itemType': itemType,
          if (itemName != null) 'itemName': itemName,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/messages/conversations'), headers: headers);
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'conversations': data['conversations'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'conversations': [], 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMessages(String userId, {String? itemId}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/messages/$userId';
      if (itemId != null && itemId.isNotEmpty) url += '?itemId=$itemId';
      final response = await http.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'messages': data['messages'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'messages': [], 'message': 'Ошибка: $e'};
    }
  }

  static Future<int> getUnreadMessageCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/messages/unread/count'), headers: headers);
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Moderation ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> assignRole(String userId, String role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/assign-role/$userId'),
        headers: headers,
        body: jsonEncode({'role': role}),
      );
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/auth/users'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'users': data['users'] ?? []};
    } catch (e) {
      return {'success': false, 'users': []};
    }
  }

  static Future<Map<String, dynamic>> moderationRemove(
      String type, String id, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/moderation/remove/$type/$id'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> moderationRestore(String type, String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/moderation/restore/$type/$id'),
        headers: headers,
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> moderationGetRemoved() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/moderation/removed'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'removed': data['removed'] ?? []};
    } catch (e) {
      return {'success': false, 'removed': []};
    }
  }

  static Future<Map<String, dynamic>> moderationGetAppeals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/moderation/appeals'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'appeals': data['appeals'] ?? []};
    } catch (e) {
      return {'success': false, 'appeals': []};
    }
  }

  static Future<Map<String, dynamic>> moderationResolveAppeal(
      String type, String id, bool restore) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/moderation/resolve-appeal/$type/$id'),
        headers: headers,
        body: jsonEncode({'restore': restore}),
      );
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAppeal(
      String type, String id, String message) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/moderation/appeal/$type/$id'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyRemovedListings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/moderation/my-removed'), headers: headers);
      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'removed': data['removed'] ?? []};
    } catch (e) {
      return {'success': false, 'removed': []};
    }
  }
}
