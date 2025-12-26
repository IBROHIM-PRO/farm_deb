import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () => _showLanguageDialog(context),
      tooltip: l10n.language,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageProvider.getSupportedLanguages().map((lang) {
              return ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(lang['name']!),
                trailing: languageProvider.locale.languageCode == lang['code']
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  languageProvider.setLocale(Locale(lang['code']!, ''));
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('close')),
            ),
          ],
        );
      },
    );
  }
}

/// Alternative: Language button with flag icon showing current language
class LanguageButtonWithFlag extends StatelessWidget {
  const LanguageButtonWithFlag({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);
    
    String getFlag(String languageCode) {
      switch (languageCode) {
        case 'en':
          return '🇬🇧';
        case 'ru':
          return '🇷🇺';
        case 'tg':
          return '🇹🇯';
        default:
          return '🌐';
      }
    }
    
    return TextButton(
      onPressed: () => _showLanguageDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getFlag(languageProvider.locale.languageCode),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageProvider.getSupportedLanguages().map((lang) {
              return ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(lang['name']!),
                trailing: languageProvider.locale.languageCode == lang['code']
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  languageProvider.setLocale(Locale(lang['code']!, ''));
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('close')),
            ),
          ],
        );
      },
    );
  }
}
