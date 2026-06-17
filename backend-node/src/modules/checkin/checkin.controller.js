'use strict';

const checkinService = require('./checkin.service');
const { success, created } = require('../../utils/response.utils');

async function openCheckin(req, res, next) {
  try {
    const result = await checkinService.openCheckin(req.params.sessionId, req.user.id);
    return success(res, result, 'Check-in opened');
  } catch (err) {
    next(err);
  }
}

async function scan(req, res, next) {
  try {
    const log = await checkinService.scanCheckin(
      req.user.id,
      req.body.payload || req.body,
      req.body.lat,
      req.body.lng,
      req.body.device_info
    );
    return created(res, log, 'Check-in successful');
  } catch (err) {
    next(err);
  }
}

async function complete(req, res, next) {
  try {
    const result = await checkinService.completeSession(req.params.sessionId, req.user.id);
    return success(res, result, 'Session completed');
  } catch (err) {
    next(err);
  }
}

async function getAttendance(req, res, next) {
  try {
    const attendance = await checkinService.getAttendance(req.params.sessionId, req.user.id);
    return success(res, attendance);
  } catch (err) {
    next(err);
  }
}

module.exports = { openCheckin, scan, complete, getAttendance };
