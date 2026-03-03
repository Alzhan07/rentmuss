const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  username: {
    type: String,
    required: true
  },

  userAvatar: {
    type: String,
    default: ''
  },

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

  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },

  comment: {
    type: String,
    trim: true,
    maxlength: 1000
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

// One review per user per item
reviewSchema.index({ userId: 1, itemId: 1, itemType: 1 }, { unique: true });
reviewSchema.index({ itemId: 1, itemType: 1, createdAt: -1 });

// After save — recalculate rating on the item
async function recalcRating(doc) {
  const reviews = await mongoose.model('Review').find({
    itemId: doc.itemId,
    itemType: doc.itemType
  });

  if (reviews.length === 0) return;

  const avg = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
  const rounded = Math.round(avg * 10) / 10;

  let ItemModel;
  switch (doc.itemType) {
    case 'instrument': ItemModel = mongoose.model('Instrument'); break;
    case 'stage':      ItemModel = mongoose.model('Stage');      break;
    case 'studio':     ItemModel = mongoose.model('Studio');     break;
  }

  if (ItemModel) {
    await ItemModel.findByIdAndUpdate(doc.itemId, {
      rating: rounded,
      reviewsCount: reviews.length
    });
  }
}

reviewSchema.post('save', recalcRating);
reviewSchema.post('findOneAndDelete', recalcRating);

module.exports = mongoose.model('Review', reviewSchema);
