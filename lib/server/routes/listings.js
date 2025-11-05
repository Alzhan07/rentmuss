const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Instrument = require('../models/Instrument');
const Stage = require('../models/Stage');
const Studio = require('../models/Studio');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';

// Создаём папки для загрузок
const uploadsDir = path.join(__dirname, '..', 'uploads');
['instruments', 'stages', 'studios'].forEach(folder => {
  const dir = path.join(uploadsDir, folder);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Настройка multer для загрузки изображений
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const type = req.params.type || 'instruments';
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


function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Требуется авторизация' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Недействительный токен' });
    }
    req.user = user;
    next();
  });
}


async function requireSeller(req, res, next) {
  try {
    const user = await User.findById(req.user.userId);
    if (!user || (user.role !== 'seller' && user.role !== 'admin')) {
      return res.status(403).json({ success: false, message: 'Только для продавцов' });
    }
    next();
  } catch (err) {
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
}


router.get('/instruments', async (req, res) => {
  try {
    const { category, search } = req.query;
    const query = { isAvailable: true };

    if (category && category !== 'Все') {
      query.category = category;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const instruments = await Instrument.find(query).sort({ createdAt: -1 });

    res.json({
      success: true,
      instruments
    });
  } catch (err) {
    console.error('Get instruments error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.get('/instruments/my', authenticateToken, requireSeller, async (req, res) => {
  try {
    const instruments = await Instrument.find({ ownerId: req.user.userId }).sort({ createdAt: -1 });

    res.json({
      success: true,
      instruments
    });
  } catch (err) {
    console.error('Get my instruments error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.post('/instruments', authenticateToken, requireSeller, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const instrument = new Instrument({
      ...req.body,
      ownerId: req.user.userId,
      ownerName: user.username
    });

    await instrument.save();

    res.status(201).json({
      success: true,
      message: 'Инструмент добавлен',
      instrument
    });
  } catch (err) {
    console.error('Create instrument error:', err);
    res.status(500).json({ success: false, message: 'Ошибка создания инструмента' });
  }
});


router.put('/instruments/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const instrument = await Instrument.findOne({ _id: req.params.id, ownerId: req.user.userId });

    if (!instrument) {
      return res.status(404).json({ success: false, message: 'Инструмент не найден' });
    }

    Object.assign(instrument, req.body);
    await instrument.save();

    res.json({
      success: true,
      message: 'Инструмент обновлен',
      instrument
    });
  } catch (err) {
    console.error('Update instrument error:', err);
    res.status(500).json({ success: false, message: 'Ошибка обновления' });
  }
});


router.delete('/instruments/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const instrument = await Instrument.findOneAndDelete({ _id: req.params.id, ownerId: req.user.userId });

    if (!instrument) {
      return res.status(404).json({ success: false, message: 'Инструмент не найден' });
    }

    res.json({
      success: true,
      message: 'Инструмент удален'
    });
  } catch (err) {
    console.error('Delete instrument error:', err);
    res.status(500).json({ success: false, message: 'Ошибка удаления' });
  }
});


router.get('/stages', async (req, res) => {
  try {
    const { type, search } = req.query;
    const query = { isAvailable: true };

    if (type) {
      query.type = type;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const stages = await Stage.find(query).sort({ createdAt: -1 });

    res.json({
      success: true,
      stages
    });
  } catch (err) {
    console.error('Get stages error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.get('/stages/my', authenticateToken, requireSeller, async (req, res) => {
  try {
    const stages = await Stage.find({ ownerId: req.user.userId }).sort({ createdAt: -1 });

    res.json({
      success: true,
      stages
    });
  } catch (err) {
    console.error('Get my stages error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.post('/stages', authenticateToken, requireSeller, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const stage = new Stage({
      ...req.body,
      ownerId: req.user.userId,
      ownerName: user.username
    });

    await stage.save();

    res.status(201).json({
      success: true,
      message: 'Сцена добавлена',
      stage
    });
  } catch (err) {
    console.error('Create stage error:', err);
    res.status(500).json({ success: false, message: 'Ошибка создания сцены' });
  }
});

router.put('/stages/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const stage = await Stage.findOne({ _id: req.params.id, ownerId: req.user.userId });

    if (!stage) {
      return res.status(404).json({ success: false, message: 'Сцена не найдена' });
    }

    Object.assign(stage, req.body);
    await stage.save();

    res.json({
      success: true,
      message: 'Сцена обновлена',
      stage
    });
  } catch (err) {
    console.error('Update stage error:', err);
    res.status(500).json({ success: false, message: 'Ошибка обновления' });
  }
});

router.delete('/stages/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const stage = await Stage.findOneAndDelete({ _id: req.params.id, ownerId: req.user.userId });

    if (!stage) {
      return res.status(404).json({ success: false, message: 'Сцена не найдена' });
    }

    res.json({
      success: true,
      message: 'Сцена удалена'
    });
  } catch (err) {
    console.error('Delete stage error:', err);
    res.status(500).json({ success: false, message: 'Ошибка удаления' });
  }
});

router.get('/studios', async (req, res) => {
  try {
    const { type, search } = req.query;
    const query = { isAvailable: true };

    if (type) {
      query.type = type;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const studios = await Studio.find(query).sort({ createdAt: -1 });

    res.json({
      success: true,
      studios
    });
  } catch (err) {
    console.error('Get studios error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.get('/studios/my', authenticateToken, requireSeller, async (req, res) => {
  try {
    const studios = await Studio.find({ ownerId: req.user.userId }).sort({ createdAt: -1 });

    res.json({
      success: true,
      studios
    });
  } catch (err) {
    console.error('Get my studios error:', err);
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

router.post('/studios', authenticateToken, requireSeller, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const studio = new Studio({
      ...req.body,
      ownerId: req.user.userId,
      ownerName: user.username
    });

    await studio.save();

    res.status(201).json({
      success: true,
      message: 'Студия добавлена',
      studio
    });
  } catch (err) {
    console.error('Create studio error:', err);
    res.status(500).json({ success: false, message: 'Ошибка создания студии' });
  }
});

router.put('/studios/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const studio = await Studio.findOne({ _id: req.params.id, ownerId: req.user.userId });

    if (!studio) {
      return res.status(404).json({ success: false, message: 'Студия не найдена' });
    }

    Object.assign(studio, req.body);
    await studio.save();

    res.json({
      success: true,
      message: 'Студия обновлена',
      studio
    });
  } catch (err) {
    console.error('Update studio error:', err);
    res.status(500).json({ success: false, message: 'Ошибка обновления' });
  }
});

router.delete('/studios/:id', authenticateToken, requireSeller, async (req, res) => {
  try {
    const studio = await Studio.findOneAndDelete({ _id: req.params.id, ownerId: req.user.userId });

    if (!studio) {
      return res.status(404).json({ success: false, message: 'Студия не найдена' });
    }

    res.json({
      success: true,
      message: 'Студия удалена'
    });
  } catch (err) {
    console.error('Delete studio error:', err);
    res.status(500).json({ success: false, message: 'Ошибка удаления' });
  }
});

// Универсальный эндпоинт для загрузки изображений
// type может быть: instruments, stages, studios
router.post('/upload/:type', authenticateToken, requireSeller, upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'Файлы не загружены' });
    }

    const type = req.params.type;
    const imageUrls = req.files.map(file => `/uploads/${type}/${file.filename}`);

    res.json({
      success: true,
      message: 'Изображения загружены',
      imageUrls
    });
  } catch (err) {
    console.error('Upload images error:', err);
    // Удаляем загруженные файлы в случае ошибки
    if (req.files) {
      req.files.forEach(file => {
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }
    res.status(500).json({ success: false, message: 'Ошибка загрузки изображений' });
  }
});

module.exports = router;
