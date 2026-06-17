'use strict';

const sessionsService = require('./sessions.service');
const { success, created } = require('../../utils/response.utils');

async function create(req, res, next) {
  try {
    const session = await sessionsService.createSession(req.user.id, req.body);
    return created(res, session, 'Session created');
  } catch (err) {
    next(err);
  }
}

async function browse(req, res, next) {
  try {
    const sessions = await sessionsService.browseSessions(
      req.query.lat,
      req.query.lng,
      req.query.radius_km,
      req.query.limit
    );
    return success(res, sessions);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const data = await sessionsService.getSession(req.params.id, req.user.id);
    return success(res, data);
  } catch (err) {
    next(err);
  }
}

async function join(req, res, next) {
  try {
    const request = await sessionsService.submitJoinRequest(
      req.params.id,
      req.user.id,
      req.body
    );
    return created(res, request, 'Join request submitted');
  } catch (err) {
    next(err);
  }
}

async function reviewJoin(req, res, next) {
  try {
    const result = await sessionsService.reviewJoinRequest(
      req.params.id,
      req.params.requestId,
      req.user.id,
      req.body.action
    );
    return success(res, result, `Request ${req.body.action.toLowerCase()}ed`);
  } catch (err) {
    next(err);
  }
}

async function sendMessage(req, res, next) {
  try {
    const message = await sessionsService.sendChatMessage(
      req.params.id,
      req.user.id,
      req.body
    );
    return created(res, message, 'Message sent');
  } catch (err) {
    next(err);
  }
}

async function mySessions(req, res, next) {
  try {
    const sessions = await sessionsService.getUserSessions(req.user.id);
    return success(res, sessions);
  } catch (err) {
    next(err);
  }
}

module.exports = { create, browse, getById, join, reviewJoin, sendMessage, mySessions };
