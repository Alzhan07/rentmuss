require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const { connect } = require('./db');
const { seedAdmins } = require('./seed');
const authRoutes = require('./routes/auth');
const favoritesRoutes = require('./routes/favorites');
const listingsRoutes = require('./routes/listings');
const userRoutes = require('./routes/user');
const bookingsRoutes = require('./routes/bookings');
const paymentsRoutes = require('./routes/payments');
const reviewsRoutes = require('./routes/reviews');
const messagesRoutes    = require('./routes/messages');
const moderationRoutes  = require('./routes/moderation');

const app = express();
app.use(express.json());
app.use(cors());

// Обслуживание статических файлов (загруженных изображений)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

connect().then(() => seedAdmins());

app.use('/api/auth', authRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/listings', listingsRoutes);
app.use('/api/user', userRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/reviews', reviewsRoutes);
app.use('/api/messages',    messagesRoutes);
app.use('/api/moderation', moderationRoutes);

app.get('/', (req, res) => res.send('Server is up v3'));

// Global JSON error handler (prevents Express from returning HTML on errors)
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || err.statusCode || 500).json({
    success: false,
    message: err.message || 'Ошибка сервера',
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server started on ${PORT}`));