# 🚀 Supabase Setup Guide for InsureVis

## 📋 Prerequisites
1. Create a Supabase account at [supabase.com](https://supabase.com)
2. Create a new project
3. Get your project URL and API keys

## 🗄️ Database Schema Setup

### 1. Run the following SQL in your Supabase SQL editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR,
  profile_image_url VARCHAR,
  join_date TIMESTAMP DEFAULT NOW(),
  is_email_verified BOOLEAN DEFAULT FALSE,
  preferences JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Statistics table  
CREATE TABLE user_stats (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  total_assessments INTEGER DEFAULT 0,
  completed_assessments INTEGER DEFAULT 0,
  documents_submitted INTEGER DEFAULT 0,
  total_saved DECIMAL DEFAULT 0,
  last_active_date TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  vin VARCHAR UNIQUE,
  make VARCHAR NOT NULL,
  model VARCHAR NOT NULL,
  year INTEGER NOT NULL,
  insurance_provider VARCHAR,
  policy_number VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Assessments table
CREATE TABLE assessments (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  vehicle_id UUID REFERENCES vehicles(id),
  image_urls TEXT[],
  ai_results JSONB,
  status VARCHAR DEFAULT 'processing',
  estimated_cost DECIMAL,
  location POINT,
  incident_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 2. Enable Row Level Security (RLS):

```sql
-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- User stats policies
CREATE POLICY "Users can view own stats" ON user_stats
  FOR ALL USING (auth.uid() = user_id);

-- Vehicles policies
CREATE POLICY "Users can manage own vehicles" ON vehicles
  FOR ALL USING (auth.uid() = user_id);

-- Assessments policies
CREATE POLICY "Users can manage own assessments" ON assessments
  FOR ALL USING (auth.uid() = user_id);
```

### 3. Create indexes for performance:

```sql
-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_user_stats_user_id ON user_stats(user_id);
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_assessments_user_id ON assessments(user_id);
CREATE INDEX idx_assessments_status ON assessments(status);
```

## 🔧 Flutter Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.3.4
  crypto: ^3.0.3  # For password hashing if needed locally
```

## 🔑 Environment Variables

Create a `.env` file in your project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

## 📱 Flutter Integration

### 1. Initialize Supabase in your `main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}
```

### 2. Create the SupabaseService class in `lib/services/supabase_service.dart`

### 3. Update your UserProvider to integrate with Supabase

## 🔒 Authentication Setup

### 1. Configure Email Templates (Optional)
- Go to Authentication > Email Templates in your Supabase dashboard
- Customize confirmation and password reset emails

### 2. Configure OAuth Providers (Optional)
- Go to Authentication > Settings
- Enable Google, Apple, or other OAuth providers if needed

### 3. Set up Email Confirmation
- Enable email confirmation in Authentication > Settings
- Configure your email service (SMTP) if using custom domain

## 📂 Storage Setup

### 1. Create Storage Buckets:

```sql
-- Create buckets for file storage
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('avatars', 'avatars', true),
  ('assessment-images', 'assessment-images', true),
  ('documents', 'documents', false);
```

### 2. Set up Storage Policies:

```sql
-- Avatar storage policies
CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own avatar" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Assessment images policies
CREATE POLICY "Users can upload assessment images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'assessment-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own assessment images" ON storage.objects
  FOR SELECT USING (bucket_id = 'assessment-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## 🚀 Deployment Checklist

- [ ] Database schema created
- [ ] RLS policies enabled
- [ ] Storage buckets configured
- [ ] Authentication settings configured
- [ ] Environment variables set
- [ ] Flutter dependencies added
- [ ] Supabase service integrated
- [ ] User provider updated
- [ ] Authentication screens created
- [ ] Testing completed

## 📊 Monitoring & Analytics

1. **Database Performance**
   - Monitor query performance in Supabase dashboard
   - Set up alerts for slow queries

2. **Authentication Metrics**
   - Track user registration/login rates
   - Monitor authentication errors

3. **Storage Usage**
   - Monitor storage consumption
   - Set up alerts for storage limits

## 🔄 Migration Strategy

If migrating from local storage:

1. **Data Export**: Export existing user data from SharedPreferences
2. **Data Import**: Create migration script to import users to Supabase
3. **Gradual Migration**: Implement both local and remote data during transition
4. **Testing**: Thoroughly test the migration process
5. **Cutover**: Switch to Supabase-only mode

## 🛡️ Security Best Practices

1. **API Keys**: Never expose service role key in client-side code
2. **RLS**: Always use Row Level Security for data protection
3. **Validation**: Validate all inputs on both client and server side
4. **Monitoring**: Set up monitoring for suspicious activities
5. **Backups**: Enable automatic database backups
6. **SSL**: Ensure all connections use HTTPS/SSL

---

**Need Help?** 
- Check the [Supabase Documentation](https://supabase.com/docs)
- Join the [Supabase Discord](https://discord.supabase.com)
- Review the [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
