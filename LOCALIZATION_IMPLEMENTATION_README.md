# AR/EN Localization Implementation

This document describes the implementation of Arabic and English localization with RTL/LTR support in the Student Welfare Fund App.

## Features Implemented

### 1. Dependencies Added
- `flutter_localizations`: SDK localization support
- `easy_localization`: Easy-to-use localization package

### 2. Translation Files
- `assets/translations/en.json`: English translations
- `assets/translations/ar.json`: Arabic translations

### 3. Main App Setup
- EasyLocalization wrapper in `main.dart`
- Automatic RTL/LTR text direction based on locale
- Locale persistence (saves user's language choice)

### 4. Language Switcher Component
- `lib/widgets/language_switcher.dart`: Reusable language switcher
- Two variants: PopupMenuButton and Dialog-based button
- Visual indicators for current language selection

## How to Use

### 1. Using Translations in Widgets
```dart
import 'package:easy_localization/easy_localization.dart';

// Simple text translation
Text('hello'.tr())

// With parameters (if needed)
Text('welcome_user'.tr(namedArgs: {'name': 'Ahmed'}))

// Pluralization (if needed)
Text('item_count'.plural(5))
```

### 2. Adding New Translations

#### Step 1: Add to Translation Files
Add the new key to both `en.json` and `ar.json`:

**en.json:**
```json
{
  "new_key": "New English Text"
}
```

**ar.json:**
```json
{
  "new_key": "النص العربي الجديد"
}
```

#### Step 2: Use in Code
```dart
Text('new_key'.tr())
```

### 3. Language Switcher Usage

#### PopupMenuButton (for AppBar)
```dart
import '../widgets/language_switcher.dart';

AppBar(
  actions: [
    const LanguageSwitcher(),
  ],
)
```

#### Dialog Button (for Settings)
```dart
import '../widgets/language_switcher.dart';

LanguageSwitcherButton()
```

### 4. Programmatic Language Change
```dart
import 'package:easy_localization/easy_localization.dart';

// Change to Arabic
context.setLocale(const Locale('ar'));

// Change to English
context.setLocale(const Locale('en'));
```

## Current Translation Keys

The following keys are available in both languages:

### Basic App
- `app_title`: App title
- `welcome`: Welcome message
- `hello`: Hello greeting

### Navigation
- `home`: Home
- `my_donations`: My Donations
- `settings`: Settings
- `language`: Language

### Actions
- `donate_now`: Donate now
- `quick_donate`: Quick Donate
- `login`: Login
- `register`: Register
- `logout`: Logout
- `search`: Search
- `save`: Save
- `cancel`: Cancel
- `confirm`: Confirm

### Forms
- `email`: Email
- `password`: Password
- `full_name`: Full Name
- `phone_number`: Phone Number
- `student_id`: Student ID
- `amount`: Amount

### Status Messages
- `payment_success`: Payment successful
- `payment_failed`: Payment failed
- `loading`: Loading...
- `error`: Error
- `success`: Success
- `no_data`: No data available

### Motivational Messages
- `support_students`: Support Students
- `make_difference`: Make a Difference
- `every_donation_matters`: Every donation matters
- `help_students_succeed`: Help students succeed in their education

## RTL/LTR Support

The app automatically handles text direction:
- **Arabic (ar)**: Right-to-Left (RTL)
- **English (en)**: Left-to-Right (LTR)

This is configured in `main.dart`:
```dart
builder: (context, child) {
  return Directionality(
    textDirection: context.locale.languageCode == 'ar' 
        ? TextDirection.rtl 
        : TextDirection.ltr,
    child: child!,
  );
},
```

## Best Practices

1. **Always use translation keys** instead of hardcoded strings
2. **Add new keys to both language files** simultaneously
3. **Use descriptive key names** that indicate the context
4. **Test both languages** after adding new translations
5. **Keep translations consistent** across the app

## Example Implementation

Here's a complete example of a localized screen:

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/language_switcher.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: const [
          LanguageSwitcher(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'hello'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Your action here
              },
              child: Text('donate_now'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

To test the localization:

1. **Run the app** and verify it starts in the default language
2. **Use the language switcher** to change languages
3. **Restart the app** to verify language persistence
4. **Check RTL/LTR layout** for both languages
5. **Verify all text elements** are properly translated

## Future Enhancements

Potential improvements for the localization system:

1. **Add more languages** (French, Spanish, etc.)
2. **Implement pluralization** for complex grammar rules
3. **Add date/time localization** for different regions
4. **Implement number formatting** based on locale
5. **Add currency formatting** for different regions
6. **Create translation management** system for easy updates

## Troubleshooting

### Common Issues

1. **Translation not showing**: Check if the key exists in both language files
2. **RTL layout issues**: Verify Directionality widget is properly configured
3. **Language not persisting**: Ensure `saveLocale: true` is set in EasyLocalization
4. **Build errors**: Run `flutter pub get` after adding new dependencies

### Debug Tips

1. **Check console logs** for missing translation warnings
2. **Use `context.locale`** to debug current locale
3. **Verify asset paths** in pubspec.yaml
4. **Test on different devices** to ensure compatibility
