# Student Welfare Fund App

A Flutter application designed to support students through community donations and welfare programs.

## Features

### 🎨 Welcome Splash Screen
- Beautiful gradient background with app branding
- Animated app logo and welcome message
- Smooth transitions to main application

### 🏠 Main Home Screen
- **Top Section**: Gradient background with app logo and search functionality
- **Interactive Features**: Three main action cards
  - Quick Donate: Fast donation process
  - Gift a Donation: Donate on behalf of others
  - My Donations: View donation history
- **Student Registration Banner**: Prominent call-to-action for students to register for support
- **Campaign List**: Display of active donation campaigns with progress tracking

## Architecture & Design

### 📁 Project Structure
```
lib/
├── constants/
│   ├── app_colors.dart      # Color scheme and gradients
│   ├── app_text_styles.dart # Typography system
│   └── app_constants.dart   # App-wide constants
├── models/
│   ├── campaign.dart        # Campaign data model
│   └── donation.dart        # Donation data model
├── screens/
│   ├── splash_screen.dart   # Welcome screen
│   └── home_screen.dart     # Main home screen
├── widgets/
│   └── common/
│       ├── app_logo.dart    # Reusable logo component
│       ├── gradient_button.dart # Animated gradient button
│       ├── feature_card.dart    # Interactive feature cards
│       └── campaign_card.dart  # Campaign display cards
└── main.dart               # App entry point
```

### 🎯 Design Principles

#### Responsive Design
- Flexible layouts that adapt to different screen sizes
- Proper use of constraints and flexible widgets
- Mobile-first approach with tablet considerations

#### RTL Support
- Built-in support for Right-to-Left languages
- Configurable text direction in main.dart
- Proper alignment and layout considerations

#### Clean Code Practices
- **Separation of Concerns**: UI, business logic, and data models are separated
- **Reusable Components**: Common widgets for consistent UI
- **Constants Management**: Centralized color, text, and constant definitions
- **Type Safety**: Strong typing throughout the application
- **Documentation**: Clear code comments and structure

### 🎨 UI/UX Features

#### Color Scheme
- **Primary**: Indigo gradient (#6366F1 to #818CF8)
- **Secondary**: Green gradient (#10B981 to #34D399)
- **Accent**: Amber gradient (#F59E0B to #FBBF24)
- **Background**: Light gray (#F8FAFC)
- **Surface**: White (#FFFFFF)

#### Typography System
- **Display**: Large, bold text for headlines
- **Headline**: Medium weight for section titles
- **Title**: Semi-bold for card titles
- **Body**: Regular weight for content
- **Label**: Medium weight for small text
- **Button**: Bold weight for call-to-action text

#### Interactive Elements
- **Animated Buttons**: Scale animations on press
- **Gradient Cards**: Beautiful gradient backgrounds with shadows
- **Progress Indicators**: Visual progress tracking for campaigns
- **Smooth Transitions**: Page transitions and loading states

## Getting Started

### Prerequisites
- Flutter SDK (3.5.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd student_welfare_fund_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Customization

### Changing Colors
Edit `lib/constants/app_colors.dart` to modify the color scheme:
```dart
static const Color primary = Color(0xFF6366F1);
static const Color secondary = Color(0xFF10B981);
```

### Adding New Features
1. Create new screens in `lib/screens/`
2. Add reusable widgets in `lib/widgets/common/`
3. Update routes in `lib/main.dart`
4. Add constants in `lib/constants/app_constants.dart`

### RTL Support
To enable RTL layout, change in `lib/main.dart`:
```dart
textDirection: TextDirection.rtl, // For RTL languages
```

## Future Enhancements

### Planned Features
- [ ] User authentication and profiles
- [ ] Payment integration for donations
- [ ] Push notifications for campaign updates
- [ ] Offline support with local storage
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Advanced search and filtering
- [ ] Social sharing features

### Technical Improvements
- [ ] State management (Provider/Riverpod)
- [ ] API integration for real data
- [ ] Unit and widget tests
- [ ] CI/CD pipeline
- [ ] Performance optimization
- [ ] Accessibility improvements

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

---

**Built with ❤️ using Flutter**
