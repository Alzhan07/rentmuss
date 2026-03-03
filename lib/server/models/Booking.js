const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  // User who is renting
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // Item being rented
  itemId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },

  itemType: {
    type: String,
    enum: ['instrument', 'stage', 'studio'],
    required: true
  },

  // Seller/Owner of the item
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // Booking dates
  startDate: {
    type: Date,
    required: true
  },

  endDate: {
    type: Date,
    required: true
  },

  // Pricing details
  pricePerUnit: {
    type: Number,
    required: true,
    min: 0
  },

  duration: {
    type: Number,
    required: true,
    min: 1
  },

  durationType: {
    type: String,
    enum: ['hour', 'day'],
    required: true
  },

  totalPrice: {
    type: Number,
    required: true,
    min: 0
  },

  // Status tracking
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'completed', 'cancelled'],
    default: 'pending'
  },

  // Optional notes from renter
  notes: {
    type: String,
    trim: true,
    maxlength: 500
  },

  // Rejection reason from seller
  rejectionReason: {
    type: String,
    trim: true,
    maxlength: 500
  },

  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },

  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes for efficient queries
bookingSchema.index({ userId: 1, createdAt: -1 });
bookingSchema.index({ sellerId: 1, createdAt: -1 });
bookingSchema.index({ itemId: 1, itemType: 1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ startDate: 1, endDate: 1 });

// Compound index for availability checking
bookingSchema.index({ itemId: 1, itemType: 1, startDate: 1, endDate: 1, status: 1 });

// Update timestamp on save
bookingSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Virtual for checking if booking is active
bookingSchema.virtual('isActive').get(function() {
  return this.status === 'confirmed' && this.endDate > new Date();
});

// Virtual for checking if booking is past
bookingSchema.virtual('isPast').get(function() {
  return this.endDate < new Date();
});

module.exports = mongoose.model('Booking', bookingSchema);
