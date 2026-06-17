'use strict';

const Review = require('../../models/mongo/Review.model');
const sessionModel = require('../../models/pg/session.model');
const attendanceModel = require('../../models/pg/attendance.model');
const restaurantModel = require('../../models/pg/restaurant.model');
const userModel = require('../../models/pg/user.model');
const checkinService = require('../checkin/checkin.service');

async function submitReview(userId, data) {
  const session = await sessionModel.findById(data.session_id);
  if (!session) {
    const err = new Error('Session not found');
    err.statusCode = 404;
    throw err;
  }

  if (session.status !== 'COMPLETED' && session.status !== 'ACTIVE') {
    const err = new Error('Reviews only available after check-in');
    err.statusCode = 400;
    throw err;
  }

  const attendance = await attendanceModel.findBySessionAndUser(data.session_id, userId);
  if (!attendance || attendance.status !== 'CONFIRMED') {
    const err = new Error('Verified check-in required to submit review');
    err.statusCode = 403;
    throw err;
  }

  const existing = await Review.findOne({
    sessionId: data.session_id,
    authorId: userId,
  });
  if (existing) {
    const err = new Error('Review already submitted for this session');
    err.statusCode = 409;
    throw err;
  }

  const attendeeCount = await attendanceModel.countConfirmed(data.session_id);

  const review = await Review.create({
    sessionId: data.session_id,
    restaurantId: data.restaurant_id || session.restaurant_id,
    authorId: userId,
    isVerified: true,
    attendee_count: attendeeCount,
    ratings: data.ratings,
    review_text: data.review_text,
    tags: data.tags || [],
    media: data.media || [],
    dishes_ordered: data.dishes_ordered || [],
    moderation: { status: 'PENDING' },
  });

  if (data.ratings.overall >= 8) {
    await checkinService.applyScoreEvent(
      userId,
      'REVIEW_RECEIVED',
      data.session_id,
      0.05
    );
  }

  await updateRestaurantStats(data.restaurant_id || session.restaurant_id);
  if (data.review_text) {
    await aggregateRestaurantTags(data.restaurant_id || session.restaurant_id);
  }

  return review;
}

async function updateRestaurantStats(restaurantId) {
  const reviews = await Review.find({
    restaurantId,
    isVerified: true,
    'moderation.status': { $ne: 'REMOVED' },
  }).lean();

  if (reviews.length === 0) return;

  const avgRating =
    reviews.reduce((sum, r) => sum + r.ratings.overall, 0) / reviews.length;

  await restaurantModel.updateReviewStats(
    restaurantId,
    Math.round(avgRating * 100) / 100,
    reviews.length
  );
}

async function getRestaurantReviews(restaurantId, page = 1, limit = 20) {
  const skip = (page - 1) * limit;
  const [reviews, total] = await Promise.all([
    Review.find({
      restaurantId,
      isVerified: true,
      'moderation.status': { $in: ['PENDING', 'APPROVED'] },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Review.countDocuments({
      restaurantId,
      isVerified: true,
      'moderation.status': { $in: ['PENDING', 'APPROVED'] },
    }),
  ]);

  return { reviews, total, page, limit };
}

async function getUserReviews(userId) {
  return Review.find({ authorId: userId }).sort({ createdAt: -1 }).lean();
}

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'but', 'or', 'for', 'nor', 'so', 'yet',
  'is', 'are', 'was', 'were', 'am', 'be', 'been', 'being',
  'to', 'of', 'in', 'on', 'at', 'by', 'with', 'about', 'against',
  'between', 'into', 'through', 'during', 'before', 'after', 'above',
  'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off',
  'over', 'under', 'again', 'further', 'then', 'once',
  'here', 'there', 'when', 'where', 'why', 'how',
  'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some',
  'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
  'too', 'very', 's', 't', 'can', 'will', 'just', 'don', 'should',
  'now', 'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves',
  'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him',
  'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its',
  'itself', 'they', 'them', 'their', 'theirs', 'themselves',
  'this', 'that', 'these', 'those'
]);

function extractUniqueWords(text) {
  if (!text) return new Set();
  const words = text.toLowerCase().match(/\b[a-z]{3,15}\b/g) || [];
  return new Set(words.filter(w => !STOP_WORDS.has(w)));
}

async function aggregateRestaurantTags(restaurantId) {
  const reviews = await Review.find({ restaurantId }).lean();
  const wordCounts = {};

  for (const review of reviews) {
    const uniqueWords = extractUniqueWords(review.review_text);
    for (const word of uniqueWords) {
      wordCounts[word] = (wordCounts[word] || 0) + 1;
    }
  }

  const frequentWords = Object.keys(wordCounts).filter(word => wordCounts[word] >= 3);
  if (frequentWords.length === 0) return;

  const restaurant = await restaurantModel.findById(restaurantId);
  if (!restaurant) return;

  let currentTags = restaurant.cuisine_tags || [];
  let updated = false;

  for (const word of frequentWords) {
    if (!currentTags.includes(word)) {
      currentTags.push(word);
      if (currentTags.length > 7) {
        currentTags.shift();
      }
      updated = true;
    }
  }

  if (updated) {
    const { query } = require('../../config/database');
    await query(
      `UPDATE restaurants SET cuisine_tags = $1, updated_at = NOW() WHERE id = $2`,
      [currentTags, restaurantId]
    );
  }
}

async function aggregateUserTags(userId) {
  const UserReview = require('../../models/mongo/UserReview.model');
  const UserProfile = require('../../models/mongo/UserProfile.model');

  const reviews = await UserReview.find({ targetUserId: userId }).lean();
  const wordCounts = {};

  for (const review of reviews) {
    const uniqueWords = extractUniqueWords(review.reviewText);
    for (const word of uniqueWords) {
      wordCounts[word] = (wordCounts[word] || 0) + 1;
    }
  }

  const frequentWords = Object.keys(wordCounts).filter(word => wordCounts[word] >= 3);
  if (frequentWords.length === 0) return;

  const profile = await UserProfile.findOne({ userId });
  if (!profile) return;

  let currentTags = profile.tags || [];
  let updated = false;

  for (const word of frequentWords) {
    if (!currentTags.includes(word)) {
      currentTags.push(word);
      if (currentTags.length > 7) {
        currentTags.shift();
      }
      updated = true;
    }
  }

  if (updated) {
    profile.tags = currentTags;
    await profile.save();
  }
}

async function updateUserBaraqahScore(userId) {
  const UserReview = require('../../models/mongo/UserReview.model');

  const reviews = await UserReview.find({ targetUserId: userId }).lean();
  const count = reviews.length;
  const sum = reviews.reduce((total, r) => total + r.rating, 0);

  // Bayesian average with prior weight 5 and prior mean 5.0
  const priorWeight = 5;
  const priorMean = 5.0;
  const newScore = (sum + priorMean * priorWeight) / (count + priorWeight);

  const finalScore = Math.min(7.0, Math.max(0.0, Math.round(newScore * 100) / 100));

  await userModel.updateScore(userId, finalScore);
  
  await userModel.recordScoreEvent(null, {
    userId,
    eventType: 'REVIEW_RECEIVED',
    sessionId: null,
    delta: finalScore - priorMean,
    scoreBefore: priorMean,
    scoreAfter: finalScore,
    metadata: { review_count: count }
  });
}

async function getRecentReviews(page = 1, limit = 20) {
  const skip = (page - 1) * limit;
  const [reviews, total] = await Promise.all([
    Review.find({
      'moderation.status': { $in: ['PENDING', 'APPROVED'] }
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Review.countDocuments({
      'moderation.status': { $in: ['PENDING', 'APPROVED'] }
    })
  ]);

  const authorIds = [...new Set(reviews.map(r => r.authorId))];
  const restaurantIds = [...new Set(reviews.map(r => r.restaurantId))];

  let authorsMap = {};
  let restaurantsMap = {};

  if (authorIds.length > 0) {
    const { query } = require('../../config/database');
    const placeholders = authorIds.map((_, i) => `$${i + 1}`).join(',');
    const usersResult = await query(
      `SELECT id, full_name, display_name, avatar_url, baraqah_score FROM users WHERE id IN (${placeholders})`,
      authorIds
    );
    usersResult.rows.forEach(user => {
      authorsMap[user.id] = user;
    });
  }

  if (restaurantIds.length > 0) {
    const { query } = require('../../config/database');
    const placeholders = restaurantIds.map((_, i) => `$${i + 1}`).join(',');
    const restaurantsResult = await query(
      `SELECT id, name, address, avg_rating FROM restaurants WHERE id IN (${placeholders})`,
      restaurantIds
    );
    restaurantsResult.rows.forEach(rest => {
      restaurantsMap[rest.id] = rest;
    });
  }

  const populatedReviews = reviews.map(r => {
    return {
      ...r,
      author: authorsMap[r.authorId] || { id: r.authorId, full_name: 'Unknown User', baraqah_score: 5.00 },
      restaurant: restaurantsMap[r.restaurantId] || { id: r.restaurantId, name: 'Unknown Restaurant' }
    };
  });

  return { reviews: populatedReviews, total, page, limit };
}

async function submitUserReview(userId, data) {
  const UserReview = require('../../models/mongo/UserReview.model');

  const session = await sessionModel.findById(data.session_id);
  if (!session) {
    const err = new Error('Session not found');
    err.statusCode = 404;
    throw err;
  }

  if (session.status !== 'COMPLETED') {
    const err = new Error('Reviews only available after session is completed');
    err.statusCode = 400;
    throw err;
  }

  const isRequesterMember = await sessionModel.isAttendee(data.session_id, userId);
  const isTargetMember = await sessionModel.isAttendee(data.session_id, data.target_user_id);
  if (!isRequesterMember || !isTargetMember) {
    const err = new Error('Both users must be session attendees');
    err.statusCode = 403;
    throw err;
  }

  const existing = await UserReview.findOne({
    sessionId: data.session_id,
    authorId: userId,
    targetUserId: data.target_user_id,
  });
  if (existing) {
    const err = new Error('Review already submitted for this user in this session');
    err.statusCode = 409;
    throw err;
  }

  const review = await UserReview.create({
    sessionId: data.session_id,
    authorId: userId,
    targetUserId: data.target_user_id,
    rating: data.rating,
    reviewText: data.review_text || '',
  });

  await updateUserBaraqahScore(data.target_user_id);
  if (data.review_text) {
    await aggregateUserTags(data.target_user_id);
  }

  return review;
}

module.exports = {
  submitReview,
  getRestaurantReviews,
  getUserReviews,
  getRecentReviews,
  submitUserReview,
  aggregateRestaurantTags,
  aggregateUserTags,
};
