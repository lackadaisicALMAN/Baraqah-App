'use strict';

const Joi = require('joi');

const createSessionSchema = Joi.object({
  restaurant_id: Joi.string().uuid().required(),
  scheduled_at: Joi.date().iso().greater('now').required(),
  max_attendees: Joi.number().integer().min(2).max(12).required(),
  food_category: Joi.string().required(),
  split_type: Joi.string().valid('EQUAL', 'PERCENTAGE', 'HOST_PAYS', 'PAY_OWN').optional(),
  split_details: Joi.array().optional(),
  has_ride_available: Joi.boolean().optional(),
  available_ride_seats: Joi.number().integer().min(0).optional(),
  vehicle_info: Joi.object().optional(),
  meeting_lat: Joi.number().min(-90).max(90).optional(),
  meeting_lng: Joi.number().min(-180).max(180).optional(),
  meeting_note: Joi.string().max(500).optional(),
  description: Joi.string().max(1000).optional(),
  host_transport_mode: Joi.string().valid('RIDE_TOGETHER', 'MEET_THERE').optional(),
});

const browseSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).default(31.4840), // defaults to Lahore centre
  lng: Joi.number().min(-180).max(180).default(74.3090),
  radius_km: Joi.number().min(0.5).max(50).default(30),
  limit: Joi.number().integer().min(1).max(100).default(50),
});

const joinRequestSchema = Joi.object({
  transport_mode: Joi.string().valid('RIDE_TOGETHER', 'MEET_THERE').default('MEET_THERE'),
  message: Joi.string().max(500).optional(),
});

const reviewJoinSchema = Joi.object({
  action: Joi.string().valid('ACCEPT', 'REJECT').required(),
});

const chatMessageSchema = Joi.object({
  type: Joi.string().valid('TEXT', 'IMAGE', 'SYSTEM', 'LOCATION_SHARE').default('TEXT'),
  content: Joi.string().max(2000).required(),
  metadata: Joi.object().optional(),
});

module.exports = {
  createSessionSchema,
  browseSchema,
  joinRequestSchema,
  reviewJoinSchema,
  chatMessageSchema,
};
