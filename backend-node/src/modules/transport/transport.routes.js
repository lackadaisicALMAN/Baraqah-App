'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./transport.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const Joi = require('joi');

const transportSchema = Joi.object({
  transport_mode: Joi.string().valid('RIDE_TOGETHER', 'MEET_THERE').required(),
});

const rideConfigSchema = Joi.object({
  has_ride_available: Joi.boolean().required(),
  available_ride_seats: Joi.number().integer().min(0).required(),
  vehicle_info: Joi.object({
    make: Joi.string().optional(),
    color: Joi.string().optional(),
    plate: Joi.string().optional(),
  }).optional(),
});

router.use(authMiddleware);

router.patch(
  '/sessions/:sessionId/transport',
  validate(transportSchema),
  controller.updateTransport
);
router.put(
  '/sessions/:sessionId/ride',
  validate(rideConfigSchema),
  controller.configureRide
);

module.exports = router;
