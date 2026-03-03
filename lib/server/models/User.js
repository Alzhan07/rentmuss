const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    trim: true
  },

  email: {
    type: String,
    lowercase: true,
    trim: true,
    default: null,
  },

  passwordHash: {
    type: String,
    required: true
  },

  role: {
    type: String,
    enum: ['user', 'seller', 'admin', 'moderator'],
    default: 'user'
  },

  emailVerified: {
    type: Boolean,
    default: false
  },

  avatar: {
    type: String,
    default: null
  },

  sellerInfo: {
    shopName: { type: String, default: null },
    shopDescription: { type: String, default: null },
    shopLogo: { type: String, default: null },
    verified: { type: Boolean, default: false },
    rating: { type: Number, default: 0 },
    totalSales: { type: Number, default: 0 }
  },


  sellerApplication: {
    status: {
      type: String,
      enum: ['none', 'pending', 'approved', 'rejected'],
      default: 'none'
    },
    appliedAt: { type: Date, default: null },
    reviewedAt: { type: Date, default: null },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    rejectionReason: { type: String, default: null }
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


userSchema.index({ email: 1 }, { unique: true, sparse: true });


userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('User', userSchema);
