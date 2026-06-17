'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./auth.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const { authRateLimiter } = require('../../middleware/rateLimiter.middleware');
const {
  registerSchema,
  loginSchema,
  refreshSchema,
  verifyOtpSchema,
  logoutSchema,
} = require('./auth.validation');
const Joi = require('joi');

router.post('/register', authRateLimiter, validate(registerSchema), controller.register);
router.post('/login', authRateLimiter, validate(loginSchema), controller.login);
router.post('/refresh', authRateLimiter, validate(refreshSchema), controller.refresh);
router.post('/logout', authMiddleware, validate(logoutSchema), controller.logout);
router.post(
  '/otp/request',
  authRateLimiter,
  validate(Joi.object({ phone_number: registerSchema.extract('phone_number') })),
  controller.requestOtp
);
router.post('/otp/verify', authRateLimiter, validate(verifyOtpSchema), controller.verifyOtp);

module.exports = router;
