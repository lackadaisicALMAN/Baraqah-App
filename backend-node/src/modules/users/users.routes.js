'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./users.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const {
  updateProfileSchema,
  updatePreferencesSchema,
  syncContactsSchema,
  locationSchema,
} = require('./users.validation');

router.use(authMiddleware);

router.get('/me', controller.getMe);
router.patch('/me', validate(updateProfileSchema), controller.updateMe);
router.patch('/me/preferences', validate(updatePreferencesSchema), controller.updatePreferences);
router.post('/me/contacts', validate(syncContactsSchema), controller.syncContacts);
router.post('/me/location', validate(locationSchema), controller.updateLocation);
router.get('/me/score', controller.getScore);
router.get('/:userId/score', controller.getScore);

module.exports = router;
