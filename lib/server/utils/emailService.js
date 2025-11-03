const nodemailer = require('nodemailer');

const createTransporter = () => {
  if (process.env.EMAIL_HOST && process.env.EMAIL_USER && process.env.EMAIL_PASS) {
    console.log('📧 Email service configured with SMTP:', process.env.EMAIL_HOST);

    return nodemailer.createTransport({
      host: process.env.EMAIL_HOST,
      port: parseInt(process.env.EMAIL_PORT || '587'),
      secure: process.env.EMAIL_SECURE === 'true',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      tls: {
        rejectUnauthorized: false
      }
    });
  } else {
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('⚠️  EMAIL SERVICE NOT CONFIGURED - Using DEV MODE');
    console.log('═══════════════════════════════════════════════════════════════\n');
    console.log('📧 Коды восстановления пароля будут выводиться в консоль');
    console.log('');
    console.log('Чтобы отправлять письма на реальный email:');
    console.log('');
    console.log('1️⃣  Откройте: lib/server/.env');
    console.log('2️⃣  Замените:');
    console.log('   EMAIL_USER=your-email@gmail.com   ← Ваш Gmail');
    console.log('   EMAIL_PASS=your-app-password      ← Пароль приложения');
    console.log('');
    console.log('📖 Инструкции: lib/server/QUICK_EMAIL_SETUP.txt');
    console.log('═══════════════════════════════════════════════════════════════\n');
    return null;
  }
};

const transporter = createTransporter();

const sendPasswordResetCode = async (email, code, username) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'RentMus <noreply@rentmus.app>',
    to: email,
    subject: 'Восстановление пароля - RentMus',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .container {
            background: linear-gradient(135deg, #1A1A2E 0%, #16213E 100%);
            border-radius: 10px;
            padding: 30px;
            color: white;
          }
          .code-box {
            background: rgba(233, 69, 96, 0.2);
            border: 2px solid #E94560;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
          }
          .code {
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 8px;
            color: #E94560;
          }
          .footer {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.2);
            font-size: 12px;
            color: rgba(255, 255, 255, 0.6);
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1 style="color: #E94560; margin-top: 0;">Восстановление пароля</h1>
          <p>Здравствуйте, ${username || 'пользователь'}!</p>
          <p>Вы запросили восстановление пароля для вашей учетной записи RentMus.</p>
          <p>Ваш код для восстановления пароля:</p>

          <div class="code-box">
            <div class="code">${code}</div>
          </div>

          <p><strong>Важно:</strong></p>
          <ul>
            <li>Код действителен в течение 15 минут</li>
            <li>Используйте этот код только один раз</li>
            <li>Если вы не запрашивали восстановление пароля, проигнорируйте это письмо</li>
          </ul>

          <div class="footer">
            <p>Это автоматическое письмо. Пожалуйста, не отвечайте на него.</p>
            <p>&copy; 2025 RentMus. Все права защищены.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Восстановление пароля - RentMus

Здравствуйте, ${username || 'пользователь'}!

Вы запросили восстановление пароля для вашей учетной записи RentMus.

Ваш код для восстановления пароля: ${code}

Важно:
- Код действителен в течение 15 минут
- Используйте этот код только один раз
- Если вы не запрашивали восстановление пароля, проигнорируйте это письмо

Это автоматическое письмо. Пожалуйста, не отвечайте на него.

© 2025 RentMus. Все права защищены.
    `,
  };

  try {
    if (transporter) {
      const info = await transporter.sendMail(mailOptions);
      console.log('\n✅ EMAIL SENT SUCCESSFULLY!');
      console.log('   To:', email);
      console.log('   Message ID:', info.messageId);
      console.log('   Code:', code);
      console.log('');
      return { success: true, messageId: info.messageId };
    } else {
      console.log('\n📧 [DEV MODE] Password Reset Code:');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('   Email:', email);
      console.log('   User:', username || 'Unknown');
      console.log('');
      console.log('   🔑 CODE:', code);
      console.log('');
      console.log('   Valid for: 15 minutes');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return { success: true, messageId: 'dev-mode' };
    }
  } catch (error) {
    console.error('\n❌ ERROR SENDING EMAIL!');
    console.error('   Error:', error.message);
    console.error('   Code:', error.code);
    console.error('');
    if (error.message.includes('Invalid login')) {
      console.error('💡 Tip: Make sure you are using App Password, not regular Gmail password');
      console.error('   See: lib/server/QUICK_EMAIL_SETUP.txt');
    }
    console.error('');
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendPasswordResetCode,
};
