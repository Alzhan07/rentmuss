// lib/server/scripts/createAdmin.js
// Скрипт для создания нового администратора

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const readline = require('readline');
const User = require('../models/User');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/rentmuss';
const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
const PEPPER = process.env.PEPPER || '';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function createAdmin() {
  try {
    console.log('🔌 Подключение к MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Подключено к MongoDB\n');

    const username = await question('Введите имя администратора: ');
    const email = await question('Введите email администратора (или оставьте пустым): ');
    const password = await question('Введите пароль: ');

    if (!username || !password) {
      console.error('❌ Имя и пароль обязательны!');
      process.exit(1);
    }

    const passwordHash = await bcrypt.hash(password + PEPPER, SALT_ROUNDS);

    const admin = new User({
      username: username.trim(),
      ...(email ? { email: email.trim().toLowerCase() } : {}),
      passwordHash,
      role: 'admin'
    });

    await admin.save();
    console.log('\n✅ Администратор успешно создан:');
    console.log(`   ID: ${admin._id}`);
    console.log(`   Имя: ${admin.username}`);
    console.log(`   Email: ${admin.email || 'не указан'}`);
    console.log(`   Роль: ${admin.role}`);

    rl.close();
    process.exit(0);
  } catch (err) {
    console.error('❌ Ошибка:', err);
    if (err.code === 11000) {
      console.error('Пользователь с такими данными уже существует!');
    }
    rl.close();
    process.exit(1);
  }
}

createAdmin();
