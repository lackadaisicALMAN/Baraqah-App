'use strict';

const mongoose = require('mongoose');

const userReviewSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, index: true },
    targetUserId: { type: String, required: true, index: true },
    authorId: { type: String, required: true, index: true },
    rating: { type: Number, required: true, min: 1, max: 7 }, // out of 7 stars
    reviewText: { type: String, maxlength: 1000 },
  },
  { timestamps: true, collection: 'user_reviews' }
);

userReviewSchema.index({ sessionId: 1, targetUserId: 1, authorId: 1 }, { unique: true });
userReviewSchema.index({ targetUserId: 1, createdAt: -1 });

const UserReview = mongoose.model('UserReview', userReviewSchema);

module.exports = UserReview;
