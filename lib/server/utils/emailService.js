const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM = 'RentMus <onboarding@resend.dev>';

const sendPasswordResetCode = async (email, code, username) => {
  try {
    const { data, error } = await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Құпия сөзді қалпына келтіру - RentMus',
      html: `
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
      `,
    });
    if (error) throw new Error(error.message);
    console.log('✅ Password reset email sent to:', email);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('❌ ERROR SENDING PASSWORD RESET EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

const sendEmailVerificationCode = async (email, code, username) => {
  try {
    const { data, error } = await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Email растау - RentMus',
      html: `
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
      `,
    });
    if (error) throw new Error(error.message);
    console.log('✅ Verification email sent to:', email, '| Code:', code);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('❌ ERROR SENDING VERIFICATION EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

const sendBookingConfirmedEmail = async (email, username, itemName) => {
  try {
    const { data, error } = await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Брондауыңыз расталды - RentMus',
      html: `
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
      `,
    });
    if (error) throw new Error(error.message);
    console.log('✅ Booking confirmed email sent to:', email);
    return { success: true, messageId: data.id };
  } catch (err) {
    console.error('❌ ERROR SENDING BOOKING EMAIL:', err.message);
    return { success: false, error: err.message };
  }
};

module.exports = { sendPasswordResetCode, sendEmailVerificationCode, sendBookingConfirmedEmail };
