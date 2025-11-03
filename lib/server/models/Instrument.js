// lib/server/models/Instrument.js
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
    enum: ['Гитары', 'Клавишные', 'Ударные', 'Духовые', 'Струнные', 'Бас']
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
    enum: ['Отличное', 'Хорошее', 'Удовлетворительное'],
    default: 'Хорошее'
  },

  isAvailable: {
    type: Boolean,
    default: true
  },

  features: [{
    type: String
  }],

  // Информация о владельце (продавце)
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

// Индексы для быстрого поиска
instrumentSchema.index({ ownerId: 1, createdAt: -1 });
instrumentSchema.index({ category: 1, isAvailable: 1 });
instrumentSchema.index({ name: 'text', description: 'text' });

// Обновляем updatedAt перед сохранением
instrumentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Instrument', instrumentSchema);
