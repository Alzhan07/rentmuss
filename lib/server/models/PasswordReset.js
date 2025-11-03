const mongoose = require('mongoose');

const passwordResetSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },

  code: {
    type: String,
    required: true
  },

  expiresAt: {
    type: Date,
    required: true,
  
    default: () => new Date(Date.now() + 15 * 60 * 1000)
  },

  used: {
    type: Boolean,
    default: false
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

passwordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });


passwordResetSchema.index({ email: 1, code: 1 });

module.exports = mongoose.model('PasswordReset', passwordResetSchema);
