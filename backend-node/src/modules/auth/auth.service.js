'use strict';

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const userModel = require('../../models/pg/user.model');
const UserProfile = require('../../models/mongo/UserProfile.model');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');
const logger = require('../../utils/logger');

const BCRYPT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);

function parseExpiry(expStr) {
  const match = expStr.match(/^(\d+)([smhd])$/);
  if (!match) return 900;
  const val = parseInt(match[1], 10);
  const unit = match[2];
  const multipliers = { s: 1, m: 60, h: 3600, d: 86400 };
  return val * (multipliers[unit] || 60);
}

async function hashPassword(password) {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

async function verifyPassword(password, hash) {
  return bcrypt.compare(password, hash);
}

async function generateTokens(user, deviceInfo, ipAddress) {
  const jti = uuidv4();
  const accessExpires = process.env.JWT_ACCESS_EXPIRES || '15m';
  const refreshExpires = process.env.JWT_REFRESH_EXPIRES || '7d';

  const accessToken = jwt.sign(
    { sub: user.id, phone: user.phone_number, jti },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: accessExpires }
  );

  const refreshToken = crypto.randomBytes(48).toString('hex');
  const refreshExpiryMs = parseExpiry(refreshExpires.replace(/(\d+)([a-z])/, '$1$2')) * 1000;
  const expiresAt = new Date(Date.now() + refreshExpiryMs);

  await userModel.storeRefreshToken({
    userId: user.id,
    rawToken: refreshToken,
    deviceInfo,
    ipAddress,
    expiresAt,
  });

  const redis = getRedis();
  await redis.set(
    RedisKeys.accessToken(user.id, jti),
    'valid',
    'EX',
    parseExpiry(accessExpires.replace(/(\d+)([a-z])/, '$1$2'))
  );

  return { accessToken, refreshToken, jti };
}

async function revokeAccessToken(userId, jti) {
  const redis = getRedis();
  await redis.del(RedisKeys.accessToken(userId, jti));
}

async function register(data) {
  const existing = await userModel.findByPhone(data.phone_number);
  if (existing) {
    const err = new Error('Phone number already registered');
    err.statusCode = 409;
    throw err;
  }

  const passwordHash = await hashPassword(data.password);
  const user = await userModel.create({
    phoneNumber: data.phone_number,
    email: data.email,
    passwordHash,
    fullName: data.full_name,
    displayName: data.display_name,
  });

  await UserProfile.create({
    userId: user.id,
    preference_vector: {
      cuisine_weights: {},
      price_range_preference: 2,
      transport_preference: 'NO_PREFERENCE',
    },
  });

  return user;
}

async function login(phoneNumber, password, deviceInfo, ipAddress) {
  const user = await userModel.findByPhone(phoneNumber);
  if (!user || !user.is_active) {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }

  const valid = await verifyPassword(password, user.password_hash);
  if (!valid) {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }

  const tokens = await generateTokens(user, deviceInfo, ipAddress);
  const profile = await userModel.findById(user.id);

  return { user: profile, ...tokens };
}

async function refresh(refreshToken) {
  const stored = await userModel.findRefreshToken(refreshToken);
  if (!stored) {
    const err = new Error('Invalid refresh token');
    err.statusCode = 401;
    throw err;
  }

  await userModel.revokeRefreshToken(refreshToken);

  const user = await userModel.findById(stored.user_id);
  const tokens = await generateTokens(
    { id: user.id, phone_number: user.phone_number },
    stored.device_info,
    stored.ip_address
  );

  return { user, ...tokens };
}

async function logout(userId, jti, refreshToken) {
  if (jti) await revokeAccessToken(userId, jti);
  if (refreshToken) await userModel.revokeRefreshToken(refreshToken);
}

async function generateOtp(phoneNumber) {
  const redis = getRedis();
  const attemptsKey = RedisKeys.otpAttempts(phoneNumber);
  const attempts = parseInt((await redis.get(attemptsKey)) || '0', 10);

  if (attempts >= 5) {
    const err = new Error('Too many OTP attempts. Try again later.');
    err.statusCode = 429;
    throw err;
  }

  const otp = String(Math.floor(100000 + Math.random() * 900000));
  await redis.set(RedisKeys.otp(phoneNumber), otp, 'EX', RedisTTL.OTP);
  logger.info('OTP generated', { phoneNumber: phoneNumber.slice(-4) });
  return otp;
}

async function verifyOtp(phoneNumber, otp) {
  const redis = getRedis();
  const stored = await redis.get(RedisKeys.otp(phoneNumber));

  if (!stored || stored !== otp) {
    const attemptsKey = RedisKeys.otpAttempts(phoneNumber);
    await redis.incr(attemptsKey);
    await redis.expire(attemptsKey, RedisTTL.OTP_ATTEMPTS);

    const err = new Error('Invalid OTP');
    err.statusCode = 401;
    throw err;
  }

  await redis.del(RedisKeys.otp(phoneNumber));

  const user = await userModel.findByPhone(phoneNumber);
  if (!user) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  await userModel.updateProfile(user.id, { is_phone_verified: true });

  return true;
}

module.exports = {
  register,
  login,
  refresh,
  logout,
  generateOtp,
  verifyOtp,
  generateTokens,
};
