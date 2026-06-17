'use strict';

const usersService = require('./users.service');
const { success } = require('../../utils/response.utils');

async function getMe(req, res, next) {
  try {
    const profile = await usersService.getProfile(req.user.id);
    return success(res, profile);
  } catch (err) {
    next(err);
  }
}

async function updateMe(req, res, next) {
  try {
    const user = await usersService.updateProfile(req.user.id, req.body);
    return success(res, user, 'Profile updated');
  } catch (err) {
    next(err);
  }
}

async function updatePreferences(req, res, next) {
  try {
    const profile = await usersService.updatePreferences(req.user.id, req.body);
    return success(res, profile, 'Preferences updated');
  } catch (err) {
    next(err);
  }
}

async function syncContacts(req, res, next) {
  try {
    const results = await usersService.syncContacts(req.user.id, req.body.contacts);
    return success(res, results, 'Contacts synced');
  } catch (err) {
    next(err);
  }
}

async function updateLocation(req, res, next) {
  try {
    const loc = await usersService.updateLocation(
      req.user.id,
      req.body.lat,
      req.body.lng,
      req.body.accuracy
    );
    return success(res, loc, 'Location updated');
  } catch (err) {
    next(err);
  }
}

async function getScore(req, res, next) {
  try {
    const score = await usersService.getScore(req.params.userId || req.user.id);
    return success(res, score);
  } catch (err) {
    next(err);
  }
}

module.exports = { getMe, updateMe, updatePreferences, syncContacts, updateLocation, getScore };
