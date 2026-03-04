const bcrypt = require('bcryptjs');
const User = require('./models/User');

const SALT_ROUNDS = Number(process.env.SALT_ROUNDS) || 10;
const PEPPER = process.env.PEPPER || '';

const ADMINS = [
  {
    username: 'Nurislam',
    email: process.env.ADMIN_NURISLAM_EMAIL || 'nurislam@rentmus.app',
    password: process.env.ADMIN_NURISLAM_PASS || 'Admin@Nurislam1',
  },
  {
    username: 'Olzhas',
    email: process.env.ADMIN_OLZHAS_EMAIL || 'olzhas@rentmus.app',
    password: process.env.ADMIN_OLZHAS_PASS || 'Admin@Olzhas1',
  },
];

async function seedAdmins() {
  for (const admin of ADMINS) {
    const existing = await User.findOne({ username: admin.username });
    if (existing) {
      // Always enforce admin role, verified email, and seed password
      existing.role = 'admin';
      existing.emailVerified = true;
      existing.passwordHash = await bcrypt.hash(admin.password + PEPPER, SALT_ROUNDS);
      await existing.save();
      console.log(`🔧 ${admin.username}: role=admin, пароль жаңартылды`);
      continue;
    }

    const passwordHash = await bcrypt.hash(admin.password + PEPPER, SALT_ROUNDS);
    await User.create({
      username: admin.username,
      email: admin.email,
      passwordHash,
      role: 'admin',
      emailVerified: true,
    });
    console.log(`🚀 Admin "${admin.username}" жасалды (${admin.email})`);
  }
}

module.exports = { seedAdmins };
