const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

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


const uploadsDir = path.join(__dirname, '..', 'uploads', 'avatars');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}


const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'avatar-' + req.user.userId + '-' + uniqueSuffix + path.extname(file.originalname));
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
    fileSize: 5 * 1024 * 1024 
  }
});


router.post('/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Файл не загружен' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
  
      fs.unlinkSync(req.file.path);
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

   
    if (user.avatar) {
      const oldAvatarPath = path.join(__dirname, '..', user.avatar.replace('/uploads', 'uploads'));
      if (fs.existsSync(oldAvatarPath)) {
        fs.unlinkSync(oldAvatarPath);
      }
    }

   
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    user.avatar = avatarUrl;
    await user.save();

    res.json({
      message: 'Аватар успешно загружен',
      avatarUrl: avatarUrl
    });
  } catch (err) {
    console.error('Upload avatar error:', err);
  
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ message: 'Ошибка загрузки аватара' });
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
