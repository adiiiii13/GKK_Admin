const express = require('express');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'gharkakhanasupport@gmail.com',
    pass: 'tfkq jmwv dzoh rxrd',
  },
});

app.post('/send-email', async (req, res) => {
  try {
    const { to, subject, body } = req.body;

    if (!to || !subject || !body) {
      return res.status(400).json({ success: false, error: 'Missing required fields: to, subject, body' });
    }

    await transporter.sendMail({
      from: '"Ghar Ka Khana" <gharkakhanasupport@gmail.com>',
      to,
      subject,
      text: body,
    });

    console.log(`Email sent to ${to}`);
    res.json({ success: true, message: `Email sent to ${to}` });
  } catch (error) {
    console.error('Email error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.listen(3001, () => {
  console.log('GKK Email Server running on http://localhost:3001');
});
