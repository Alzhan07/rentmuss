const mongoose = require('mongoose');

const studioSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },

  type: {
    type: String,
    required: true,
    enum: ['recording', 'rehearsal', 'podcast', 'live_streaming', 'mixing']
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

  address: {
    type: String,
    required: true
  },

  areaSquareMeters: {
    type: Number,
    required: true,
    min: 0
  },

  hasEngineer: {
    type: Boolean,
    default: false
  },

  hasInstruments: {
    type: Boolean,
    default: false
  },

  hasSoundproofing: {
    type: Boolean,
    default: true
  },

  hasAirConditioning: {
    type: Boolean,
    default: false
  },

  equipment: {
    type: String,
    default: ''
  },

  amenities: [{
    type: String
  }],

  isAvailable: {
    type: Boolean,
    default: true
  },


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

studioSchema.index({ ownerId: 1, createdAt: -1 });
studioSchema.index({ type: 1, isAvailable: 1 });
studioSchema.index({ name: 'text', description: 'text' });

studioSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Studio', studioSchema);
