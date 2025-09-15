import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(
        Icons.language,
        color: AppColors.surface,
      ),
      tooltip: 'language'.tr(),
      onSelected: (Locale locale) {
        context.setLocale(locale);
        
        // Force rebuild of the entire app
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // Navigate to home to refresh the entire app
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale('ar'),
          child: Row(
            children: [
              const Text('🇸🇦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('arabic'.tr()),
              if (context.locale.languageCode == 'ar')
                const Spacer(),
              if (context.locale.languageCode == 'ar')
                const Icon(Icons.check, color: AppColors.primary),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇺🇸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('english'.tr()),
              if (context.locale.languageCode == 'en')
                const Spacer(),
              if (context.locale.languageCode == 'en')
                const Icon(Icons.check, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('language'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                    title: Text('arabic'.tr()),
                    trailing: context.locale.languageCode == 'ar'
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      context.setLocale(const Locale('ar'));
                      Navigator.of(context).pop();
                      
                      // Force rebuild of the entire app
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          // Navigate to home to refresh the entire app
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                    title: Text('english'.tr()),
                    trailing: context.locale.languageCode == 'en'
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      context.setLocale(const Locale('en'));
                      Navigator.of(context).pop();
                      
                      // Force rebuild of the entire app
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          // Navigate to home to refresh the entire app
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.language),
      label: Text('language'.tr()),
    );
  }
}
