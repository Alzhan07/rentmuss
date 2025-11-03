// lib/server/server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const { connect } = require('./db');
const authRoutes = require('./routes/auth');
const favoritesRoutes = require('./routes/favorites');
const listingsRoutes = require('./routes/listings');

const app = express();
app.use(express.json());
app.use(cors());

connect();

app.use('/api/auth', authRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/listings', listingsRoutes);

app.get('/', (req, res) => res.send('Server is up'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server started on ${PORT}`));