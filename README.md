# InsureVis

![InsureVis Banner](assets/images/logo/4.png)
> *AI-Powered Vehicle Damage Assessment for Streamlined Insurance Claims*

---

## 📖 About
**InsureVis** is a mobile application designed to revolutionize the insurance claims process by leveraging artificial intelligence to analyze vehicle damage through photos. This project was built to address the inefficiencies in traditional vehicle damage assessment—reducing manual inspection time, improving accuracy, and providing instant cost estimates.

As an insurance claimant, you simply take photos of your damaged vehicle, and InsureVis analyzes the damage in real-time, generates professional PDF reports, and seamlessly submits claims to insurance companies—all from your mobile device.

---

## 🛠 Tech Stack

**Frontend:**
* [Flutter](https://flutter.dev/) - Cross-platform mobile framework
* [Material 3 Design](https://m3.material.io/) - Modern UI/UX components
* [Provider](https://pub.dev/packages/provider) - State management

**Backend:**
* [Supabase](https://supabase.com/) - Backend-as-a-Service (Authentication, Database, Storage)
* [Firebase](https://firebase.google.com/) - Push notifications and analytics

**AI/ML:**
* Custom damage detection API with confidence scoring
* Real-time image processing and analysis

**Additional Tools:**
* [Camera Plugin](https://pub.dev/packages/camera) - Photo capture functionality
* [PDF Generation](https://pub.dev/packages/pdf) - Professional report creation
* [Photo Manager](https://pub.dev/packages/photo_manager) - Gallery integration
* [Flutter ScreenUtil](https://pub.dev/packages/flutter_screenutil) - Responsive design

---

## ✨ Key Features

* **Real-Time AI Damage Detection:** Analyzes vehicle damage instantly with 96%+ accuracy and displays confidence scores.
* **Smart Camera System:** Intuitive camera interface with live AI overlay for multi-angle photo capture.
* **Assessment Comparison:** Side-by-side comparison of multiple assessments with comprehensive cost breakdowns.
* **Offline-First Architecture:** Works seamlessly offline with automatic cloud synchronization when online.
* **Professional PDF Reports:** Generate customizable, multi-format PDF reports for insurance submissions.
* **Advanced Search & Filtering:** Multi-criteria search with date range, severity, and cost filters.
* **Dark/Light Theme Support:** Modern Material 3 design with accessibility features and dynamic theming.
* **Analytics Dashboard:** Real-time metrics with interactive charts and CSV/Excel export capabilities.

---

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites
* Flutter SDK (v3.0 or higher)
* Android Studio or Xcode for platform development
* Dart SDK (comes with Flutter)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/insurevis.git
   cd insurevis
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   - Create a `.env` file in the root directory
   - Add your API keys and configuration (see `.env.example`)
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_key
   FIREBASE_API_KEY=your_firebase_key
   ```

4. **Run the project**
   ```bash
   flutter run
   ```

5. **Build for production**
   ```bash
   # For Android
   flutter build apk --release
   
   # For iOS
   flutter build ios --release
   ```
---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**InsureVis** - Revolutionizing vehicle damage assessment through AI technology 🚗✨