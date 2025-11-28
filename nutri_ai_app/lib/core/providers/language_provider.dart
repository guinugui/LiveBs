import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR'); // Português como padrão
  
  Locale get locale => _locale;
  
  String get languageCode => _locale.languageCode;
  
  // Idiomas suportados
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português Brasil
    Locale('en', 'US'), // Inglês
    Locale('es', 'ES'), // Espanhol
  ];
  
  static const Map<String, String> languageNames = {
    'pt': '🇧🇷 Português',
    'en': '🇺🇸 English',  
    'es': '🇪🇸 Español',
  };
  
  LanguageProvider() {
    _loadLanguageFromPrefs();
  }
  
  void changeLanguage(String languageCode) {
    switch (languageCode) {
      case 'pt':
        _locale = const Locale('pt', 'BR');
        break;
      case 'en':
        _locale = const Locale('en', 'US');
        break;
      case 'es':
        _locale = const Locale('es', 'ES');
        break;
      default:
        _locale = const Locale('pt', 'BR');
    }
    _saveLanguageToPrefs();
    notifyListeners();
  }
  
  Future<void> _loadLanguageFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'pt';
      changeLanguage(languageCode);
    } catch (e) {
      print('Erro ao carregar idioma: $e');
    }
  }
  
  Future<void> _saveLanguageToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', _locale.languageCode);
    } catch (e) {
      print('Erro ao salvar idioma: $e');
    }
  }
}