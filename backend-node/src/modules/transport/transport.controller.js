'use strict';

const transportService = require('./transport.service');
const { success } = require('../../utils/response.utils');

async function updateTransport(req, res, next) {
  try {
    const result = await transportService.updateRidePreference(
      req.params.sessionId,
      req.user.id,
      req.body.transport_mode
    );
    return success(res, result, 'Transport preference updated');
  } catch (err) {
    next(err);
  }
}

async function configureRide(req, res, next) {
  try {
    const session = await transportService.configureRide(
      req.params.sessionId,
      req.user.id,
      req.body
    );
    return success(res, session, 'Ride configuration updated');
  } catch (err) {
    next(err);
  }
}

module.exports = { updateTransport, configureRide };
