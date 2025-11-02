// lib/server/routes/favorites.js
const express = require('express');
const router = express.Router();
const Favorite = require('../models/Favorite');
const jwt = require('jsonwebtoken');

// Middleware для проверки аутентификации
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Требуется авторизация' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Недействительный токен' });
    }
    req.user = user;
    next();
  });
};

// Получить все избранные пользователя
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { type } = req.query; // Опционально фильтровать по типу

    const query = { userId: req.user.userId };
    if (type && ['instrument', 'stage', 'studio'].includes(type)) {
      query.itemType = type;
    }

    const favorites = await Favorite.find(query)
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      favorites: favorites
    });
  } catch (error) {
    console.error('Error fetching favorites:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка при получении избранного'
    });
  }
});

// Добавить в избранное
router.post('/add', authenticateToken, async (req, res) => {
  try {
    const { itemType, itemId, itemData } = req.body;

    // Валидация
    if (!itemType || !['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        message: 'Неверный тип объекта'
      });
    }

    if (!itemId || !itemData) {
      return res.status(400).json({
        success: false,
        message: 'Отсутствуют обязательные данные'
      });
    }

    // Проверяем, не добавлено ли уже в избранное
    const existing = await Favorite.findOne({
      userId: req.user.userId,
      itemType,
      itemId
    });

    if (existing) {
      return res.json({
        success: true,
        message: 'Уже в избранном',
        favorite: existing
      });
    }

    // Создаем новое избранное
    const favorite = new Favorite({
      userId: req.user.userId,
      itemType,
      itemId,
      itemData
    });

    await favorite.save();

    res.status(201).json({
      success: true,
      message: 'Добавлено в избранное',
      favorite
    });
  } catch (error) {
    console.error('Error adding to favorites:', error);

    // Обработка ошибки уникальности (если одновременные запросы)
    if (error.code === 11000) {
      return res.json({
        success: true,
        message: 'Уже в избранном'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Ошибка при добавлении в избранное'
    });
  }
});

// Удалить из избранного
router.delete('/remove', authenticateToken, async (req, res) => {
  try {
    const { itemType, itemId } = req.body;

    if (!itemType || !itemId) {
      return res.status(400).json({
        success: false,
        message: 'Отсутствуют обязательные данные'
      });
    }

    const result = await Favorite.findOneAndDelete({
      userId: req.user.userId,
      itemType,
      itemId
    });

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Объект не найден в избранном'
      });
    }

    res.json({
      success: true,
      message: 'Удалено из избранного'
    });
  } catch (error) {
    console.error('Error removing from favorites:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка при удалении из избранного'
    });
  }
});

// Проверить, в избранном ли объект
router.post('/check', authenticateToken, async (req, res) => {
  try {
    const { itemType, itemId } = req.body;

    if (!itemType || !itemId) {
      return res.status(400).json({
        success: false,
        message: 'Отсутствуют обязательные данные'
      });
    }

    const favorite = await Favorite.findOne({
      userId: req.user.userId,
      itemType,
      itemId
    });

    res.json({
      success: true,
      isFavorite: !!favorite
    });
  } catch (error) {
    console.error('Error checking favorite:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка при проверке избранного'
    });
  }
});

module.exports = router;
