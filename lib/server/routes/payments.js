const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');

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

function generateTransactionId() {
  const prefix = 'TXN';
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
}

function simulatePaymentProcessing() {
  return new Promise((resolve) => {
    const processingTime = 1500 + Math.random() * 1000;
    setTimeout(() => {
      const isSuccess = Math.random() < 0.9;
      resolve(isSuccess);
    }, processingTime);
  });
}

router.post('/process', authenticateToken, async (req, res) => {
  try {
    const { bookingId, method, cardLastFour, cardHolder } = req.body;

    if (!bookingId || !method) {
      return res.status(400).json({
        success: false,
        message: 'Брондау ID және төлем әдісі қажет'
      });
    }

    if (!['card', 'kaspi', 'qr'].includes(method)) {
      return res.status(400).json({ success: false, message: 'Қате төлем әдісі' });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Брондау табылмады' });
    }

    if (booking.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Қол жетімділік жоқ' });
    }

    const existingPayment = await Payment.findOne({
      bookingId,
      status: { $in: ['processing', 'completed'] }
    });

    if (existingPayment && existingPayment.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Бұл брондау үшін төлем жасалған'
      });
    }

    if (method === 'card') {
      if (!cardLastFour || cardLastFour.length !== 4) {
        return res.status(400).json({
          success: false,
          message: 'Карта нөмірі дұрыс емес'
        });
      }
    }

    const payment = new Payment({
      bookingId,
      userId: req.user.userId,
      amount: booking.totalPrice,
      method,
      cardLastFour: method === 'card' ? cardLastFour : undefined,
      cardHolder: method === 'card' ? cardHolder : undefined,
      status: 'processing'
    });

    await payment.save();

    const isSuccess = await simulatePaymentProcessing();

    if (isSuccess) {
      payment.status = 'completed';
      payment.transactionId = generateTransactionId();
      await payment.save();

      return res.json({
        success: true,
        message: 'Төлем сәтті өтті!',
        payment: {
          id: payment._id,
          transactionId: payment.transactionId,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          method: payment.method
        }
      });
    } else {
      payment.status = 'failed';
      payment.failureReason = 'Банк төлемді қабылдаудан бас тартты';
      await payment.save();

      return res.status(402).json({
        success: false,
        message: 'Төлем қабылданбады. Картаны тексеріп, қайта көріңіз.',
        payment: {
          id: payment._id,
          status: payment.status
        }
      });
    }
  } catch (error) {
    console.error('Payment processing error:', error);
    res.status(500).json({ success: false, message: 'Төлем қатесі' });
  }
});

router.get('/history', authenticateToken, async (req, res) => {
  try {
    const payments = await Payment.find({ userId: req.user.userId })
      .sort({ createdAt: -1 });

    res.json({ success: true, payments });
  } catch (error) {
    console.error('Get payment history error:', error);
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const payment = await Payment.findOne({
      _id: req.params.id,
      userId: req.user.userId
    });

    if (!payment) {
      return res.status(404).json({ success: false, message: 'Төлем табылмады' });
    }

    res.json({ success: true, payment });
  } catch (error) {
    console.error('Get payment error:', error);
    res.status(500).json({ success: false, message: 'Қате' });
  }
});

module.exports = router;
