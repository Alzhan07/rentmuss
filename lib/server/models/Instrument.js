const mongoose = require('mongoose');

const instrumentSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },

  category: {
    type: String,
    required: true,
    enum: ['Гитаралар', 'Пернетақталы', 'Ұрмалы', 'Үрмелі', 'Шекті', 'Бас']
  },

  brand: {
    type: String,
    required: true
  },

  model: {
    type: String,
    required: true
  },

  description: {
    type: String,
    required: true
  },

  pricePerHour: {
    type: Number,
    required: true,
    min: 0
  },

  pricePerDay: {
    type: Number,
    required: true,
    min: 0
  },

  imageUrls: [{
    type: String
  }],

  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },

  reviewsCount: {
    type: Number,
    default: 0
  },

  location: {
    type: String,
    required: true
  },

  condition: {
    type: String,
    enum: ['Керемет', 'Жақсы', 'Қанағаттанарлық'],
    default: 'Жақсы'
  },

  isAvailable: {
    type: Boolean,
    default: true
  },

  isPublished: {
    type: Boolean,
    default: true
  },

  moderation: {
    removedBy:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    removalReason:  { type: String, default: null },
    removedAt:      { type: Date, default: null },
    appeal: {
      message:    { type: String, default: null },
      status:     { type: String, enum: ['none', 'pending', 'resolved'], default: 'none' },
      submittedAt:{ type: Date, default: null },
      resolvedAt: { type: Date, default: null },
      resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
      resolution: { type: String, enum: ['none', 'restored', 'rejected'], default: 'none' },
    }
  },

  features: [{
    type: String
  }],

  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  ownerName: {
    type: String,
    required: true
  },

  createdAt: {
    type: Date,
    default: Date.now
  },

  updatedAt: {
    type: Date,
    default: Date.now
  }
});

instrumentSchema.index({ ownerId: 1, createdAt: -1 });
instrumentSchema.index({ category: 1, isAvailable: 1 });
instrumentSchema.index({ name: 'text', description: 'text' });

instrumentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Instrument', instrumentSchema);
