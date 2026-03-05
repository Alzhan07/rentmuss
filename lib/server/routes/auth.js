const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const PasswordReset = require('../models/PasswordReset');
const { sendPasswordResetCode, sendEmailVerificationCode } = require('../utils/emailService');
const { passwordStrengthError } = require('../utils/passwordStrength');
const rateLimit = require('express-rate-limit');

const registerLimiter = rateLimit({
  windowMs: 60 * 1000, 
  max: 5,
  message: { message: 'Тіркелу әрекеттері тым көп, кейінірек көріңіз.' }
});

const router = express.Router();

const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';
const PEPPER = process.env.PEPPER || '';


function normalizeName(n) {
  return (n || '').toString().trim();
}

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Белгі берілмеген' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Жарамсыз токен' });
    }
    req.user = user;
    next();
  });
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Администратор құқықтары қажет' });
  }
  next();
}

function requireModeratorOrAdmin(req, res, next) {
  if (req.user.role !== 'admin' && req.user.role !== 'moderator') {
    return res.status(403).json({ message: 'Модератор немесе администратор құқықтары қажет' });
  }
  next();
}

router.post('/assign-role/:userId', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { role } = req.body;
    if (!['user', 'moderator'].includes(role)) {
      return res.status(400).json({ message: 'Рұқсат етілген рөлдер: user, moderator' });
    }
    const target = await User.findById(req.params.userId);
    if (!target) return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    if (target.role === 'admin') {
      return res.status(400).json({ message: 'Басқа администраторды өзгерту мүмкін емес' });
    }
    target.role = role;
    await target.save();
    res.json({ message: role === 'moderator' ? 'Модератор тағайындалды' : 'Рөл алынып тасталды', role });
  } catch (err) {
    console.error('Assign role error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.get('/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await User.find({ role: { $ne: 'admin' } })
      .select('username email role createdAt sellerApplication')
      .sort({ createdAt: -1 });
    res.json({ users });
  } catch (err) {
    console.error('Get users error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.get('/check-name/:name', async (req, res) => {
  try {
    const raw = req.params.name || '';
    const name = raw.toString().trim();
    if (!name) return res.status(400).json({ available: false, message: 'Аты бос' });

    const exists = await User.findOne({ username: name }).lean();
    return res.json({ available: !exists });
  } catch (err) {
    console.error('check-name error:', err);
    return res.status(500).json({ available: false });
  }
});

router.post('/register', registerLimiter, async (req, res) => {
  try {
    console.log('REGISTER body:', req.body);

    const { username, password, email } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'Пайдаланушы аты мен құпия сөз міндетті болып табылады' });
    }

    if (!email || !email.toString().includes('@')) {
      return res.status(400).json({ message: 'Email міндетті болып табылады' });
    }

    const usernameNorm = normalizeName(username);
    const emailNorm = email.toString().trim().toLowerCase();

    const pwError = passwordStrengthError(password, usernameNorm);
    if (pwError) {
      return res.status(400).json({ message: pwError });
    }

    const existingUsername = await User.findOne({ username: usernameNorm });
    if (existingUsername) {
      return res.status(409).json({ message: 'Мұндай атаумен пайдаланушы бар' });
    }

    const existingEmail = await User.findOne({ email: emailNorm });
    if (existingEmail) {
      return res.status(409).json({ message: 'Бұл email қолданылуда' });
    }

    const passwordHash = await bcrypt.hash(password + PEPPER, SALT_ROUNDS);

    const user = new User({
      username: usernameNorm,
      passwordHash,
      email: emailNorm,
      emailVerified: true,
      role: 'user',
    });

    const saved = await user.save();
    console.log('✅ User тіркелді:', saved._id.toString(), saved.username);

    // Fire and forget — не ждём email, отвечаем сразу
    (async () => {
      try {
        console.log("📧 Sending email to:", emailNorm);
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        await PasswordReset.deleteMany({ userId: saved._id });
        await PasswordReset.create({
          userId: saved._id,
          email: emailNorm,
          code,
          expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        });
        await sendEmailVerificationCode(emailNorm, code, usernameNorm);
      } catch (emailErr) {
        console.error('Email жіберу қатесі (тіркелу сәтті):', emailErr.message);
      }
    })();

    res.status(201).json({
      message: 'Тіркелу сәтті.',
      requiresVerification: false,
      userId: saved._id,
      email: emailNorm,
    });
  } catch (err) {
    console.error('Register error:', err);
    if (err.code === 11000) {
      return res.status(409).json({ message: 'Пайдаланушы аты немесе email қолданылуда' });
    }
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.post('/verify-email', async (req, res) => {
  try {
    const { userId, code } = req.body;
    if (!userId || !code) {
      return res.status(400).json({ message: 'userId және code міндетті' });
    }

    const record = await PasswordReset.findOne({
      userId,
      code: code.toString().trim(),
      used: false,
      expiresAt: { $gt: new Date() },
    });

    if (!record) {
      return res.status(400).json({ message: 'Код дұрыс емес немесе мерзімі өтіп кетті' });
    }

    record.used = true;
    await record.save();

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'Пайдаланушы табылмады' });

    user.emailVerified = true;
    await user.save();

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log('✅ Email расталды:', user.email);

    res.json({
      message: 'Email сәтті расталды',
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        role: user.role,
        avatar: user.avatar || null,
      },
    });
  } catch (err) {
    console.error('Verify email error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.post('/resend-verification', registerLimiter, async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId міндетті' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    if (user.emailVerified) return res.status(400).json({ message: 'Email расталған' });

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    await PasswordReset.deleteMany({ userId });
    await PasswordReset.create({
      userId,
      email: user.email,
      code,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    });

    await sendEmailVerificationCode(user.email, code, user.username);

    res.json({ message: 'Код қайта жіберілді' });
  } catch (err) {
    console.error('Resend verification error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});


router.post('/login', async (req, res) => {
  try {
    console.log('LOGIN body:', req.body);

    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Пайдаланушы аты мен құпия сөз міндетті болып табылады' });
    }

    const usernameNorm = normalizeName(username);

    const user = await User.findOne({ username: usernameNorm });
    console.log('🔍 Found user:', user ? { id: user._id.toString(), username: user.username, role: user.role } : null);

    if (!user) {
      return res.status(401).json({ message: 'Тіркеу деректері дұрыс емес' });
    }

    const ok = await bcrypt.compare(password + PEPPER, user.passwordHash);
    console.log('🔑 bcrypt.compare result:', ok);

    if (!ok) {
      return res.status(401).json({ message: 'Тіркеу деректері дұрыс емес' });
    }

    if (!user.emailVerified) {
      return res.status(403).json({
        message: 'Email расталмаған. Поштаңызды тексеріңіз.',
        requiresVerification: true,
        userId: user._id,
        email: user.email,
      });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Сәтті кіру',
      token,
      user: {
        id: user._id.toString(),
        username: user.username,
        email: user.email || null,
        role: user.role,
        avatar: user.avatar || null,
        sellerApplication: user.sellerApplication
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});


router.post('/apply-seller', authenticateToken, async (req, res) => {
  try {
    const { shopName, shopDescription } = req.body;

    if (!shopName) {
      return res.status(400).json({ message: 'Дүкеннің атауы міндетті' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    }

    if (user.role === 'seller') {
      return res.status(400).json({ message: 'Сіз сатушысыз' });
    }

    if (user.sellerApplication.status === 'pending') {
      return res.status(400).json({ message: 'Сіздің өтініміңіз қаралуда' });
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
      message: 'Сатушы болу өтінімі берілді',
      sellerApplication: user.sellerApplication
    });
  } catch (err) {
    console.error('Apply seller error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});


router.get('/seller-applications', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    
    const applications = await User.find({
      'sellerApplication.status': { $ne: 'none' }
    }).select('username email sellerInfo sellerApplication createdAt');

    res.json({ applications });
  } catch (err) {
    console.error('Get seller applications error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});


router.post('/review-seller-application/:userId', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { approved, rejectionReason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    }

    if (user.sellerApplication.status !== 'pending') {
      return res.status(400).json({ message: 'Өтінім қаралуда емес' });
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
      user.sellerApplication.rejectionReason = rejectionReason || 'Берілмеген';
    }

    await user.save();

    res.json({
      message: approved ? 'Өтінім қабылданды' : 'Өтінім қабылданбады',
      user: {
        id: user._id,
        username: user.username,
        role: user.role,
        sellerApplication: user.sellerApplication
      }
    });
  } catch (err) {
    console.error('Review seller application error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});


router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    }

    res.json({ user });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

module.exports = router;
