const mongoose = require('mongoose');

const stageSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },

  type: {
    type: String,
    required: true,
    enum: ['concert', 'theater', 'club', 'outdoor', 'small', 'medium', 'large']
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

  capacity: {
    type: Number,
    required: true,
    min: 0
  },

  areaSquareMeters: {
    type: Number,
    required: true,
    min: 0
  },

  hasSound: {
    type: Boolean,
    default: false
  },

  hasLighting: {
    type: Boolean,
    default: false
  },

  hasBackstage: {
    type: Boolean,
    default: false
  },

  hasParking: {
    type: Boolean,
    default: false
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

stageSchema.index({ ownerId: 1, createdAt: -1 });
stageSchema.index({ type: 1, isAvailable: 1 });
stageSchema.index({ capacity: 1 });
stageSchema.index({ name: 'text', description: 'text' });

stageSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Stage', stageSchema);
