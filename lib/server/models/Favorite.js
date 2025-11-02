// lib/server/models/Favorite.js
const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  itemType: {
    type: String,
    enum: ['instrument', 'stage', 'studio'],
    required: true
  },

  itemId: {
    type: String,
    required: true
  },

  // Сохраняем основную информацию для быстрого отображения
  itemData: {
    name: { type: String, required: true },
    description: { type: String },
    images: [{ type: String }],
    pricePerHour: { type: Number },
    pricePerDay: { type: Number },
    rating: { type: Number },
    location: { type: String },
    // Дополнительные поля в зависимости от типа
    category: { type: String }, // для instruments
    capacity: { type: Number }, // для stages
    equipment: [{ type: String }] // для studios
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Составной индекс для быстрого поиска избранных пользователем
favoriteSchema.index({ userId: 1, createdAt: -1 });

// Уникальный индекс чтобы избежать дублирования
favoriteSchema.index({ userId: 1, itemType: 1, itemId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
