'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./reviews.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const Joi = require('joi');

const reviewSchema = Joi.object({
  session_id: Joi.string().uuid().required(),
  restaurant_id: Joi.string().uuid().optional(),
  ratings: Joi.object({
    overall: Joi.number().min(1).max(10).required(),
    food_quality: Joi.number().min(1).max(10).optional(),
    value: Joi.number().min(1).max(10).optional(),
    service: Joi.number().min(1).max(10).optional(),
    ambiance: Joi.number().min(1).max(10).optional(),
    group_friendliness: Joi.number().min(1).max(10).optional(),
  }).required(),
  review_text: Joi.string().max(1500).optional(),
  tags: Joi.array().items(Joi.string()).max(8).optional(),
  media: Joi.array().optional(),
  dishes_ordered: Joi.array().optional(),
});

const userReviewValidationSchema = Joi.object({
  session_id: Joi.string().uuid().required(),
  target_user_id: Joi.string().uuid().required(),
  rating: Joi.number().min(1).max(7).required(), // Out of 7 stars
  review_text: Joi.string().max(1000).optional(),
});

router.use(authMiddleware);

router.post('/', validate(reviewSchema), controller.submit);
router.post('/user', validate(userReviewValidationSchema), controller.submitUser);
router.get('/recent', controller.getRecent);
router.get('/restaurant/:restaurantId', controller.getByRestaurant);
router.get('/mine', controller.getMine);

module.exports = router;
