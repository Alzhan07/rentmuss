# RentMuss Server

Серверная часть приложения RentMuss на Node.js с использованием MongoDB.

## Установка и настройка

### 1. Установка MongoDB

**Windows:**
```bash
# Скачайте и установите MongoDB Community Edition с официального сайта
# https://www.mongodb.com/try/download/community
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install -y mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb
```

**WSL2:**
```bash
sudo apt-get update
sudo apt-get install -y mongodb
sudo service mongodb start
```

### 2. Проверка работы MongoDB

```bash
# Проверьте, что MongoDB запущен
sudo service mongodb status

# Подключитесь к MongoDB (опционально)
mongosh
```

### 3. Установка зависимостей

```bash
cd lib/server
npm install
```

### 4. Настройка переменных окружения

Файл `.env` уже создан. Проверьте настройки:

```env
MONGO_URI=mongodb://localhost:27017/rentmuss
JWT_SECRET=change_this_for_prod_super_secret_key_12345
SALT_ROUNDS=10
PEPPER=
PORT=5000
```

### 5. Инициализация базы данных

**Сброс базы данных и создание администратора:**
```bash
npm run reset-db
```

Это создаст администратора со следующими данными:
- **Имя:** Admin
- **Фамилия:** System
- **Email:** admin@rentmuss.com
- **Пароль:** Admin123!

⚠️ **ВАЖНО:** Смените пароль после первого входа!

**Создание дополнительного администратора:**
```bash
npm run create-admin
```

### 6. Запуск сервера

```bash
npm start
```

Сервер запустится на `http://localhost:5000`

## API Endpoints

### Аутентификация

#### Регистрация
```
POST /api/auth/register
Content-Type: application/json

{
  "name": "Иван",
  "lastName": "Иванов",
  "password": "SecurePass123!",
  "email": "ivan@example.com" // опционально
}
```

#### Вход
```
POST /api/auth/login
Content-Type: application/json

{
  "name": "Иван",
  "lastName": "Иванов",
  "password": "SecurePass123!"
}
```

#### Проверка имени
```
GET /api/auth/check-name/:name
```

#### Получить профиль
```
GET /api/auth/profile
Authorization: Bearer <token>
```

### Продавцы

#### Подать заявку на продавца
```
POST /api/auth/apply-seller
Authorization: Bearer <token>
Content-Type: application/json

{
  "shopName": "Мой магазин",
  "shopDescription": "Описание магазина"
}
```

#### Получить все заявки (только админ)
```
GET /api/auth/seller-applications
Authorization: Bearer <token>
```

#### Одобрить/Отклонить заявку (только админ)
```
POST /api/auth/review-seller-application/:userId
Authorization: Bearer <token>
Content-Type: application/json

{
  "approved": true,
  "rejectionReason": "Причина отклонения" // только если approved: false
}
```

## Система ролей

В приложении есть три роли:

### 1. User (Пользователь)
- Регистрируется через приложение
- Может просматривать товары
- Может подать заявку на продавца

### 2. Seller (Продавец)
- Получает роль после одобрения заявки администратором
- Может добавлять и управлять своими товарами
- Имеет информацию о магазине (название, описание, рейтинг)

### 3. Admin (Администратор)
- Создается через скрипты
- Может одобрять/отклонять заявки на продавца
- Полный доступ ко всем функциям системы

## Структура пользователя в БД

```javascript
{
  name: String,              // Имя пользователя
  lastName: String,          // Фамилия
  email: String,             // Email (опционально)
  passwordHash: String,      // Хеш пароля
  role: 'user' | 'seller' | 'admin', // Роль

  // Информация о магазине (для продавцов)
  sellerInfo: {
    shopName: String,
    shopDescription: String,
    shopLogo: String,
    verified: Boolean,
    rating: Number,
    totalSales: Number
  },

  // Статус заявки на продавца
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

## Безопасность

- Пароли хешируются с использованием bcrypt
- JWT токены для аутентификации (срок действия 7 дней)
- Rate limiting на регистрацию (5 запросов в минуту)
- Валидация сложности паролей (минимум 8 символов, заглавные и строчные буквы, цифры, спецсимволы)

## Разработка

### Структура проекта
```
lib/server/
├── models/
│   └── User.js           # Модель пользователя
├── routes/
│   └── auth.js           # Маршруты аутентификации
├── scripts/
│   ├── resetDatabase.js  # Сброс БД и создание админа
│   └── createAdmin.js    # Создание дополнительного админа
├── db.js                 # Подключение к MongoDB
├── server.js             # Главный файл сервера
├── .env                  # Переменные окружения
└── package.json          # Зависимости
```

### Полезные команды MongoDB

```bash
# Подключиться к MongoDB
mongosh

# Посмотреть все базы данных
show dbs

# Использовать базу rentmuss
use rentmuss

# Посмотреть все коллекции
show collections

# Посмотреть всех пользователей
db.users.find().pretty()

# Удалить конкретного пользователя
db.users.deleteOne({ name: "Имя" })

# Удалить всю коллекцию
db.users.drop()

# Удалить всю базу данных
db.dropDatabase()
```

## Решение проблем

### MongoDB не запускается

```bash
# Проверьте статус
sudo service mongodb status

# Перезапустите службу
sudo service mongodb restart

# Проверьте логи
sudo tail -f /var/log/mongodb/mongod.log
```

### Порт 5000 уже занят

Измените порт в `.env`:
```env
PORT=3000
```

### Ошибки подключения к MongoDB

Убедитесь, что:
1. MongoDB запущен
2. MONGO_URI правильно указан в `.env`
3. У вас есть права на создание базы данных

## Тестирование API

Вы можете использовать Postman, Insomnia или curl для тестирования API:

```bash
# Регистрация
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","lastName":"User","password":"Test123!"}'

# Вход
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","lastName":"User","password":"Test123!"}'
```
