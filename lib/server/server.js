require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const { connect } = require('./db');
const authRoutes = require('./routes/auth');
const favoritesRoutes = require('./routes/favorites');
const listingsRoutes = require('./routes/listings');
const userRoutes = require('./routes/user');

const app = express();
app.use(express.json());
app.use(cors());

// Обслуживание статических файлов (загруженных изображений)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

connect();

app.use('/api/auth', authRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/listings', listingsRoutes);
app.use('/api/user', userRoutes);

app.get('/', (req, res) => res.send('Server is up'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server started on ${PORT}`));