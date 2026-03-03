const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Review = require('../models/Review');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Требуется авторизация' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ success: false, message: 'Недействительный токен' });
    req.user = user;
    next();
  });
}

router.get('/:itemType/:itemId', async (req, res) => {
  try {
    const { itemType, itemId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    if (!['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({ success: false, message: 'Неверный тип' });
    }

    const reviews = await Review.find({ itemId, itemType })
      .sort({ createdAt: -1 })
      .skip(Number(offset))
      .limit(Number(limit));

    const total = await Review.countDocuments({ itemId, itemType });

    const avg = reviews.length > 0
      ? reviews.reduce((s, r) => s + r.rating, 0) / reviews.length
      : 0;

    res.json({
      success: true,
      reviews,
      total,
      averageRating: Math.round(avg * 10) / 10
    });
  } catch (error) {
    console.error('Get reviews error:', error);
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  try {
    const { itemId, itemType, rating, comment } = req.body;

    if (!['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({ success: false, message: 'Неверный тип' });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: 'Рейтинг 1-5 аралығында болуы керек' });
    }

    const user = await User.findById(req.user.userId).select('username avatar');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Қолданушы табылмады' });
    }

    const existing = await Review.findOne({ userId: req.user.userId, itemId, itemType });
    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Сіз бұл объектіге пікір қалдырдыңыз'
      });
    }

    const review = new Review({
      userId: req.user.userId,
      username: user.username,
      userAvatar: user.avatar || '',
      itemId,
      itemType,
      rating: Number(rating),
      comment: comment?.trim() || ''
    });

    await review.save();

    res.status(201).json({
      success: true,
      message: 'Пікір қосылды!',
      review
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Сіз бұл объектіге пікір қалдырдыңыз'
      });
    }
    console.error('Create review error:', error);
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const review = await Review.findOne({
      _id: req.params.id,
      userId: req.user.userId
    });

    if (!review) {
      return res.status(404).json({ success: false, message: 'Пікір табылмады' });
    }

    await Review.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: 'Пікір жойылды' });
  } catch (error) {
    console.error('Delete review error:', error);
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

router.get('/check/:itemType/:itemId', authenticateToken, async (req, res) => {
  try {
    const { itemType, itemId } = req.params;
    const existing = await Review.findOne({
      userId: req.user.userId,
      itemId,
      itemType
    });

    res.json({
      success: true,
      hasReviewed: !!existing,
      review: existing || null
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

module.exports = router;
