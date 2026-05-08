const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
      maxlength: 200,
    },
    phone: {
      type: String,
      required: [true, 'Phone is required'],
      match: [/^\d{10}$/, 'Enter valid 10-digit phone'],
    },
    address: {
      type: String,
      trim: true,
      maxlength: 300,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Customer', customerSchema);