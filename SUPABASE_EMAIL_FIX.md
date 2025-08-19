## How to Disable Email Confirmation in Supabase

### Step 1: Access Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: `insurevis` 

### Step 2: Disable Email Confirmation
1. Navigate to **Authentication** → **Settings**
2. Scroll down to **Email** section
3. **Uncheck** "Enable email confirmations"
4. Click **Save**

### Step 3: Test Signup
After making this change:
- Users can sign up without email verification
- Accounts will be created immediately
- No confirmation email will be sent
- Users can sign in right away

### Step 4: Verify the Fix
1. Try signing up with a new account
2. Account should be created successfully
3. You should be able to sign in immediately

### Alternative: Configure Email Properly
If you want to keep email verification:
1. Go to **Settings** → **Auth** → **SMTP Settings**
2. Configure your email provider (Gmail, SendGrid, etc.)
3. Set up proper sender email and SMTP credentials
4. Test email configuration

### Note:
Disabling email confirmation is fine for development and testing.
For production, you may want to properly configure email delivery.
