'use strict';

const socialService = require('./social.service');
const { success, created } = require('../../utils/response.utils');

async function sendRequest(req, res, next) {
  try {
    const friendship = await socialService.sendFriendRequest(
      req.user.id,
      req.body.addressee_id
    );
    return created(res, friendship, 'Friend request sent');
  } catch (err) {
    next(err);
  }
}

async function acceptRequest(req, res, next) {
  try {
    const friendship = await socialService.acceptFriendRequest(
      req.user.id,
      req.params.friendshipId
    );
    return success(res, friendship, 'Friend request accepted');
  } catch (err) {
    next(err);
  }
}

async function getFriends(req, res, next) {
  try {
    const friends = await socialService.getFriends(req.user.id);
    return success(res, friends);
  } catch (err) {
    next(err);
  }
}

async function getPending(req, res, next) {
  try {
    const pending = await socialService.getPendingRequests(req.user.id);
    return success(res, pending);
  } catch (err) {
    next(err);
  }
}

async function leaderboard(req, res, next) {
  try {
    const board = await socialService.getLeaderboard(
      req.query.city,
      parseInt(req.query.limit || '50', 10)
    );
    return success(res, board);
  } catch (err) {
    next(err);
  }
}

async function syncContacts(req, res, next) {
  try {
    const result = await socialService.syncContactsAndSuggest(
      req.user.id,
      req.body.contacts
    );
    return success(res, result, 'Contacts synced');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  sendRequest,
  acceptRequest,
  getFriends,
  getPending,
  leaderboard,
  syncContacts,
};
