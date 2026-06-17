'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./social.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const { syncContactsSchema } = require('../users/users.validation');
const Joi = require('joi');

const friendRequestSchema = Joi.object({
  addressee_id: Joi.string().uuid().required(),
});

router.use(authMiddleware);

router.post('/friends/request', validate(friendRequestSchema), controller.sendRequest);
router.post('/friends/:friendshipId/accept', controller.acceptRequest);
router.get('/friends', controller.getFriends);
router.get('/friends/pending', controller.getPending);
router.get('/leaderboard', controller.leaderboard);
router.post('/contacts/sync', validate(syncContactsSchema), controller.syncContacts);

module.exports = router;
