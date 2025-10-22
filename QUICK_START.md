# Быстрый старт RentMuss

## 1. Установка MongoDB (WSL2/Linux)

```bash
# Обновите пакеты
sudo apt-get update

# Установите MongoDB
sudo apt-get install -y mongodb

# Запустите MongoDB
sudo service mongodb start

# Проверьте статус
sudo service mongodb status
```

## 2. Настройка и запуск сервера

```bash
# Перейдите в директорию сервера
cd lib/server

# Установите зависимости (если еще не установлены)
npm install

# Сбросьте базу данных и создайте администратора
npm run reset-db

# Запустите сервер
npm start
```

Сервер запустится на `http://localhost:5000`

### Учетные данные администратора по умолчанию:
- **Имя:** Admin
- **Фамилия:** System
- **Email:** admin@rentmuss.com
- **Пароль:** Admin123!

⚠️ **ВАЖНО:** Смените пароль после первого входа!

## 3. Запуск Flutter приложения

```bash
# Вернитесь в корневую директорию
cd ../..

# Запустите приложение
flutter run
```

## Тестирование регистрации

Попробуйте зарегистрировать нового пользователя:

1. Откройте приложение
2. Нажмите "Зарегистрироваться"
3. Заполните форму:
   - **Имя:** Тест
   - **Фамилия:** Пользователь
   - **Email:** test@example.com (необязательно)
   - **Пароль:** Test123! (минимум 8 символов, заглавная буква, строчная буква, цифра, спецсимвол)
4. Нажмите "Зарегистрироваться"

## Система ролей

### User (Пользователь)
- Создается при регистрации
- Может просматривать товары
- Может подать заявку на продавца

### Seller (Продавец)
- Получает роль после одобрения администратором
- Может добавлять свои товары

### Admin (Администратор)
- Создается через скрипт `npm run reset-db`
- Может одобрять заявки на продавца
- Полный доступ к системе

## Полезные команды

### Сервер
```bash
cd lib/server

# Запустить сервер
npm start

# Сбросить базу данных
npm run reset-db

# Создать нового администратора
npm run create-admin
```

### MongoDB
```bash
# Запустить MongoDB
sudo service mongodb start

# Остановить MongoDB
sudo service mongodb stop

# Перезапустить MongoDB
sudo service mongodb restart

# Проверить статус
sudo service mongodb status
```

### Flutter
```bash
# Запустить приложение
flutter run

# Очистить кэш
flutter clean

# Получить зависимости
flutter pub get
```

## Решение проблем

### Ошибка подключения к серверу

1. Убедитесь, что сервер запущен (`npm start` в `lib/server`)
2. Убедитесь, что MongoDB запущен (`sudo service mongodb status`)
3. Проверьте, что порт 5000 свободен

### Ошибка "Ошибка подключения к MongoDB"

1. Запустите MongoDB: `sudo service mongodb start`
2. Проверьте статус: `sudo service mongodb status`
3. Попробуйте перезапустить: `sudo service mongodb restart`

### Приложение не подключается к серверу

- На эмуляторе Android используйте `http://10.0.2.2:5000/api` вместо `http://localhost:5000/api`
- На физическом устройстве используйте IP адрес вашего компьютера

Измените в `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api'; // для эмулятора Android
// или
static const String baseUrl = 'http://192.168.x.x:5000/api'; // для физического устройства
```
