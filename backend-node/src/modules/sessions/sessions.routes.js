'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./sessions.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authMiddleware } = require('../../middleware/auth.middleware');
const {
  createSessionSchema,
  browseSchema,
  joinRequestSchema,
  reviewJoinSchema,
  chatMessageSchema,
} = require('./sessions.validation');

router.use(authMiddleware);

router.post('/', validate(createSessionSchema), controller.create);
router.get('/browse', validate(browseSchema, 'query'), controller.browse);
router.get('/mine', controller.mySessions);
router.get('/:id', controller.getById);
router.post('/:id/join', validate(joinRequestSchema), controller.join);
router.post(
  '/:id/join-requests/:requestId',
  validate(reviewJoinSchema),
  controller.reviewJoin
);
router.post('/:id/messages', validate(chatMessageSchema), controller.sendMessage);

module.exports = router;
