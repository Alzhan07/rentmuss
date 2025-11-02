// lib/server/routes/auth.js
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const PasswordReset = require('../models/PasswordReset');
const { sendPasswordResetCode } = require('../utils/emailService');
const rateLimit = require('express-rate-limit');

// Ограничитель для регистрации (5 запросов в минуту с одного IP)
const registerLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 минута
  max: 5,
  message: { message: 'Слишком много попыток регистрации, попробуйте позже.' }
});

const router = express.Router();

const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';
const PEPPER = process.env.PEPPER || '';

// Функция проверки сложности пароля
function isStrongPassword(pw) {
  if (!pw || typeof pw !== 'string') return false;
  if (pw.length < 8) return false;
  if (!/[a-z]/.test(pw)) return false;
  if (!/[A-Z]/.test(pw)) return false;
  if (!/[0-9]/.test(pw)) return false;
  if (!/[!@#\$%\^&\*\(\)\-_=\+\[\]\{\};:'",.<>\/\\\?|`~]/.test(pw)) return false;
  return true;
}

function normalizeName(n) {
  return (n || '').toString().trim();
}

// Middleware для проверки JWT токена
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Токен не предоставлен' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Недействительный токен' });
    }
    req.user = user;
    next();
  });
}

// Middleware для проверки роли администратора
function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Требуются права администратора' });
  }
  next();
}

// Проверка доступности имени
router.get('/check-name/:name', async (req, res) => {
  try {
    const raw = req.params.name || '';
    const name = raw.toString().trim();
    if (!name) return res.status(400).json({ available: false, message: 'Имя пустое' });

    const exists = await User.findOne({ name }).lean();
    return res.json({ available: !exists });
  } catch (err) {
    console.error('check-name error:', err);
    return res.status(500).json({ available: false });
  }
});

// ====================== РЕГИСТРАЦИЯ ======================
router.post('/register', registerLimiter, async (req, res) => {
  try {
    console.log('REGISTER body:', req.body);

    const { username, password, email } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'Имя пользователя и пароль обязательны' });
    }

    if (!isStrongPassword(password)) {
      return res.status(400).json({
        message: 'Пароль не соответствует требованиям безопасности:\n• Минимум 8 символов\n• Заглавная буква (A-Z)\n• Строчная буква (a-z)\n• Цифра (0-9)\n• Спецсимвол (!@#$%^&*)'
      });
    }

    const usernameNorm = normalizeName(username);

    const existing = await User.findOne({ username: usernameNorm });
    if (existing) {
      return res.status(409).json({ message: 'Пользователь с таким именем уже существует' });
    }

    const passwordHash = await bcrypt.hash(password + PEPPER, SALT_ROUNDS);

    const user = new User({
      username: usernameNorm,
      passwordHash,
      role: 'user',
      ...(email ? { email: email.toString().trim().toLowerCase() } : {})
    });

    const saved = await user.save();
    console.log('✅ User зарегистрирован:', saved._id.toString(), saved.username);

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'Пользователь создан',
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email || null,
        role: user.role
      }
    });
  } catch (err) {
    console.error('Register error:', err);
    if (err.code === 11000) {
      return res.status(409).json({ message: 'Имя пользователя или email уже используется' });
    }
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ====================== ЛОГИН ======================
router.post('/login', async (req, res) => {
  try {
    console.log('LOGIN body:', req.body);

    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Имя пользователя и пароль обязательны' });
    }

    const usernameNorm = normalizeName(username);

    const user = await User.findOne({ username: usernameNorm });
    console.log('🔍 Found user:', user ? { id: user._id.toString(), username: user.username, role: user.role } : null);

    if (!user) {
      return res.status(401).json({ message: 'Неверные учетные данные' });
    }

    const ok = await bcrypt.compare(password + PEPPER, user.passwordHash);
    console.log('🔑 bcrypt.compare result:', ok);

    if (!ok) {
      return res.status(401).json({ message: 'Неверные учетные данные' });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Успешный вход',
      token,
      user: {
        id: user._id.toString(),
        username: user.username,
        email: user.email || null,
        role: user.role,
        sellerApplication: user.sellerApplication
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ====================== ПОДАТЬ ЗАЯВКУ НА ПРОДАВЦА ======================
router.post('/apply-seller', authenticateToken, async (req, res) => {
  try {
    const { shopName, shopDescription } = req.body;

    if (!shopName) {
      return res.status(400).json({ message: 'Название магазина обязательно' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    if (user.role === 'seller') {
      return res.status(400).json({ message: 'Вы уже являетесь продавцом' });
    }

    if (user.sellerApplication.status === 'pending') {
      return res.status(400).json({ message: 'Ваша заявка уже находится на рассмотрении' });
    }

    user.sellerApplication = {
      status: 'pending',
      appliedAt: new Date(),
      reviewedAt: null,
      reviewedBy: null,
      rejectionReason: null
    };

    user.sellerInfo = {
      shopName,
      shopDescription: shopDescription || '',
      verified: false,
      rating: 0,
      totalSales: 0
    };

    await user.save();

    res.json({
      message: 'Заявка на продавца подана',
      sellerApplication: user.sellerApplication
    });
  } catch (err) {
    console.error('Apply seller error:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ====================== ПОЛУЧИТЬ ВСЕ ЗАЯВКИ НА ПРОДАВЦА (ТОЛЬКО ADMIN) ======================
router.get('/seller-applications', authenticateToken, requireAdmin, async (req, res) => {
  try {
    // Возвращаем все заявки (pending, approved, rejected)
    const applications = await User.find({
      'sellerApplication.status': { $exists: true }
    }).select('username email sellerInfo sellerApplication createdAt');

    res.json({ applications });
  } catch (err) {
    console.error('Get seller applications error:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ====================== ОДОБРИТЬ/ОТКЛОНИТЬ ЗАЯВКУ НА ПРОДАВЦА (ТОЛЬКО ADMIN) ======================
router.post('/review-seller-application/:userId', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { approved, rejectionReason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    if (user.sellerApplication.status !== 'pending') {
      return res.status(400).json({ message: 'Заявка не находится на рассмотрении' });
    }

    if (approved) {
      user.role = 'seller';
      user.sellerApplication.status = 'approved';
      user.sellerApplication.reviewedAt = new Date();
      user.sellerApplication.reviewedBy = req.user.userId;
    } else {
      user.sellerApplication.status = 'rejected';
      user.sellerApplication.reviewedAt = new Date();
      user.sellerApplication.reviewedBy = req.user.userId;
      user.sellerApplication.rejectionReason = rejectionReason || 'Не указана';
    }

    await user.save();

    res.json({
      message: approved ? 'Заявка одобрена' : 'Заявка отклонена',
      user: {
        id: user._id,
        username: user.username,
        role: user.role,
        sellerApplication: user.sellerApplication
      }
    });
  } catch (err) {
    console.error('Review seller application error:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ====================== ПОЛУЧИТЬ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ======================
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    res.json({ user });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ========== ВОССТАНОВЛЕНИЕ ПАРОЛЯ ==========

// Ограничитель для запроса кода (3 попытки в 15 минут)
const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 3,
  message: { message: 'Слишком много попыток. Попробуйте через 15 минут.' }
});

/**
 * POST /api/auth/forgot-password
 * Отправить код восстановления пароля на email
 */
router.post('/forgot-password', forgotPasswordLimiter, async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email обязателен'
      });
    }

    // Найти пользователя по email
    const user = await User.findOne({ email: email.toLowerCase().trim() });

    // Для безопасности всегда возвращаем успех, даже если пользователь не найден
    if (!user) {
      return res.json({
        success: true,
        message: 'Если email существует, код восстановления будет отправлен на него'
      });
    }

    // Генерируем 6-значный код
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Удаляем старые неиспользованные коды для этого пользователя
    await PasswordReset.deleteMany({
      userId: user._id,
      used: false
    });

    // Создаем новый код
    const passwordReset = new PasswordReset({
      userId: user._id,
      email: user.email,
      code: code,
    });

    await passwordReset.save();

    // Отправляем email
    const emailResult = await sendPasswordResetCode(user.email, code, user.username);

    if (!emailResult.success) {
      console.error('Failed to send email:', emailResult.error);
      // В продакшене можно вернуть ошибку, но для разработки продолжаем
    }

    res.json({
      success: true,
      message: 'Код восстановления отправлен на ваш email'
    });

  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({
      success: false,
      message: 'Ошибка сервера'
    });
  }
});

/**
 * POST /api/auth/verify-reset-code
 * Проверить код восстановления
 */
router.post('/verify-reset-code', async (req, res) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({
        success: false,
        message: 'Email и код обязательны'
      });
    }

    // Найти код восстановления
    const resetRequest = await PasswordReset.findOne({
      email: email.toLowerCase().trim(),
      code: code.trim(),
      used: false,
      expiresAt: { $gt: new Date() }
    });

    if (!resetRequest) {
      return res.status(400).json({
        success: false,
        message: 'Неверный или истекший код'
      });
    }

    res.json({
      success: true,
      message: 'Код подтвержден',
      resetId: resetRequest._id
    });

  } catch (err) {
    console.error('Verify code error:', err);
    res.status(500).json({
      success: false,
      message: 'Ошибка сервера'
    });
  }
});

/**
 * POST /api/auth/reset-password
 * Сбросить пароль с использованием кода
 */
router.post('/reset-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email, код и новый пароль обязательны'
      });
    }

    // Проверка надежности пароля
    if (!isStrongPassword(newPassword)) {
      return res.status(400).json({
        success: false,
        message: 'Пароль не соответствует требованиям безопасности:\n• Минимум 8 символов\n• Заглавная буква (A-Z)\n• Строчная буква (a-z)\n• Цифра (0-9)\n• Спецсимвол (!@#$%^&*)'
      });
    }

    // Найти код восстановления
    const resetRequest = await PasswordReset.findOne({
      email: email.toLowerCase().trim(),
      code: code.trim(),
      used: false,
      expiresAt: { $gt: new Date() }
    });

    if (!resetRequest) {
      return res.status(400).json({
        success: false,
        message: 'Неверный или истекший код'
      });
    }

    // Найти пользователя
    const user = await User.findById(resetRequest.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Пользователь не найден'
      });
    }

    // Хешируем новый пароль с pepper
    const pepperedPassword = newPassword + PEPPER;
    const passwordHash = await bcrypt.hash(pepperedPassword, SALT_ROUNDS);

    // Обновляем пароль
    user.passwordHash = passwordHash;
    await user.save();

    // Отмечаем код как использованный
    resetRequest.used = true;
    await resetRequest.save();

    res.json({
      success: true,
      message: 'Пароль успешно изменен'
    });

  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({
      success: false,
      message: 'Ошибка сервера'
    });
  }
});

module.exports = router;
