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


  itemData: {
    name: { type: String, required: true },
    description: { type: String },
    images: [{ type: String }],
    pricePerHour: { type: Number },
    pricePerDay: { type: Number },
    rating: { type: Number },
    location: { type: String },

    category: { type: String }, 
    capacity: { type: Number },   
    equipment: [{ type: String }]
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});


favoriteSchema.index({ userId: 1, createdAt: -1 });


favoriteSchema.index({ userId: 1, itemType: 1, itemId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
