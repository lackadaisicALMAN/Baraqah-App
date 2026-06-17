'use strict';

const Joi = require('joi');

const updateProfileSchema = Joi.object({
  full_name: Joi.string().min(2).max(150).optional(),
  display_name: Joi.string().max(80).optional(),
  avatar_url: Joi.string().uri().optional(),
  bio: Joi.string().max(500).optional(),
  email: Joi.string().email().optional(),
  lat: Joi.number().min(-90).max(90).optional(),
  lng: Joi.number().min(-180).max(180).optional(),
});

const updatePreferencesSchema = Joi.object({
  cuisine_weights: Joi.object().pattern(Joi.string(), Joi.number().min(0).max(1)).optional(),
  price_range_preference: Joi.number().min(1).max(4).optional(),
  transport_preference: Joi.string()
    .valid('RIDE_TOGETHER', 'MEET_THERE', 'NO_PREFERENCE')
    .optional(),
  dietary_restrictions: Joi.array().items(Joi.string()).optional(),
  social_comfort_level: Joi.number().min(0).max(1).optional(),
});

const syncContactsSchema = Joi.object({
  contacts: Joi.array()
    .items(
      Joi.object({
        contact_name: Joi.string().max(150).optional(),
        phone_number: Joi.string().pattern(/^\+?[0-9]{10,15}$/).required(),
      })
    )
    .min(1)
    .max(500)
    .required(),
});

const locationSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  accuracy: Joi.number().optional(),
});

module.exports = {
  updateProfileSchema,
  updatePreferencesSchema,
  syncContactsSchema,
  locationSchema,
};
