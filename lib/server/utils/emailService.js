const SibApiV3Sdk = require('sib-api-v3-sdk');

const client = SibApiV3Sdk.ApiClient.instance;
client.authentications['api-key'].apiKey = process.env.BREVO_API_KEY;

const transactionalApi = new SibApiV3Sdk.TransactionalEmailsApi();
const FROM = { email: 'noreply@rentmus.app', name: 'RentMus' };

const sendEmail = async (to, subject, html) => {
  const email = new SibApiV3Sdk.SendSmtpEmail();
  email.to = [{ email: to }];
  email.sender = FROM;
  email.subject = subject;
  email.htmlContent = html;
  return transactionalApi.sendTransacEmail(email);
};

const sendPasswordResetCode = async (email, code, username) => {
  try {
    await sendEmail(email, 'Құпия сөзді қалпына келтіру - RentMus', `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;background:linear-gradient(135deg,#1A1A2E,#16213E);border-radius:10px;color:white;">
        <h1 style="color:#E94560;margin-top:0;">Құпия сөзді қалпына келтіру</h1>
        <p>Сәлеметсіз бе, ${username || 'қолданушы'}!</p>
        <p>Сіз RentMus аккаунтыңыздың құпия сөзін қалпына келтіруді сұрадыңыз.</p>
        <div style="background:rgba(233,69,96,0.2);border:2px solid #E94560;border-radius:8px;padding:20px;text-align:center;margin:20px 0;">
          <div style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#E94560;">${code}</div>
        </div>
        <ul>
          <li>Код 15 минут ішінде жарамды</li>
          <li>Егер сіз бұл сұранысты жібермеген болсаңыз, бұл хатты елемеңіз</li>
        </ul>
        <p style="font-size:12px;color:rgba(255,255,255,0.6);">© 2025 RentMus. Барлық құқықтар қорғалған.</p>
      </div>
    `);
    console.log('✅ Password reset email sent to:', email);
    return { success: true };
  } catch (err) {
    console.error('❌ ERROR SENDING PASSWORD RESET EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

const sendEmailVerificationCode = async (email, code, username) => {
  try {
    await sendEmail(email, 'Email растау - RentMus', `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;background:linear-gradient(135deg,#1A1A2E,#16213E);border-radius:10px;color:white;">
        <h1 style="color:#E94560;margin-top:0;">Email растау</h1>
        <p>Сәлеметсіз бе, ${username || 'қолданушы'}!</p>
        <p>RentMus-ке тіркелгеніңіз үшін рақмет! Email растау кодыңыз:</p>
        <div style="background:rgba(233,69,96,0.2);border:2px solid #E94560;border-radius:8px;padding:20px;text-align:center;margin:20px 0;">
          <div style="font-size:36px;font-weight:bold;letter-spacing:10px;color:#E94560;">${code}</div>
        </div>
        <ul>
          <li>Код 15 минут ішінде жарамды</li>
          <li>Егер сіз тіркелмеген болсаңыз, бұл хатты елемеңіз</li>
        </ul>
        <p style="font-size:12px;color:rgba(255,255,255,0.6);">© 2025 RentMus. Барлық құқықтар қорғалған.</p>
      </div>
    `);
    console.log('✅ Verification email sent to:', email, '| Code:', code);
    return { success: true };
  } catch (err) {
    console.error('❌ ERROR SENDING VERIFICATION EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

const sendBookingConfirmedEmail = async (email, username, itemName) => {
  try {
    await sendEmail(email, 'Брондауыңыз расталды - RentMus', `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;background:linear-gradient(135deg,#1A1A2E,#16213E);border-radius:10px;color:white;">
        <h1 style="color:#27AE60;margin-top:0;">Брондау расталды!</h1>
        <p>Сәлеметсіз бе, ${username || 'қолданушы'}!</p>
        <div style="background:rgba(39,174,96,0.2);border:2px solid #27AE60;border-radius:8px;padding:20px;text-align:center;margin:20px 0;">
          <div style="font-size:48px;">✅</div>
          <p style="font-size:18px;font-weight:bold;">${itemName || 'Өтінішіңіз мақұлданды'}</p>
        </div>
        <p>Сатушы сіздің брондау өтінішіңізді қабылдады.</p>
        <p style="font-size:12px;color:rgba(255,255,255,0.6);">© 2025 RentMus. Барлық құқықтар қорғалған.</p>
      </div>
    `);
    console.log('✅ Booking confirmed email sent to:', email);
    return { success: true };
  } catch (err) {
    console.error('❌ ERROR SENDING BOOKING EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

module.exports = { sendPasswordResetCode, sendEmailVerificationCode, sendBookingConfirmedEmail };
