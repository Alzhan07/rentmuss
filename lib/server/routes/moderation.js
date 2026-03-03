const express = require('express');
const router  = express.Router();
const jwt     = require('jsonwebtoken');
const Instrument = require('../models/Instrument');
const Stage      = require('../models/Stage');
const Studio     = require('../models/Studio');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';

function authenticateToken(req, res, next) {
  const token = (req.headers['authorization'] || '').split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Белгі берілмеген' });
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Жарамсыз токен' });
    req.user = user;
    next();
  });
}

function requireModeratorOrAdmin(req, res, next) {
  if (req.user.role !== 'admin' && req.user.role !== 'moderator') {
    return res.status(403).json({ message: 'Модератор немесе администратор құқықтары қажет' });
  }
  next();
}

function getModel(type) {
  if (type === 'instrument') return Instrument;
  if (type === 'stage')      return Stage;
  if (type === 'studio')     return Studio;
  return null;
}

router.post('/remove/:type/:id', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const Model = getModel(req.params.type);
    if (!Model) return res.status(400).json({ message: 'Қате тип' });

    const { reason } = req.body;
    if (!reason || !reason.toString().trim()) {
      return res.status(400).json({ message: 'Себеп міндетті' });
    }

    const item = await Model.findById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Жарнама табылмады' });

    item.isPublished             = false;
    item.moderation.removedBy    = req.user.userId;
    item.moderation.removalReason= reason.toString().trim();
    item.moderation.removedAt    = new Date();
    item.moderation.appeal = {
      message: null, status: 'none', submittedAt: null,
      resolvedAt: null, resolvedBy: null, resolution: 'none',
    };
    await item.save();

    res.json({ success: true, message: 'Жарнама жарияланымнан алынды' });
  } catch (err) {
    console.error('Moderation remove error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.post('/restore/:type/:id', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const Model = getModel(req.params.type);
    if (!Model) return res.status(400).json({ message: 'Қате тип' });

    const item = await Model.findById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Жарнама табылмады' });

    item.isPublished                          = true;
    item.moderation.removedBy                 = null;
    item.moderation.removalReason             = null;
    item.moderation.removedAt                 = null;
    item.moderation.appeal.status             = 'resolved';
    item.moderation.appeal.resolvedAt         = new Date();
    item.moderation.appeal.resolvedBy         = req.user.userId;
    item.moderation.appeal.resolution         = 'restored';
    await item.save();

    res.json({ success: true, message: 'Жарнама қалпына келтірілді' });
  } catch (err) {
    console.error('Moderation restore error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.get('/removed', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const filter = { isPublished: false };

    const [instruments, stages, studios] = await Promise.all([
      Instrument.find(filter).sort({ 'moderation.removedAt': -1 }).lean(),
      Stage     .find(filter).sort({ 'moderation.removedAt': -1 }).lean(),
      Studio    .find(filter).sort({ 'moderation.removedAt': -1 }).lean(),
    ]);

    const toItem = (doc, type) => ({ ...doc, _listingType: type });

    res.json({
      success: true,
      removed: [
        ...instruments.map(d => toItem(d, 'instrument')),
        ...stages     .map(d => toItem(d, 'stage')),
        ...studios    .map(d => toItem(d, 'studio')),
      ].sort((a, b) => new Date(b.moderation?.removedAt) - new Date(a.moderation?.removedAt)),
    });
  } catch (err) {
    console.error('Get removed error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.get('/appeals', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const filter = { 'moderation.appeal.status': 'pending' };

    const [instruments, stages, studios] = await Promise.all([
      Instrument.find(filter).sort({ 'moderation.appeal.submittedAt': -1 }).lean(),
      Stage     .find(filter).sort({ 'moderation.appeal.submittedAt': -1 }).lean(),
      Studio    .find(filter).sort({ 'moderation.appeal.submittedAt': -1 }).lean(),
    ]);

    const toItem = (doc, type) => ({ ...doc, _listingType: type });

    res.json({
      success: true,
      appeals: [
        ...instruments.map(d => toItem(d, 'instrument')),
        ...stages     .map(d => toItem(d, 'stage')),
        ...studios    .map(d => toItem(d, 'studio')),
      ].sort((a, b) =>
        new Date(b.moderation?.appeal?.submittedAt) - new Date(a.moderation?.appeal?.submittedAt)
      ),
    });
  } catch (err) {
    console.error('Get appeals error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.post('/appeal/:type/:id', authenticateToken, async (req, res) => {
  try {
    const Model = getModel(req.params.type);
    if (!Model) return res.status(400).json({ message: 'Қате тип' });

    const { message } = req.body;
    if (!message || !message.toString().trim()) {
      return res.status(400).json({ message: 'Апелляция мәтіні міндетті' });
    }

    const item = await Model.findById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Жарнама табылмады' });

    if (item.ownerId.toString() !== req.user.userId.toString()) {
      return res.status(403).json({ message: 'Тек иесі апелляция бере алады' });
    }

    if (item.isPublished) {
      return res.status(400).json({ message: 'Жарнама жарияланған, апелляция қажет емес' });
    }

    if (item.moderation.appeal.status === 'pending') {
      return res.status(400).json({ message: 'Апелляция қазірдің өзінде қаралуда' });
    }

    item.moderation.appeal.message     = message.toString().trim();
    item.moderation.appeal.status      = 'pending';
    item.moderation.appeal.submittedAt = new Date();
    item.moderation.appeal.resolvedAt  = null;
    item.moderation.appeal.resolvedBy  = null;
    item.moderation.appeal.resolution  = 'none';
    await item.save();

    res.json({ success: true, message: 'Апелляция жіберілді. Модератор қарайды.' });
  } catch (err) {
    console.error('Submit appeal error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.post('/resolve-appeal/:type/:id', authenticateToken, requireModeratorOrAdmin, async (req, res) => {
  try {
    const Model = getModel(req.params.type);
    if (!Model) return res.status(400).json({ message: 'Қате тип' });

    const { restore } = req.body;
    const item = await Model.findById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Жарнама табылмады' });

    if (item.moderation.appeal.status !== 'pending') {
      return res.status(400).json({ message: 'Апелляция күтуде жоқ' });
    }

    item.moderation.appeal.status     = 'resolved';
    item.moderation.appeal.resolvedAt = new Date();
    item.moderation.appeal.resolvedBy = req.user.userId;

    if (restore) {
      item.isPublished                  = true;
      item.moderation.removedBy         = null;
      item.moderation.removalReason     = null;
      item.moderation.removedAt         = null;
      item.moderation.appeal.resolution = 'restored';
    } else {
      item.moderation.appeal.resolution = 'rejected';
    }

    await item.save();
    res.json({ success: true, message: restore ? 'Апелляция қабылданды, жарнама қалпына келтірілді' : 'Апелляция қабылданбады' });
  } catch (err) {
    console.error('Resolve appeal error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

router.get('/my-removed', authenticateToken, async (req, res) => {
  try {
    const filter = { ownerId: req.user.userId, isPublished: false };
    const [instruments, stages, studios] = await Promise.all([
      Instrument.find(filter).lean(),
      Stage     .find(filter).lean(),
      Studio    .find(filter).lean(),
    ]);
    const toItem = (doc, type) => ({ ...doc, _listingType: type });
    res.json({
      success: true,
      removed: [
        ...instruments.map(d => toItem(d, 'instrument')),
        ...stages     .map(d => toItem(d, 'stage')),
        ...studios    .map(d => toItem(d, 'studio')),
      ],
    });
  } catch (err) {
    console.error('Get my removed error:', err);
    res.status(500).json({ message: 'Серверде қате пайда болды' });
  }
});

module.exports = router;
