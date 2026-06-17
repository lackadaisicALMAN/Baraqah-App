'use strict';

const mongoose = require('mongoose');

const mediaSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    type: { type: String, enum: ['image', 'video'], required: true },
    caption: String,
    uploaded_at: { type: Date, default: Date.now },
  },
  { _id: false }
);

const dishSchema = new mongoose.Schema(
  {
    name: String,
    rating: { type: Number, min: 1, max: 5 },
    is_recommended: Boolean,
  },
  { _id: false }
);

const moderationSchema = new mongoose.Schema(
  {
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'FLAGGED', 'REMOVED'],
      default: 'PENDING',
    },
    flagged_reason: String,
    reviewed_by: String,
    reviewed_at: Date,
  },
  { _id: false }
);

const ratingsSchema = new mongoose.Schema(
  {
    overall: { type: Number, required: true, min: 1, max: 10 },
    food_quality: { type: Number, min: 1, max: 10 },
    value: { type: Number, min: 1, max: 10 },
    service: { type: Number, min: 1, max: 10 },
    ambiance: { type: Number, min: 1, max: 10 },
    group_friendliness: { type: Number, min: 1, max: 10 },
  },
  { _id: false }
);

const reviewSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, index: true },
    restaurantId: { type: String, required: true, index: true },
    authorId: { type: String, required: true, index: true },
    isVerified: { type: Boolean, required: true, default: true },
    attendee_count: { type: Number, default: 0 },
    ratings: { type: ratingsSchema, required: true },
    review_text: { type: String, maxlength: 1500 },
    tags: [{ type: String }],
    media: [mediaSchema],
    dishes_ordered: [dishSchema],
    helpful_votes: { type: Number, default: 0, min: 0 },
    moderation: { type: moderationSchema, default: () => ({}) },
  },
  { timestamps: true, collection: 'reviews' }
);

reviewSchema.index({ restaurantId: 1, isVerified: 1, createdAt: -1 });
reviewSchema.index({ sessionId: 1, authorId: 1 }, { unique: true });
reviewSchema.index({ authorId: 1, createdAt: -1 });
reviewSchema.index({ 'moderation.status': 1, createdAt: 1 });

const Review = mongoose.model('Review', reviewSchema);

module.exports = Review;
