// lib/server/db.js
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/rentmuss';

console.log('MONGO_URI used by server:', MONGO_URI);

async function connect() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('✅ MongoDB подключен к базе данных: rentmuss');
  } catch (err) {
    console.error('❌ Ошибка подключения к MongoDB:', err);
    process.exit(1);
  }
}

async function dropDatabase() {
  try {
    await mongoose.connection.dropDatabase();
    console.log('🗑️  База данных успешно удалена');
  } catch (err) {
    console.error('❌ Ошибка при удалении базы данных:', err);
    throw err;
  }
}

module.exports = { connect, dropDatabase };
