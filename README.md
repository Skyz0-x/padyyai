# PaddyAI - Smart Rice Paddy Management Platform

A comprehensive Flutter application designed to help farmers optimize rice paddy management through AI-powered disease detection, field monitoring, scheduling, and supplier marketplace integration.

## Features

### 🤖 AI Disease Detection
- Real-time rice disease detection using TensorFlow Lite models
- Detects multiple disease types: Bacterial Leaf Blight, Blast, Brown Spot
- Confidence scoring and detailed disease analysis
- Automatic pesticide recommendations based on detected disease
- Prevention tips and treatment guidance

### 📊 Field Monitoring & Management
- Paddy monitoring dashboard with growth tracking
- Field records for historical data and analysis
- Farming calendar with seasonal reminders
- Comprehensive farmland management tools

### 🛒 Supplier Marketplace
- Integrated supplier network for pesticides and farming inputs
- Disease-specific product filtering
- Cart and payment system for easy ordering
- Direct supplier order management

### 📱 Additional Capabilities
- Multi-language support (i18n localization)
- Google Sign-In integration
- Image capture and processing for disease detection
- Supabase backend for data persistence
- Responsive UI for multiple device sizes

## Technology Stack

- **Framework**: Flutter 3.7.2+
- **Backend**: Supabase (PostgreSQL)
- **AI/ML**: TensorFlow Lite for on-device inference
- **Authentication**: Google Sign-In, Supabase Auth
- **Storage**: Supabase PostgreSQL with secure Row-Level Security
- **Languages**: Dart (Flutter), SQL (PostgreSQL)

## Project Structure

```
lib/
├── screens/          # UI screens (detection, marketplace, monitoring, etc.)
├── services/         # Business logic (disease detection, Supabase, auth)
├── models/           # Data models
├── widgets/          # Reusable UI components
├── config/           # Configuration files
├── utils/            # Utility functions
└── l10n/             # Localization files

assets/
├── images/           # App images and icons
├── model/            # TensorFlow Lite model files
└── video/            # Video assets
```

## Getting Started

### Prerequisites
- Flutter 3.7.2 or higher
- Dart SDK 3.7.2+
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd paddyai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Copy your project credentials
   - Update configuration in `lib/config/supabase_config.dart`

4. **Build and run**
   ```bash
   flutter run
   ```

## Key Guides & Documentation

- [AI Implementation Guide](AI_IMPLEMENTATION_GUIDE.md) - Disease detection system
- [Supabase Setup](SUPABASE_CERTIFICATE_SETUP.md) - Database configuration
- [Firebase Integration](CHATBOT_SETUP.md) - Chatbot setup
- [Testing Documentation](TEST_DOCUMENTATION.md) - Testing procedures
- [SQL Setup](SQL_SETUP_GUIDE.md) - Database schema

## API & Services

### Disease Detection Service
- Analyzes uploaded images for rice diseases
- Returns predictions with confidence scores
- Provides treatment recommendations and pesticide suggestions

### Supabase Integration
- Real-time database synchronization
- User authentication and profiles
- Orders and supplier management
- Disease detection history

## Development

### Running Tests
```bash
flutter test
```

### Building for Release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Contributing

Please refer to the project documentation for contribution guidelines and development setup procedures.

## License

This project is private and not intended for public distribution.

## Support

For issues, feature requests, or technical support, please refer to the internal documentation or contact the development team.
