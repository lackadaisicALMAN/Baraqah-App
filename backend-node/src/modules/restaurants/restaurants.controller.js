'use strict';

const restaurantModel = require('../../models/pg/restaurant.model');
const { success } = require('../../utils/response.utils');

async function list(req, res, next) {
  try {
    const restaurants = await restaurantModel.findAll();
    return success(res, restaurants);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const restaurant = await restaurantModel.findById(req.params.id);
    if (!restaurant) {
      return res.status(404).json({ success: false, message: 'Restaurant not found' });
    }
    return success(res, restaurant);
  } catch (err) {
    next(err);
  }
}

module.exports = { list, getById };
