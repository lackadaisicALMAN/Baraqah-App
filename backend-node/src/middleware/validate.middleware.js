'use strict';

const { error: errorResponse } = require('../utils/response.utils');

/**
 * Joi schema validation middleware factory.
 * @param {import('joi').Schema} schema
 * @param {'body'|'query'|'params'} source
 */
function validate(schema, source = 'body') {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((d) => ({
        field: d.path.join('.'),
        message: d.message,
      }));
      return errorResponse(res, 'Validation failed', 422, errors);
    }

    req[source] = value;
    next();
  };
}

module.exports = { validate };
