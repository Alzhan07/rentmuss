const express = require('express');
const multer = require('multer');
const streamifier = require('streamifier');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { passwordStrengthError } = require('../utils/passwordStrength');
const cloudinary = require('../utils/cloudinary');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';


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

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

function uploadToCloudinary(buffer, folder, publicId) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, public_id: publicId, overwrite: true },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );
    streamifier.createReadStream(buffer).pipe(stream);
  });
}

router.post('/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Файл не загружен' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    const result = await uploadToCloudinary(
      req.file.buffer,
      'rentmuss/avatars',
      `avatar-${req.user.userId}`
    );

    user.avatar = result.secure_url;
    await user.save();

    res.json({
      message: 'Аватар успешно загружен',
      avatarUrl: result.secure_url,
    });
  } catch (err) {
    console.error('Upload avatar error:', err);
    res.status(500).json({ message: 'Ошибка загрузки аватара' });
  }
});


router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }
    res.json({ success: true, user });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ success: false, message: 'Ошибка получения профиля' });
  }
});

router.patch('/profile', authenticateToken, async (req, res) => {
  try {
    const { username, email } = req.body;

    if (!username || username.trim().length < 2) {
      return res.status(400).json({ success: false, message: 'Имя пользователя должно содержать минимум 2 символа' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }

    if (email && email !== user.email) {
      const existing = await User.findOne({ email: email.toLowerCase(), _id: { $ne: user._id } });
      if (existing) {
        return res.status(409).json({ success: false, message: 'Этот email уже используется' });
      }
    }

    user.username = username.trim();
    if (email !== undefined) user.email = email ? email.trim().toLowerCase() : null;
    await user.save();

    const userObj = user.toObject();
    delete userObj.passwordHash;

    res.json({ success: true, message: 'Профиль обновлен', user: userObj });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ success: false, message: 'Ошибка обновления профиля' });
  }
});

router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: 'Старый и новый пароли обязательны' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    const pwError = passwordStrengthError(newPassword, user.username);
    if (pwError) {
      return res.status(400).json({ message: pwError });
    }

    const bcrypt = require('bcrypt');
    const PEPPER = process.env.PEPPER || '';

    const isValidPassword = await bcrypt.compare(oldPassword + PEPPER, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ message: 'Неверный старый пароль' });
    }

    const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
    const newPasswordHash = await bcrypt.hash(newPassword + PEPPER, SALT_ROUNDS);

    user.passwordHash = newPasswordHash;
    await user.save();

    res.json({ message: 'Пароль успешно изменен' });
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ message: 'Ошибка изменения пароля' });
  }
});

module.exports = router;
