# Настройка отправки Email через Gmail

## Шаг 1: Включить двухфакторную аутентификацию (2FA) в Google аккаунте

1. Перейдите на https://myaccount.google.com/security
2. Найдите раздел "Двухэтапная аутентификация"
3. Включите её, если ещё не включена

## Шаг 2: Создать пароль приложения (App Password)

1. Перейдите на https://myaccount.google.com/apppasswords
   - Или: Google Account → Security → 2-Step Verification → App passwords
2. Выберите:
   - **Приложение**: Mail
   - **Устройство**: Other (Custom name) → введите "RentMus"
3. Нажмите "Generate" (Создать)
4. **Скопируйте 16-значный пароль** (без пробелов)

## Шаг 3: Обновить файл .env

Откройте файл `lib/server/.env` и обновите следующие строки:

```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=ваш-email@gmail.com          # ← Ваш Gmail адрес
EMAIL_PASS=abcd efgh ijkl mnop          # ← 16-значный пароль приложения
EMAIL_FROM=RentMus <noreply@rentmus.app>
```

**Пример:**
```env
EMAIL_USER=myemail@gmail.com
EMAIL_PASS=abcdefghijklmnop
```

## Шаг 4: Перезапустить сервер

```bash
cd lib/server
node server.js
```

## Проверка

После настройки при запросе восстановления пароля в консоли вы увидите:
```
✅ Email sent: <message-id>
```

А НЕ:
```
📧 [DEV MODE] Password reset code email:
```

---

## Альтернатива: SendGrid (более профессионально)

Если хотите использовать SendGrid вместо Gmail:

1. Зарегистрируйтесь на https://sendgrid.com (бесплатно до 100 писем/день)
2. Создайте API ключ
3. Обновите `.env`:

```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=apikey
EMAIL_PASS=SG.ваш-api-ключ-от-sendgrid
EMAIL_FROM=RentMus <noreply@yourdomain.com>
```

---

## Решение проблем

### "Invalid login: 535-5.7.8 Username and Password not accepted"

- Убедитесь, что включена 2FA
- Используйте **пароль приложения**, а не обычный пароль от Gmail
- Проверьте, что EMAIL_USER содержит полный email (с @gmail.com)

### "Connection timeout"

- Проверьте подключение к интернету
- Убедитесь, что EMAIL_PORT=587 и EMAIL_SECURE=false
- Попробуйте порт 465 с EMAIL_SECURE=true

### Письма попадают в спам

- Настройте SPF и DKIM записи для вашего домена
- Или используйте профессиональный сервис типа SendGrid

---

## Важно!

**Не коммитьте .env файл в git!**

Файл `.env` уже добавлен в `.gitignore`, но убедитесь, что не публикуете пароли в публичных репозиториях.
