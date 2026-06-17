'use strict';

const reviewsService = require('./reviews.service');
const { success, created, paginated } = require('../../utils/response.utils');

async function submit(req, res, next) {
  try {
    const review = await reviewsService.submitReview(req.user.id, req.body);
    return created(res, review, 'Review submitted');
  } catch (err) {
    next(err);
  }
}

async function getByRestaurant(req, res, next) {
  try {
    const page = parseInt(req.query.page || '1', 10);
    const limit = parseInt(req.query.limit || '20', 10);
    const result = await reviewsService.getRestaurantReviews(
      req.params.restaurantId,
      page,
      limit
    );
    return paginated(res, result.reviews, {
      page: result.page,
      limit: result.limit,
      total: result.total,
    });
  } catch (err) {
    next(err);
  }
}

async function getMine(req, res, next) {
  try {
    const reviews = await reviewsService.getUserReviews(req.user.id);
    return success(res, reviews);
  } catch (err) {
    next(err);
  }
}

async function getRecent(req, res, next) {
  try {
    const page = parseInt(req.query.page || '1', 10);
    const limit = parseInt(req.query.limit || '20', 10);
    const result = await reviewsService.getRecentReviews(page, limit);
    return paginated(res, result.reviews, {
      page: result.page,
      limit: result.limit,
      total: result.total,
    });
  } catch (err) {
    next(err);
  }
}

async function submitUser(req, res, next) {
  try {
    const review = await reviewsService.submitUserReview(req.user.id, req.body);
    return created(res, review, 'User review submitted');
  } catch (err) {
    next(err);
  }
}

module.exports = { submit, getByRestaurant, getMine, getRecent, submitUser };
