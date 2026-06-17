'use strict';

const mongoose = require('mongoose');
const logger = require('../utils/logger');

const MONGO_URI =
  process.env.MONGO_URI ||
  'mongodb://baraqah:baraqah_mongo_secret@localhost:27017/baraqah?authSource=admin';

let isConnected = false;

async function connectMongo() {
  if (isConnected) return mongoose.connection;

  mongoose.set('strictQuery', true);

  await mongoose.connect(MONGO_URI, {
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 10000,
  });

  isConnected = true;
  logger.info('MongoDB connected');

  mongoose.connection.on('error', (err) => {
    logger.error('MongoDB connection error', { error: err.message });
  });

  mongoose.connection.on('disconnected', () => {
    isConnected = false;
    logger.warn('MongoDB disconnected');
  });

  return mongoose.connection;
}

async function disconnectMongo() {
  if (!isConnected) return;
  await mongoose.disconnect();
  isConnected = false;
  logger.info('MongoDB disconnected');
}

module.exports = { connectMongo, disconnectMongo, mongoose };
