const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const Debt = require('../models/Debt');
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

// GET /api/debts/:customerId
router.get('/:customerId', auth, async (req, res, next) => {
  try {
    if (!(await ownsCustomer(req.params.customerId, req.user._id))) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    const debts = await Debt.find({ customerId: req.params.customerId })
      .sort({ date: -1 });
    res.json({ success: true, data: debts });
  } catch (err) {
    next(err);
  }
});

// POST /api/debts/:customerId
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
      const debt = await Debt.create({
        userId: req.user._id,
        customerId: req.params.customerId,
        amount: req.body.amount,
        description: req.body.description,
        date: new Date(req.body.date),
      });
      res.status(201).json({ success: true, data: debt });
    } catch (err) {
      next(err);
    }
  }
);

// PATCH /api/debts/:id/mark-paid
router.patch('/:id/mark-paid', auth, async (req, res, next) => {
  try {
    const debt = await Debt.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { $set: { isPaid: true, paidAt: new Date() } },
      { new: true }
    );
    if (!debt) {
      return res.status(404).json({ success: false, message: 'Debt not found' });
    }
    res.json({ success: true, data: debt });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/debts/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const debt = await Debt.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!debt) {
      return res.status(404).json({ success: false, message: 'Debt not found' });
    }
    res.json({ success: true, message: 'Debt deleted' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;