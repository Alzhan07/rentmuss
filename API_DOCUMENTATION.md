# 📚 Документация API и технологий проекта RentMus

## 🌐 HTTP методы и REST API

### 🔹 **GET запросы** (Получение данных)

#### Бэкенд (Node.js/Express)
```javascript
// auth.js
router.get('/check-name/:name', async (req, res) => {...})           // Проверка доступности имени
router.get('/seller-applications', authenticateToken, requireAdmin, async (req, res) => {...}) // Список заявок продавцов
router.get('/profile', authenticateToken, async (req, res) => {...}) // Получение профиля пользователя

// listings.js
router.get('/instruments', async (req, res) => {...})                // Все инструменты
router.get('/instruments/my', authenticateToken, requireSeller, async (req, res) => {...}) // Мои инструменты
router.get('/stages', async (req, res) => {...})                     // Все сцены
router.get('/stages/my', authenticateToken, requireSeller, async (req, res) => {...}) // Мои сцены
router.get('/studios', async (req, res) => {...})                    // Все студии
router.get('/studios/my', authenticateToken, requireSeller, async (req, res) => {...}) // Мои студии

// favorites.js
router.get('/', authenticateToken, async (req, res) => {...})        // Получение избранного
```

#### Flutter (Dart)
```dart
// api_service.dart
static Future<Map<String, dynamic>> getUserProfile() async {
  final response = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: headers);
}

static Future<Map<String, dynamic>> getAllInstruments({String? category, String? search}) async {
  final response = await http.get(Uri.parse(url), headers: headers);
}

static Future<Map<String, dynamic>> getMyInstruments() async {
  final response = await http.get(Uri.parse('$baseUrl/listings/instruments/my'), headers: headers);
}
```

---

### 🔹 **POST запросы** (Создание данных)

#### Бэкенд (Node.js/Express)
```javascript
// auth.js
router.post('/register', registerLimiter, async (req, res) => {...}) // Регистрация пользователя
router.post('/login', async (req, res) => {...})                     // Вход в систему
router.post('/apply-seller', authenticateToken, async (req, res) => {...}) // Заявка на продавца
router.post('/review-seller-application/:userId', authenticateToken, requireAdmin, async (req, res) => {...}) // Рассмотрение заявки

// listings.js
router.post('/instruments', authenticateToken, requireSeller, async (req, res) => {...}) // Создание инструмента
router.post('/stages', authenticateToken, requireSeller, async (req, res) => {...})      // Создание сцены
router.post('/studios', authenticateToken, requireSeller, async (req, res) => {...})     // Создание студии
router.post('/upload/:type', authenticateToken, requireSeller, upload.array('images', 5), async (req, res) => {...}) // Загрузка изображений

// user.js
router.post('/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {...}) // Загрузка аватара
router.post('/change-password', authenticateToken, async (req, res) => {...})                 // Смена пароля

// favorites.js
router.post('/add', authenticateToken, async (req, res) => {...})    // Добавить в избранное
router.post('/check', authenticateToken, async (req, res) => {...})  // Проверить избранное
```

#### Flutter (Dart)
```dart
// api_service.dart
static Future<Map<String, dynamic>> register({required String username, required String password, String? email}) async {
  final response = await http.post(Uri.parse('$baseUrl/auth/register'), headers: headers, body: jsonEncode({...}));
}

static Future<Map<String, dynamic>> login({required String username, required String password}) async {
  final response = await http.post(Uri.parse('$baseUrl/auth/login'), headers: headers, body: jsonEncode({...}));
}

static Future<Map<String, dynamic>> createInstrument(Map<String, dynamic> data) async {
  final response = await http.post(Uri.parse('$baseUrl/listings/instruments'), headers: headers, body: jsonEncode(data));
}

// Multipart (загрузка файлов)
static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/avatar'));
  request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
}

static Future<Map<String, dynamic>> uploadImages({required String type, required List<File> images}) async {
  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/listings/upload/$type'));
  for (var image in images) {
    request.files.add(await http.MultipartFile.fromPath('images', image.path));
  }
}
```

---

### 🔹 **PUT запросы** (Обновление данных)

#### Бэкенд (Node.js/Express)
```javascript
// listings.js
router.put('/instruments/:id', authenticateToken, requireSeller, async (req, res) => {...}) // Обновление инструмента
router.put('/stages/:id', authenticateToken, requireSeller, async (req, res) => {...})      // Обновление сцены
router.put('/studios/:id', authenticateToken, requireSeller, async (req, res) => {...})     // Обновление студии
```

---

### 🔹 **DELETE запросы** (Удаление данных)

#### Бэкенд (Node.js/Express)
```javascript
// listings.js
router.delete('/instruments/:id', authenticateToken, requireSeller, async (req, res) => {...}) // Удаление инструмента
router.delete('/stages/:id', authenticateToken, requireSeller, async (req, res) => {...})      // Удаление сцены
router.delete('/studios/:id', authenticateToken, requireSeller, async (req, res) => {...})     // Удаление студии

// favorites.js
router.delete('/remove', authenticateToken, async (req, res) => {...})                         // Удалить из избранного
```

#### Flutter (Dart)
```dart
static Future<Map<String, dynamic>> deleteInstrument(String id) async {
  final response = await http.delete(Uri.parse('$baseUrl/listings/instruments/$id'), headers: headers);
}
```

---

## ⚡ Асинхронные функции (async/await)

### Node.js (Backend)
```javascript
// Все роуты используют async/await
router.post('/login', async (req, res) => {
  try {
    const user = await User.findOne({ username: usernameNorm }); // await для MongoDB
    const ok = await bcrypt.compare(password + PEPPER, user.passwordHash); // await для bcrypt
    // ...
  } catch (err) {
    res.status(500).json({ message: 'Ошибка' });
  }
});

// Middleware функции
async function requireSeller(req, res, next) {
  try {
    const user = await User.findById(req.user.userId); // await для запроса к БД
    if (!user || (user.role !== 'seller' && user.role !== 'admin')) {
      return res.status(403).json({ success: false, message: 'Только для продавцов' });
    }
    next();
  } catch (err) {
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
}
```

### Flutter (Dart)
```dart
// Все API методы используют async/await
static Future<Map<String, dynamic>> login({
  required String username,
  required String password,
}) async {
  try {
    final response = await http.post(...); // await для HTTP запроса
    final data = jsonDecode(response.body);

    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance(); // await для SharedPreferences
      await prefs.setString('auth_token', data['token']); // await для сохранения
    }
    return {...};
  } catch (e) {
    return {'success': false, 'message': 'Ошибка: $e'};
  }
}

// В UI компонентах
Future<void> _submitForm() async {
  setState(() => _isSubmitting = true);

  try {
    // Сначала загружаем изображения
    final uploadResponse = await ApiService.uploadImages(
      type: 'instruments',
      images: _selectedImages,
    );

    // Затем создаём инструмент
    final response = await ApiService.createInstrument(data);

    if (response['success']) {
      Navigator.pop(context, true);
    }
  } catch (e) {
    // Обработка ошибки
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

---

## 📡 REST API структура

### Base URL
```
http://localhost:5000/api
```

### Эндпоинты

#### **Аутентификация** (`/api/auth`)
| Метод | Путь | Описание | Аутентификация |
|-------|------|----------|----------------|
| POST | `/register` | Регистрация | ❌ |
| POST | `/login` | Вход | ❌ |
| GET | `/profile` | Профиль пользователя | ✅ |
| GET | `/check-name/:name` | Проверка имени | ❌ |
| POST | `/apply-seller` | Заявка на продавца | ✅ |
| GET | `/seller-applications` | Список заявок | ✅ Admin |
| POST | `/review-seller-application/:userId` | Рассмотрение заявки | ✅ Admin |

#### **Пользователи** (`/api/user`)
| Метод | Путь | Описание | Аутентификация |
|-------|------|----------|----------------|
| POST | `/avatar` | Загрузка аватара | ✅ |
| POST | `/change-password` | Смена пароля | ✅ |

#### **Листинги** (`/api/listings`)
| Метод | Путь | Описание | Аутентификация |
|-------|------|----------|----------------|
| GET | `/instruments` | Все инструменты | ❌ |
| GET | `/instruments/my` | Мои инструменты | ✅ Seller |
| POST | `/instruments` | Создать инструмент | ✅ Seller |
| PUT | `/instruments/:id` | Обновить инструмент | ✅ Seller |
| DELETE | `/instruments/:id` | Удалить инструмент | ✅ Seller |
| GET | `/stages` | Все сцены | ❌ |
| GET | `/stages/my` | Мои сцены | ✅ Seller |
| POST | `/stages` | Создать сцену | ✅ Seller |
| PUT | `/stages/:id` | Обновить сцену | ✅ Seller |
| DELETE | `/stages/:id` | Удалить сцену | ✅ Seller |
| GET | `/studios` | Все студии | ❌ |
| GET | `/studios/my` | Мои студии | ✅ Seller |
| POST | `/studios` | Создать студию | ✅ Seller |
| PUT | `/studios/:id` | Обновить студию | ✅ Seller |
| DELETE | `/studios/:id` | Удалить студию | ✅ Seller |
| POST | `/upload/:type` | Загрузка изображений | ✅ Seller |

#### **Избранное** (`/api/favorites`)
| Метод | Путь | Описание | Аутентификация |
|-------|------|----------|----------------|
| GET | `/` | Получить избранное | ✅ |
| POST | `/add` | Добавить в избранное | ✅ |
| DELETE | `/remove` | Удалить из избранного | ✅ |
| POST | `/check` | Проверить избранное | ✅ |

---

## 🔐 Аутентификация

### JWT токены
```javascript
// Бэкенд - создание токена
const token = jwt.sign(
  { userId: user._id, role: user.role },
  JWT_SECRET,
  { expiresIn: '7d' }
);

// Middleware для проверки токена
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN"

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Недействительный токен' });
    req.user = user;
    next();
  });
}
```

```dart
// Flutter - сохранение и использование токена
static Future<Map<String, String>> _getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

---

## 📦 Используемые API и пакеты

### Backend (Node.js)
```json
{
  "express": "^4.18.2",           // Веб-фреймворк
  "mongoose": "^7.0.0",           // MongoDB ODM
  "bcrypt": "^5.1.0",             // Хеширование паролей
  "jsonwebtoken": "^9.0.0",       // JWT токены
  "multer": "^1.4.5-lts.1",       // Загрузка файлов
  "cors": "^2.8.5",               // CORS
  "dotenv": "^16.0.3",            // Переменные окружения
  "express-rate-limit": "^6.7.0", // Rate limiting
  "nodemailer": "^6.9.1"          // Отправка email
}
```

### Frontend (Flutter)
```yaml
dependencies:
  http: ^1.2.0                    # HTTP клиент
  shared_preferences: ^2.2.2      # Локальное хранилище
  image_picker: ^1.0.7            # Выбор изображений
  flutter:
    sdk: flutter
```

---

## 🗄️ База данных (MongoDB)

### Модели

#### User
```javascript
{
  username: String,
  email: String,
  passwordHash: String,
  role: 'user' | 'seller' | 'admin',
  avatar: String,                    // ⬅️ НОВОЕ ПОЛЕ
  sellerInfo: {
    shopName: String,
    shopDescription: String,
    shopLogo: String,
    verified: Boolean,
    rating: Number,
    totalSales: Number
  },
  sellerApplication: {
    status: 'none' | 'pending' | 'approved' | 'rejected',
    appliedAt: Date,
    reviewedAt: Date,
    reviewedBy: ObjectId,
    rejectionReason: String
  },
  createdAt: Date,
  updatedAt: Date
}
```

#### Instrument
```javascript
{
  name: String,
  category: String,
  brand: String,
  model: String,
  description: String,
  pricePerHour: Number,
  pricePerDay: Number,
  imageUrls: [String],               // ⬅️ Массив URL изображений
  rating: Number,
  reviewsCount: Number,
  location: String,
  condition: String,
  isAvailable: Boolean,
  features: [String],
  ownerId: ObjectId,
  ownerName: String,
  createdAt: Date
}
```

#### Stage / Studio
```javascript
{
  name: String,
  type: String,
  description: String,
  pricePerHour: Number,
  pricePerDay: Number,
  imageUrls: [String],               // ⬅️ Массив URL изображений
  rating: Number,
  reviewsCount: Number,
  location: String,
  address: String,
  capacity: Number,
  areaSquareMeters: Number,
  amenities: [String],
  isAvailable: Boolean,
  ownerId: ObjectId,
  ownerName: String,
  createdAt: Date
}
```

---

## 📸 Загрузка файлов (Multer)

### Backend конфигурация
```javascript
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const type = req.params.type || 'instruments'; // instruments, stages, studios
    cb(null, path.join(uploadsDir, type));
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, req.params.type + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Только изображения разрешены!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }
});

// Использование
router.post('/upload/:type', authenticateToken, requireSeller, upload.array('images', 5), async (req, res) => {...});
router.post('/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {...});
```

### Frontend загрузка
```dart
// Выбор изображений
final List<XFile> images = await _picker.pickMultiImage(
  maxWidth: 1920,
  maxHeight: 1080,
  imageQuality: 85,
);

// Загрузка на сервер
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/listings/upload/$type'));
request.headers['Authorization'] = 'Bearer $token';

for (var image in images) {
  request.files.add(await http.MultipartFile.fromPath('images', image.path));
}

final streamedResponse = await request.send();
final response = await http.Response.fromStream(streamedResponse);
```

---

## 🎯 Итого

### HTTP методы использовались:
- ✅ **GET** - получение данных (профиль, листинги, избранное)
- ✅ **POST** - создание данных (регистрация, логин, создание листингов, загрузка файлов)
- ✅ **PUT** - обновление данных (обновление листингов)
- ✅ **DELETE** - удаление данных (удаление листингов, удаление из избранного)

### Асинхронность:
- ✅ **Backend**: `async/await` во всех роутах для работы с MongoDB и bcrypt
- ✅ **Frontend**: `Future<>` и `async/await` для всех HTTP запросов и работы с SharedPreferences

### API технологии:
- ✅ **REST API** с использованием Express.js
- ✅ **JWT аутентификация** с Bearer токенами
- ✅ **MongoDB** с Mongoose ODM
- ✅ **Multer** для загрузки файлов
- ✅ **HTTP клиент** в Flutter для запросов
- ✅ **SharedPreferences** для хранения токенов
- ✅ **Image Picker** для выбора изображений
