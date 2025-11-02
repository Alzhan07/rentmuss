// lib/server/scripts/resetDatabase.js
// Скрипт для полного сброса базы данных и создания первого администратора

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('../models/User');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/rentmuss';
const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
const PEPPER = process.env.PEPPER || '';

async function resetDatabase() {
  try {
    console.log('🔌 Подключение к MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Подключено к MongoDB');

    console.log('🗑️  Удаление старой базы данных...');
    await mongoose.connection.dropDatabase();
    console.log('✅ База данных удалена');

    console.log('👤 Создание администратора по умолчанию...');
    const adminPassword = 'Admin123!'; 
    const passwordHash = await bcrypt.hash(adminPassword + PEPPER, SALT_ROUNDS);

    const admin = new User({
      username: 'Admin',
      email: 'admin@rentmuss.com',
      passwordHash,
      role: 'admin'
    });

    await admin.save();
    console.log('✅ Администратор создан:');
    console.log('   Имя пользователя: Admin');
    console.log('   Email: admin@rentmuss.com');
    console.log('   Пароль: Admin123$');
    console.log('   ⚠️  ВАЖНО: Смените пароль после первого входа!');

    console.log('\n🎉 База данных успешно сброшена и настроена!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Ошибка:', err);
    process.exit(1);
  }
}

resetDatabase();
