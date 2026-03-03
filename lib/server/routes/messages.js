const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Message = require('../models/Message');

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

router.post('/', authenticateToken, async (req, res) => {
  try {
    const { receiverId, content, itemId, itemType, itemName } = req.body;

    if (!receiverId || !content || content.trim() === '') {
      return res.status(400).json({ success: false, message: 'receiverId and content are required' });
    }

    if (receiverId === req.user.userId) {
      return res.status(400).json({ success: false, message: 'Cannot send message to yourself' });
    }

    const message = await Message.create({
      sender: req.user.userId,
      receiver: receiverId,
      content: content.trim(),
      itemId: itemId || null,
      itemType: itemType || null,
      itemName: itemName || null,
    });

    const populated = await message.populate('sender', 'username avatar');

    res.status(201).json({ success: true, message: populated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.userId);

    const conversations = await Message.aggregate([
      {
        $match: {
          $or: [{ sender: userId }, { receiver: userId }],
        },
      },
      {
        $sort: { createdAt: -1 },
      },
      {
        $group: {
          _id: {
            pair: {
              $cond: [
                { $lt: ['$sender', '$receiver'] },
                { $concat: [{ $toString: '$sender' }, '_', { $toString: '$receiver' }] },
                { $concat: [{ $toString: '$receiver' }, '_', { $toString: '$sender' }] },
              ],
            },
            itemId: { $ifNull: ['$itemId', ''] },
          },
          lastMessage: { $first: '$$ROOT' },
          unread: {
            $sum: {
              $cond: [
                { $and: [{ $eq: ['$receiver', userId] }, { $eq: ['$read', false] }] },
                1,
                0,
              ],
            },
          },
        },
      },
      { $sort: { 'lastMessage.createdAt': -1 } },
    ]);

    const populated = await Message.populate(conversations.map((c) => c.lastMessage), [
      { path: 'sender', select: 'username avatar' },
      { path: 'receiver', select: 'username avatar' },
    ]);

    const result = conversations.map((c, i) => ({
      otherUser:
        populated[i].sender._id.toString() === req.user.userId
          ? populated[i].receiver
          : populated[i].sender,
      lastMessage: {
        content: populated[i].content,
        createdAt: populated[i].createdAt,
        isMine: populated[i].sender._id.toString() === req.user.userId,
      },
      itemId: c._id.itemId || null,
      itemType: populated[i].itemType,
      itemName: populated[i].itemName,
      unread: c.unread,
    }));

    res.json({ success: true, conversations: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/unread/count', authenticateToken, async (req, res) => {
  try {
    const count = await Message.countDocuments({
      receiver: req.user.userId,
      read: false,
    });
    res.json({ success: true, count });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/:userId', authenticateToken, async (req, res) => {
  try {
    const me = req.user.userId;
    const other = req.params.userId;
    const { itemId } = req.query;

    const filter = {
      $or: [
        { sender: me, receiver: other },
        { sender: other, receiver: me },
      ],
    };

    if (itemId) {
      filter.itemId = itemId;
    }

    const messages = await Message.find(filter)
      .sort({ createdAt: 1 })
      .populate('sender', 'username avatar')
      .populate('receiver', 'username avatar');

    await Message.updateMany(
      { sender: other, receiver: me, read: false, ...(itemId ? { itemId } : {}) },
      { $set: { read: true } }
    );

    res.json({ success: true, messages });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
