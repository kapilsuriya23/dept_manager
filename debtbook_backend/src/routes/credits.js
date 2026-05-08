const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const Credit = require('../models/Credit');
const Customer = require('../models/Customer');

const validate = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ success: false, errors: errors.array() });
    return false;
  }
  return true;
};

const ownsCustomer = async (customerId, userId) =>
  Customer.findOne({ _id: customerId, userId });

// GET /api/credits/:customerId
router.get('/:customerId', auth, async (req, res, next) => {
  try {
    if (!(await ownsCustomer(req.params.customerId, req.user._id))) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    const credits = await Credit.find({ customerId: req.params.customerId })
      .sort({ date: -1 });
    res.json({ success: true, data: credits });
  } catch (err) {
    next(err);
  }
});

// POST /api/credits/:customerId
router.post(
  '/:customerId',
  auth,
  [
    body('amount').isFloat({ min: 0.01 }).withMessage('Valid amount required'),
    body('description').trim().notEmpty().withMessage('Description required'),
    body('date').isISO8601().withMessage('Valid date required'),
  ],
  async (req, res, next) => {
    if (!validate(req, res)) return;
    try {
      if (!(await ownsCustomer(req.params.customerId, req.user._id))) {
        return res.status(404).json({ success: false, message: 'Customer not found' });
      }
      const credit = await Credit.create({
        userId: req.user._id,
        customerId: req.params.customerId,
        amount: req.body.amount,
        description: req.body.description,
        date: new Date(req.body.date),
      });
      res.status(201).json({ success: true, data: credit });
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /api/credits/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const credit = await Credit.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!credit) {
      return res.status(404).json({ success: false, message: 'Credit not found' });
    }
    res.json({ success: true, message: 'Credit deleted' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;