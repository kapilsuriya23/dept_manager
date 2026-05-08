const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const sign = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

const validate = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ success: false, errors: errors.array() });
    return false;
  }
  return true;
};

// POST /api/auth/register
router.post(
  '/register',
  [
    body('shopName').trim().notEmpty().withMessage('Shop name required'),
    body('phone').matches(/^\d{10}$/).withMessage('Enter valid 10-digit phone'),
    body('password').isLength({ min: 6 }).withMessage('Min 6 characters'),
  ],
  async (req, res, next) => {
    if (!validate(req, res)) return;
    try {
      const { shopName, phone, password } = req.body;
      const exists = await User.findOne({ phone });
      if (exists) {
        return res.status(400).json({ success: false, message: 'Phone already registered' });
      }
      const user = await User.create({ shopName, phone, password });
      res.status(201).json({
        success: true,
        token: sign(user._id),
        user: { id: user._id, shopName: user.shopName, phone: user.phone },
      });
    } catch (err) {
      next(err);
    }
  }
);

// POST /api/auth/login
router.post(
  '/login',
  [
    body('phone').matches(/^\d{10}$/).withMessage('Enter valid phone'),
    body('password').notEmpty().withMessage('Password required'),
  ],
  async (req, res, next) => {
    if (!validate(req, res)) return;
    try {
      const { phone, password } = req.body;
      const user = await User.findOne({ phone }).select('+password');
      if (!user || !(await user.matchPassword(password))) {
        return res.status(401).json({ success: false, message: 'Invalid credentials' });
      }
      res.json({
        success: true,
        token: sign(user._id),
        user: { id: user._id, shopName: user.shopName, phone: user.phone },
      });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/auth/me
router.get('/me', require('../middleware/auth'), (req, res) => {
  res.json({
    success: true,
    user: { id: req.user._id, shopName: req.user.shopName, phone: req.user.phone },
  });
});

module.exports = router;