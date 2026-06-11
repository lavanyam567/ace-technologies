# Supabase Setup Guide

This project uses **Supabase** (PostgreSQL + Auth + Real-time API) as the backend database for both the Flutter frontend and Express.js API server.

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/log in
2. Click **"New Project"** and create a new project
3. Choose a name (e.g., "AceTechnologies") and region
4. Save your database password (you'll need it for local development)
5. Wait for the project to initialize

## Step 2: Get Your Credentials

From your Supabase project dashboard:

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://your-project.supabase.co`
   - **Anon/Public Key**: Used in frontend and backend
   - **Service Role Key**: Used for admin operations (keep secret!)

## Step 3: Create Database Tables

In your Supabase dashboard, go to **SQL Editor** and run these queries to create tables:

```sql
-- Users table (Supabase Auth handles authentication)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'customer',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Products table
CREATE TABLE public.products (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  stock INTEGER DEFAULT 0,
  category TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Services table
CREATE TABLE public.services (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  duration_hours INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Cart table
CREATE TABLE public.cart (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Orders table
CREATE TABLE public.orders (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  total_amount DECIMAL(10, 2) NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Bookings table
CREATE TABLE public.bookings (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  service_id BIGINT REFERENCES public.services(id) ON DELETE CASCADE,
  booking_date TIMESTAMP NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Step 4: Configure Backend (.env)

In `backend/.env`, replace the placeholder values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs... (your actual anon key)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIs... (your service role key)
PORT=5000
NODE_ENV=development
JWT_SECRET=supersecretjwtkey_replace_me_later
JWT_EXPIRE=7d
```

## Step 5: Configure Frontend (lib/main.dart)

In `lib/main.dart`, replace the Supabase credentials:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIs...', // your actual anon key
  );

  runApp(
    const ProviderScope(
      child: AceTechnologiesApp(),
    ),
  );
}
```

## Step 6: Install Backend Dependencies

```bash
cd backend
npm install
```

This will install:
- `@supabase/supabase-js` - Supabase client for Node.js
- `express` - Web framework
- `cors` - Cross-origin support
- `jsonwebtoken` - JWT authentication
- `bcryptjs` - Password hashing
- `dotenv` - Environment variables

## Step 7: Start the Backend Server

```bash
cd backend
npm run dev  # Uses nodemon for auto-restart on changes
```

The server should start on `http://localhost:5000`

## Step 8: Update Supabase Row Level Security (RLS)

For security, enable RLS on your tables in Supabase **Authentication** tab.

Example policy for `public.products` (allow public read):
```sql
CREATE POLICY "Allow public read on products"
ON public.products
FOR SELECT
USING (true);
```

## Step 9: Run the Flutter App

```bash
cd my_app
flutter run
```

The app will connect to Supabase and the Express backend at `http://localhost:5000/api`.

## Testing the Setup

1. **Backend API**: Visit `http://localhost:5000/api/products` to test the API
2. **Supabase**: Check the Supabase dashboard to see real-time data updates
3. **Flutter App**: Run and test authentication and product loading

## Common Issues

### Issue: "SUPABASE_URL not found" or "SUPABASE_ANON_KEY not found"
- Make sure `.env` file exists in `backend/` folder
- Make sure you replaced placeholder values with actual credentials
- Make sure `dotenv.config()` is called before using environment variables in `server.js`

### Issue: CORS errors
- CORS is already configured in `server.js` for all origins
- If issues persist, update the CORS configuration:
  ```javascript
  app.use(cors({
    origin: ['http://localhost:3000', 'http://localhost:5000'],
    credentials: true
  }));
  ```

### Issue: Authentication fails
- Make sure Row Level Security (RLS) policies are set correctly in Supabase
- Use `SUPABASE_SERVICE_ROLE_KEY` for admin operations that bypass RLS

## Next Steps

1. Update all controllers (like `productController.js`) to use Supabase queries
2. Implement proper authentication with Supabase Auth
3. Set up real-time subscriptions using Supabase RealtimeClient
4. Add file uploads using Supabase Storage

See the updated `controllers/productController.js` for an example of how to use Supabase with Express.
