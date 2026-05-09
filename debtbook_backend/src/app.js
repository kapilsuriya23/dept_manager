require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/db');
const errorHandler = require('./middleware/errorHandler');

connectDB();

const app = express();

// ── Security ──────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// ── Rate limiting ─────────────────────────────────────────
app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 min
    max: 100,
    message: { success: false, message: 'Too many requests, try again later' },
  })
);

// ── Logging (dev only) ────────────────────────────────────
if (process.env.NODE_ENV === 'development') app.use(morgan('dev'));

// ── Routes ────────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/debts', require('./routes/debts'));
app.use('/api/credits', require('./routes/credits'));

// ── Health check ──────────────────────────────────────────
app.get('/health', (_, res) => res.json({ status: 'ok' }));

// ── 404 ───────────────────────────────────────────────────
app.use((_, res) => res.status(404).json({ success: false, message: 'Route not found' }));

// ── Error handler ─────────────────────────────────────────
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));