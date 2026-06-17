'use strict';

const authService = require('./auth.service');
const { success, created } = require('../../utils/response.utils');

async function register(req, res, next) {
  try {
    const user = await authService.register(req.body);
    const tokens = await authService.generateTokens(
      { id: user.id, phone_number: user.phone_number },
      req.body.device_info,
      req.ip
    );
    return created(res, { user, ...tokens }, 'Registration successful');
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const result = await authService.login(
      req.body.phone_number,
      req.body.password,
      req.body.device_info,
      req.ip
    );
    return success(res, result, 'Login successful');
  } catch (err) {
    next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const result = await authService.refresh(req.body.refresh_token);
    return success(res, result, 'Token refreshed');
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    await authService.logout(req.user.id, req.user.jti, req.body.refresh_token);
    return success(res, null, 'Logged out');
  } catch (err) {
    next(err);
  }
}

async function requestOtp(req, res, next) {
  try {
    const otp = await authService.generateOtp(req.body.phone_number);
    const response = { sent: true };
    if (process.env.NODE_ENV !== 'production') {
      response.otp = otp;
    }
    return success(res, response, 'OTP sent');
  } catch (err) {
    next(err);
  }
}

async function verifyOtp(req, res, next) {
  try {
    await authService.verifyOtp(req.body.phone_number, req.body.otp);
    return success(res, null, 'Phone verified');
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, refresh, logout, requestOtp, verifyOtp };
