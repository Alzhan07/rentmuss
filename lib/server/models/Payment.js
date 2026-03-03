const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true,
    index: true
  },

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  amount: {
    type: Number,
    required: true,
    min: 0
  },

  currency: {
    type: String,
    default: 'KZT'
  },

  method: {
    type: String,
    enum: ['card', 'kaspi', 'qr'],
    required: true
  },

  // Masked card info (last 4 digits only - never store full card)
  cardLastFour: {
    type: String,
    maxlength: 4
  },

  cardHolder: {
    type: String,
    trim: true
  },

  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed'],
    default: 'pending'
  },

  // Simulated transaction ID
  transactionId: {
    type: String,
    unique: true,
    sparse: true
  },

  failureReason: {
    type: String
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

paymentSchema.pre('save', function (next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Payment', paymentSchema);
