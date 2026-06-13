const fs = require('fs');
const path = require('path');

const outputPath = path.resolve(__dirname, '../env.ci.json');

const env = {
  SUPABASE_URL: process.env.SUPABASE_URL || 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || 'your-supabase-anon-key',
  PAYMENT_GATEWAY: process.env.PAYMENT_GATEWAY || 'razorpay',
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID || 'rzp_test_your_key_id',
  APP_REDIRECT_URL: process.env.APP_REDIRECT_URL || 'http://127.0.0.1:4173',
};

if (process.env.GEMINI_API_KEY) {
  env.GEMINI_API_KEY = process.env.GEMINI_API_KEY;
}

fs.writeFileSync(outputPath, `${JSON.stringify(env, null, 2)}\n`, 'utf8');
console.log(`Created ${outputPath}`);
