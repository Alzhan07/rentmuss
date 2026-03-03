const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Instrument = require('../models/Instrument');
const Stage = require('../models/Stage');
const Studio = require('../models/Studio');
const { sendBookingConfirmedEmail } = require('../utils/emailService');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

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

// Helper function to get item model based on type
function getItemModel(itemType) {
  switch (itemType) {
    case 'instrument':
      return Instrument;
    case 'stage':
      return Stage;
    case 'studio':
      return Studio;
    default:
      return null;
  }
}

// Helper function to check availability
async function checkAvailability(itemId, itemType, startDate, endDate, excludeBookingId = null) {
  const query = {
    itemId,
    itemType,
    status: { $in: ['pending', 'confirmed'] },
    $or: [
      // New booking starts during existing booking
      { startDate: { $lte: startDate }, endDate: { $gt: startDate } },
      // New booking ends during existing booking
      { startDate: { $lt: endDate }, endDate: { $gte: endDate } },
      // New booking encompasses existing booking
      { startDate: { $gte: startDate }, endDate: { $lte: endDate } }
    ]
  };

  if (excludeBookingId) {
    query._id = { $ne: excludeBookingId };
  }

  const conflictingBookings = await Booking.find(query);
  return conflictingBookings.length === 0;
}

// CREATE BOOKING
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { itemId, itemType, startDate, endDate, duration, durationType, pricePerUnit, totalPrice, notes } = req.body;

    // Validate item type
    if (!['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        message: 'Неверный тип объекта'
      });
    }

    // Validate dates
    const start = new Date(startDate);
    const end = new Date(endDate);
    const now = new Date();

    if (start < now) {
      return res.status(400).json({
        success: false,
        message: 'Дата начала не может быть в прошлом'
      });
    }

    if (end <= start) {
      return res.status(400).json({
        success: false,
        message: 'Дата окончания должна быть позже даты начала'
      });
    }

    // Check if item exists
    const ItemModel = getItemModel(itemType);
    const item = await ItemModel.findById(itemId);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Объект не найден'
      });
    }

    if (!item.isAvailable) {
      return res.status(400).json({
        success: false,
        message: 'Объект недоступен для аренды'
      });
    }

    // Check availability (no overlapping bookings)
    const isAvailable = await checkAvailability(itemId, itemType, start, end);

    if (!isAvailable) {
      return res.status(400).json({
        success: false,
        message: 'Этот объект уже забронирован на выбранные даты'
      });
    }

    // Create booking
    const booking = new Booking({
      userId: req.user.userId,
      itemId,
      itemType,
      sellerId: item.ownerId,
      startDate: start,
      endDate: end,
      duration,
      durationType,
      pricePerUnit,
      totalPrice,
      notes,
      status: 'pending'
    });

    await booking.save();

    res.status(201).json({
      success: true,
      message: 'Брондау расталды!',
      booking
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка создания бронирования'
    });
  }
});

// GET USER'S BOOKINGS
router.get('/user', authenticateToken, async (req, res) => {
  try {
    const { status, itemType } = req.query;
    const query = { userId: req.user.userId };

    if (status) {
      query.status = status;
    }

    if (itemType && ['instrument', 'stage', 'studio'].includes(itemType)) {
      query.itemType = itemType;
    }

    const bookings = await Booking.find(query)
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      bookings
    });
  } catch (error) {
    console.error('Get user bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения бронирований'
    });
  }
});

// GET SELLER'S BOOKINGS (bookings for seller's items)
router.get('/sales', authenticateToken, async (req, res) => {
  try {
    const { status, itemType } = req.query;
    const query = { sellerId: req.user.userId };

    if (status) {
      query.status = status;
    }

    if (itemType && ['instrument', 'stage', 'studio'].includes(itemType)) {
      query.itemType = itemType;
    }

    const bookings = await Booking.find(query)
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      bookings
    });
  } catch (error) {
    console.error('Get seller bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения бронирований'
    });
  }
});

// GET SINGLE BOOKING
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Бронирование не найдено'
      });
    }

    // Check if user is owner or seller
    if (booking.userId.toString() !== req.user.userId &&
        booking.sellerId.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Доступ запрещен'
      });
    }

    res.json({
      success: true,
      booking
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения бронирования'
    });
  }
});

// CANCEL BOOKING
router.patch('/:id/cancel', authenticateToken, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Бронирование не найдено'
      });
    }

    // Only booking owner can cancel
    if (booking.userId.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Только владелец брони может отменить'
      });
    }

    // Check if already cancelled or completed
    if (booking.status === 'cancelled') {
      return res.json({
        success: true,
        message: 'Бронирование уже отменено',
        booking
      });
    }

    if (booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Нельзя отменить завершенное бронирование'
      });
    }

    booking.status = 'cancelled';
    await booking.save();

    res.json({
      success: true,
      message: 'Бронирование отменено',
      booking
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка отмены бронирования'
    });
  }
});

// CHECK AVAILABILITY FOR ITEM
router.get('/availability/:itemType/:itemId', async (req, res) => {
  try {
    const { itemType, itemId } = req.params;
    const { startDate, endDate } = req.query;

    if (!['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        message: 'Неверный тип объекта'
      });
    }

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Требуются даты начала и окончания'
      });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    const isAvailable = await checkAvailability(itemId, itemType, start, end);

    res.json({
      success: true,
      available: isAvailable,
      message: isAvailable ? 'Доступно' : 'Занято на эти даты'
    });
  } catch (error) {
    console.error('Check availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка проверки доступности'
    });
  }
});

// UPDATE BOOKING STATUS (for sellers)
router.patch('/:id/status', authenticateToken, async (req, res) => {
  try {
    const { status, rejectionReason } = req.body;
    const booking = await Booking.findById(req.params.id)
      .populate('userId', 'name email');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Бронирование не найдено'
      });
    }

    // Only seller can update status
    if (booking.sellerId.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Доступ запрещен'
      });
    }

    // Allowed transitions: pending -> confirmed | cancelled
    const allowedTransitions = {
      pending: ['confirmed', 'cancelled'],
      confirmed: ['completed', 'cancelled'],
    };

    const allowed = allowedTransitions[booking.status] || [];
    if (!allowed.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Нельзя перевести статус из '${booking.status}' в '${status}'`
      });
    }

    // Rejection reason required when cancelling a pending booking
    if (status === 'cancelled' && booking.status === 'pending' && !rejectionReason?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Укажите причину отказа'
      });
    }

    booking.status = status;
    if (rejectionReason?.trim()) {
      booking.rejectionReason = rejectionReason.trim();
    }
    await booking.save();

    // Send email notification to client when booking is confirmed
    if (status === 'confirmed' && booking.userId) {
      try {
        const client = await User.findById(booking.userId).select('username email');
        if (client?.email) {
          const ItemModel = getItemModel(booking.itemType);
          const item = ItemModel ? await ItemModel.findById(booking.itemId).select('name') : null;
          const itemName = item?.name || null;
          await sendBookingConfirmedEmail(client.email, client.username, itemName);
        }
      } catch (emailErr) {
        console.error('Failed to send booking confirmed email:', emailErr.message);
      }
    }

    res.json({
      success: true,
      message: status === 'confirmed' ? 'Бронирование подтверждено' : 'Бронирование отклонено',
      booking
    });
  } catch (error) {
    console.error('Update status error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка обновления статуса'
    });
  }
});

// GET BOOKED DATES FOR ITEM (for calendar display)
router.get('/booked-dates/:itemType/:itemId', async (req, res) => {
  try {
    const { itemType, itemId } = req.params;
    const { month, year } = req.query; // optional: filter by month/year

    if (!['instrument', 'stage', 'studio'].includes(itemType)) {
      return res.status(400).json({ success: false, message: 'Неверный тип объекта' });
    }

    // Build date range filter (default: next 3 months)
    const now = new Date();
    const from = new Date(now.getFullYear(), now.getMonth(), 1);
    const to = new Date(now.getFullYear(), now.getMonth() + 3, 31);

    const bookings = await Booking.find({
      itemId,
      itemType,
      status: { $in: ['pending', 'confirmed'] },
      endDate: { $gte: from },
      startDate: { $lte: to }
    }).select('startDate endDate');

    // Expand each booking into individual booked days
    const bookedDates = [];
    for (const booking of bookings) {
      const start = new Date(booking.startDate);
      const end = new Date(booking.endDate);
      const current = new Date(start);

      while (current <= end) {
        bookedDates.push(current.toISOString().split('T')[0]); // YYYY-MM-DD
        current.setDate(current.getDate() + 1);
      }
    }

    // Remove duplicates
    const uniqueDates = [...new Set(bookedDates)];

    res.json({ success: true, bookedDates: uniqueDates });
  } catch (error) {
    console.error('Get booked dates error:', error);
    res.status(500).json({ success: false, message: 'Ошибка получения дат' });
  }
});

module.exports = router;
