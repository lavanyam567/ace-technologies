# Quick Start Guide - Frontend-Only Ace Technologies App

## 🚀 Getting Started

### 1. Prerequisites
- Flutter 3.11.5+ installed
- Dart SDK (comes with Flutter)
- Android emulator/device OR Chrome browser for web

### 2. Setup (First Time Only)
```bash
cd d:\PDD_final\my_app

# Download all dependencies
flutter pub get
```

### 3. Run the App

#### On Android/iOS Emulator
```bash
flutter run
```

#### On Web (Chrome)
```bash
flutter run -d chrome
```

#### Build for Web Release
```bash
flutter build web --release
# Output: build/web/
```

## 📱 What Works

### Browsing
- ✅ Home screen with featured products
- ✅ Products screen (100+ products)
- ✅ Services screen (8 services)
- ✅ Product details with images
- ✅ Service details

### Shopping
- ✅ Add to cart
- ✅ Remove from cart
- ✅ Update quantities
- ✅ View cart total
- ✅ Checkout (mock)

### Filtering & Search
- ✅ Search by product name
- ✅ Filter by category
- ✅ Filter by price range
- ✅ Filter by brand
- ✅ Filter by discount
- ✅ Sort by price/rating

### User Features
- ✅ Sign in / Sign up
- ✅ View profile
- ✅ View orders
- ✅ Track orders
- ✅ Manage wishlist
- ✅ Settings

### Other
- ✅ AI Chatbot (local responses)
- ✅ Dark/Light theme
- ✅ Responsive design
- ✅ Bottom navigation (mobile)
- ✅ Sidebar navigation (desktop)

## 🎨 Responsive Breakpoints

The app automatically adapts to screen size:

| Device Type | Width | Navigation | Layout |
|------------|-------|-----------|--------|
| Mobile | ≤ 480px | Bottom nav | Single column |
| Tablet | 481-768px | Bottom nav | 2 columns |
| Desktop | 769-1024px | Sidebar | 2-3 columns |
| Large Desktop | > 1024px | Sidebar | 4+ columns |

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/                  # Light/dark themes
│   ├── router/                 # Navigation routing
│   └── responsive/             # Responsive utilities
├── features/
│   ├── home/                   # Home screen
│   ├── products/               # Products & browsing
│   ├── services/               # Services
│   ├── cart/                   # Shopping cart
│   ├── orders/                 # Order management
│   ├── account/                # User account
│   └── chatbot/                # AI chatbot
├── models/
│   ├── product_model.dart      # Product data (100+)
│   ├── service_model.dart      # Service data (8)
│   └── order_model.dart        # Order data
├── providers/
│   ├── auth_provider.dart      # User auth (local)
│   ├── cart_provider.dart      # Cart state
│   └── theme_provider.dart     # Theme state
└── widgets/
    ├── product_card.dart       # Product display
    ├── service_card.dart       # Service display
    └── responsive_*.dart       # Responsive widgets
```

## 💾 Data

### Products (100+)
- Processors, Laptops, Networking, CCTV, etc.
- Price: ₹18,999 - ₹75,000+
- All have images and details

### Services (8)
- CCTV Installation, Networking, Server Setup, etc.
- Price: ₹2,499 - ₹7,999
- Professional descriptions

### Sample Orders (3)
- Different status: Processing, Shipped, Delivered
- For demo order tracking

## 🔄 Local Storage

Persistent across app restarts:
- ✅ Chat history (Shared Preferences)
- ✅ Theme preference (light/dark)
- ⚠️ Cart items (cleared on restart)
- ⚠️ User login (session only)

## ⚙️ Configuration

No configuration needed! App is fully self-contained.

### To Change Data:
Edit files in `lib/models/`:
- `product_model.dart` - Add/remove products
- `service_model.dart` - Add/remove services
- `order_model.dart` - Modify sample orders

## 🐛 Troubleshooting

### App won't start
```bash
flutter clean
flutter pub get
flutter run
```

### Hot reload not working
```bash
# Stop the app and restart
flutter run
```

### Build web error
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Images not loading
- Check internet connection (uses Unsplash URLs)
- Public URLs should work globally

## 📊 Performance Tips

- App runs completely offline (no backend calls)
- Instant data loading from local models
- No API latency
- Smooth 60 FPS animations

## 🎯 Test Scenarios

### 1. Browse Products
1. Open app
2. Go to Products tab
3. Filter by category/price
4. Search for product
5. View product details

### 2. Shopping Cart
1. Add products to cart
2. View cart
3. Update quantities
4. Clear cart

### 3. User Account
1. Sign in with any email
2. View profile
3. Check orders
4. Logout

### 4. Chatbot
1. Go to chat screen
2. Ask "show me products"
3. Ask "how much is a laptop"
4. Ask "book a service"

## 📈 Next Steps (To Add Backend)

When ready to integrate a backend:

1. Add `http` package to `pubspec.yaml`
2. Create API service in `lib/core/services/`
3. Replace data calls with HTTP requests
4. Implement proper authentication
5. Add payment gateway
6. Deploy backend server

## 📝 Notes

- This is a **frontend-only demo app**
- Perfect for prototyping and testing UI/UX
- All features work locally
- No server required
- Can be deployed as PWA (Progressive Web App)

---

**Happy coding! 🎉**
