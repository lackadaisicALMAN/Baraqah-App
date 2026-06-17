'use strict';

const mongoose = require('mongoose');

const deviceTokenSchema = new mongoose.Schema(
  {
    token: { type: String, required: true },
    platform: { type: String, enum: ['android', 'ios'], required: true },
    added_at: { type: Date, default: Date.now },
    is_active: { type: Boolean, default: true },
  },
  { _id: false }
);

const mealTimeSchema = new mongoose.Schema(
  {
    day_of_week: {
      type: String,
      enum: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
    },
    start_hour: { type: Number, min: 0, max: 23 },
    end_hour: { type: Number, min: 0, max: 23 },
  },
  { _id: false }
);

const preferenceVectorSchema = new mongoose.Schema(
  {
    cuisine_weights: { type: Map, of: Number, default: {} },
    price_range_preference: { type: Number, min: 1, max: 4, default: 2 },
    preferred_group_size: {
      min: { type: Number, default: 2 },
      max: { type: Number, default: 6 },
    },
    preferred_meal_times: [mealTimeSchema],
    transport_preference: {
      type: String,
      enum: ['RIDE_TOGETHER', 'MEET_THERE', 'NO_PREFERENCE'],
      default: 'NO_PREFERENCE',
    },
    social_comfort_level: { type: Number, min: 0, max: 1, default: 0.5 },
    dietary_restrictions: [{ type: String }],
    avg_session_rating_given: { type: Number, default: 3.0 },
  },
  { _id: false }
);

const userProfileSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, unique: true, index: true },
    preference_vector: { type: preferenceVectorSchema, default: () => ({}) },
    session_history_summary: {
      favorite_restaurants: [{ type: String }],
      favorite_cuisines: [{ type: String }],
      frequent_dining_partners: [{ type: String }],
    },
    device_tokens: [deviceTokenSchema],
    tags: { type: [String], default: [] },
    privacy_settings: {
      show_location_to: {
        type: String,
        enum: ['EVERYONE', 'FRIENDS', 'NOBODY'],
        default: 'FRIENDS',
      },
      show_score_to: {
        type: String,
        enum: ['EVERYONE', 'FRIENDS', 'NOBODY'],
        default: 'EVERYONE',
      },
      allow_contact_sync: { type: Boolean, default: true },
    },
  },
  { timestamps: true, collection: 'userprofiles' }
);

userProfileSchema.index({ 'preference_vector.cuisine_weights': 1 });
userProfileSchema.index({ 'preference_vector.dietary_restrictions': 1 });

const UserProfile = mongoose.model('UserProfile', userProfileSchema);

module.exports = UserProfile;
