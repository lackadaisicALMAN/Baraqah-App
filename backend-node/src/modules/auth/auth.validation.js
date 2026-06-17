'use strict';

const Joi = require('joi');

const registerSchema = Joi.object({
  phone_number: Joi.string().pattern(/^\+?[0-9]{10,15}$/).required(),
  email: Joi.string().email().optional(),
  password: Joi.string().min(8).max(128).required(),
  full_name: Joi.string().min(2).max(150).required(),
  display_name: Joi.string().max(80).optional(),
});

const loginSchema = Joi.object({
  phone_number: Joi.string().pattern(/^\+?[0-9]{10,15}$/).required(),
  password: Joi.string().required(),
  device_info: Joi.object().optional(),
});

const refreshSchema = Joi.object({
  refresh_token: Joi.string().required(),
});

const verifyOtpSchema = Joi.object({
  phone_number: Joi.string().pattern(/^\+?[0-9]{10,15}$/).required(),
  otp: Joi.string().length(6).required(),
});

const logoutSchema = Joi.object({
  refresh_token: Joi.string().optional(),
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshSchema,
  verifyOtpSchema,
  logoutSchema,
};
