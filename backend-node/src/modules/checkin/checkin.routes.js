'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./checkin.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const Joi = require('joi');

const scanSchema = Joi.object({
  qr_token: Joi.string().uuid().optional(),
  session_id: Joi.string().uuid().optional(),
  payload: Joi.string().optional(),
  lat: Joi.number().min(-90).max(90).optional(),
  lng: Joi.number().min(-180).max(180).optional(),
  device_info: Joi.object().optional(),
}).or('payload', 'qr_token');

router.use(authMiddleware);

router.post('/sessions/:sessionId/open', controller.openCheckin);
router.post('/scan', validate(scanSchema), controller.scan);
router.post('/sessions/:sessionId/complete', controller.complete);
router.get('/sessions/:sessionId/attendance', controller.getAttendance);

module.exports = router;
