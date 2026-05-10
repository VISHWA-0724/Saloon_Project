function notFound(req, res, next) {
  const error = new Error(`Not Found: ${req.originalUrl}`);
  res.status(404);
  next(error);
}

function errorHandler(err, req, res, _next) {
  let statusCode = res.statusCode && res.statusCode !== 200 ? res.statusCode : 500;
  let message = err.message || 'Server error';
  let errors = undefined;

  if (err?.name === 'ValidationError') {
    statusCode = 400;
    errors = Object.values(err.errors || {}).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    message = 'Validation failed';
  }

  if (err?.code === 11000) {
    statusCode = 409;
    message = 'Email already registered';
  }

  res.status(statusCode);
  res.json({
    success: false,
    message,
    errors,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
}

module.exports = { notFound, errorHandler };

