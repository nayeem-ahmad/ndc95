const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure email transporter
// For Gmail: Use App Password (not your regular Gmail password)
// Go to: https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().email.user, // Your Gmail address
    pass: functions.config().email.password, // Your Gmail App Password
  },
});

/**
 * Send verification code email when a new code is created in Firestore
 * Triggered by: Creating a document in verificationCodes collection
 */
exports.sendVerificationEmail = functions.firestore
    .document("verificationCodes/{email}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const email = context.params.email;
      const code = data.code;
      const createdAt = data.createdAt;

      console.log(`📧 Sending verification code to: ${email}`);

      // Email HTML template
      const htmlTemplate = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 20px;
            border-radius: 10px;
            text-align: center;
        }
        .content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .logo {
            font-size: 48px;
            margin-bottom: 10px;
        }
        h1 {
            color: white;
            margin: 10px 0;
            font-size: 28px;
        }
        .code-container {
            background: #f0f4ff;
            border: 3px solid #667eea;
            border-radius: 10px;
            padding: 20px;
            margin: 30px 0;
        }
        .code {
            font-size: 48px;
            font-weight: bold;
            letter-spacing: 10px;
            color: #667eea;
            font-family: 'Courier New', monospace;
        }
        .info {
            color: #666;
            font-size: 14px;
            margin-top: 20px;
        }
        .warning {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin-top: 20px;
            text-align: left;
        }
        .footer {
            color: white;
            margin-top: 20px;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🎓</div>
        <h1>NDC95 Verification Code</h1>
        
        <div class="content">
            <h2>Welcome Notredamian!</h2>
            <p>Your verification code is:</p>
            
            <div class="code-container">
                <div class="code">${code}</div>
            </div>
            
            <p class="info">
                This code will expire in <strong>10 minutes</strong>.
                <br>
                Please enter it in the app to continue.
            </p>
            
            <div class="warning">
                <strong>⚠️ Security Notice:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>Never share this code with anyone</li>
                    <li>NDC95 staff will never ask for your code</li>
                    <li>If you didn't request this code, please ignore this email</li>
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p>Notre Dame College, Dhaka - Batch 1995</p>
            <p>This is an automated message, please do not reply.</p>
        </div>
    </div>
</body>
</html>
      `;

      const mailOptions = {
        from: `"NDC95 Community" <${functions.config().email.user}>`,
        to: email,
        subject: `Your NDC95 Verification Code: ${code}`,
        html: htmlTemplate,
        text: `Your NDC95 verification code is: ${code}\n\n` +
              `This code will expire in 10 minutes.\n\n` +
              `If you didn't request this code, please ignore this email.\n\n` +
              `Notre Dame College, Dhaka - Batch 1995`,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log(`✅ Verification email sent successfully to: ${email}`);

        // Update the document to mark email as sent
        await snap.ref.update({
          emailSent: true,
          emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {success: true};
      } catch (error) {
        console.error(`❌ Error sending email to ${email}:`, error);

        // Update the document to mark email as failed
        await snap.ref.update({
          emailSent: false,
          emailError: error.message,
        });

        throw new functions.https.HttpsError(
            "internal",
            "Failed to send verification email",
        );
      }
    });

/**
 * Clean up expired verification codes
 * Runs every hour
 */
exports.cleanupExpiredCodes = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
      const now = new Date();
      const db = admin.firestore();

      console.log("🧹 Cleaning up expired verification codes...");

      const snapshot = await db.collection("verificationCodes").get();
      const batch = db.batch();
      let deleteCount = 0;

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const expiresAt = new Date(data.expiresAt);

        if (expiresAt < now) {
          batch.delete(doc.ref);
          deleteCount++;
        }
      });

      if (deleteCount > 0) {
        await batch.commit();
        console.log(`✅ Deleted ${deleteCount} expired verification codes`);
      } else {
        console.log("✅ No expired codes to delete");
      }

      return null;
    });

/**
 * HTTP endpoint to manually send verification email (for testing)
 */
exports.sendTestVerificationEmail = functions.https.onCall(
    async (data, context) => {
      // Check if user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const email = data.email;
      const code = data.code || Math.floor(100000 + Math.random() * 900000)
          .toString();

      if (!email) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Email is required",
        );
      }

      // Store in Firestore (this will trigger sendVerificationEmail)
      await admin.firestore().collection("verificationCodes").doc(email).set({
        code: code,
        email: email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
      });

      return {
        success: true,
        message: "Verification email will be sent shortly",
        code: code, // Only for testing, remove in production
      };
    },
);
