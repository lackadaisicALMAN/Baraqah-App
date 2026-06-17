'use strict';

const express = require('express');
const router = express.Router();
const controller = require('./restaurants.controller');
const { authMiddleware } = require('../../middleware/auth.middleware');

// Public routes (no auth required to browse restaurants list)
router.get('/', controller.list);
router.get('/:id', controller.getById);

module.exports = router;
