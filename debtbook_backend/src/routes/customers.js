const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const Customer = require('../models/Customer');
const Debt = require('../models/Debt');
const Credit = require('../models/Credit');

const validate = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ success: false, errors: errors.array() });
    return false;
  }
  return true;
};

// GET /api/customers — list all with net balance
router.get('/', auth, async (req, res, next) => {
  try {
    const customers = await Customer.find({ userId: req.user._id }).sort({ createdAt: -1 });

    const result = await Promise.all(
      customers.map(async (c) => {
        const totalDebt = await Debt.aggregate([
          { $match: { customerId: c._id, isPaid: false } },
          { $group: { _id: null, total: { $sum: '$amount' } } },
        ]);
        const totalCredit = await Credit.aggregate([
          { $match: { customerId: c._id } },
          { $group: { _id: null, total: { $sum: '$amount' } } },
        ]);
        const debt = totalDebt[0]?.total || 0;
        const credit = totalCredit[0]?.total || 0;
        return {
          ...c.toObject(),
          totalDebt: debt,
          totalCredit: credit,
          netBalance: Math.max(0, debt - credit),
        };
      })
    );

    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

// POST /api/customers
router.post(
  '/',
  auth,
  [
    body('name').trim().notEmpty().withMessage('Name required').isLength({ max: 200 }),
    body('phone').matches(/^\d{10}$/).withMessage('Valid 10-digit phone required'),
    body('address').optional().isLength({ max: 300 }),
  ],
  async (req, res, next) => {
    if (!validate(req, res)) return;
    try {
      const { name, phone, address } = req.body;
      const customer = await Customer.create({
        userId: req.user._id,
        name,
        phone,
        address: address || null,
      });
      res.status(201).json({ success: true, data: customer });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/customers/:id
router.get('/:id', auth, async (req, res, next) => {
  try {
    const customer = await Customer.findOne({ _id: req.params.id, userId: req.user._id });
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    res.json({ success: true, data: customer });
  } catch (err) {
    next(err);
  }
});

// PUT /api/customers/:id
router.put(
  '/:id',
  auth,
  [
    body('name').optional().trim().notEmpty().isLength({ max: 200 }),
    body('phone').optional().matches(/^\d{10}$/),
    body('address').optional().isLength({ max: 300 }),
  ],
  async (req, res, next) => {
    if (!validate(req, res)) return;
    try {
      const customer = await Customer.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id },
        { $set: req.body },
        { new: true, runValidators: true }
      );
      if (!customer) {
        return res.status(404).json({ success: false, message: 'Customer not found' });
      }
      res.json({ success: true, data: customer });
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /api/customers/:id — cascades debts + credits
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const customer = await Customer.findOne({ _id: req.params.id, userId: req.user._id });
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    await Debt.deleteMany({ customerId: customer._id });
    await Credit.deleteMany({ customerId: customer._id });
    await customer.deleteOne();
    res.json({ success: true, message: 'Customer and all records deleted' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;