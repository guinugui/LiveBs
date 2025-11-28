import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? 'Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Aparência
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade400 
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Aparência',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dark Mode Toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        title: Text(localizations?.darkMode ?? 'Modo Escuro'),
                        subtitle: Text(
                          themeProvider.isDarkMode 
                            ? 'Tema escuro ativado' 
                            : 'Tema claro ativado',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        secondary: Icon(
                          themeProvider.isDarkMode 
                            ? Icons.dark_mode 
                            : Icons.light_mode,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade400 
                              : Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Seção Idioma
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade400 
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizations?.language ?? 'Idioma',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Selection
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Column(
                        children: [
                          _buildLanguageTile(
                            context,
                            '🇧🇷 Português',
                            'pt',
                            languageProvider.languageCode == 'pt',
                            languageProvider,
                          ),
                          const SizedBox(height: 8),
                          _buildLanguageTile(
                            context,
                            '🇺🇸 English',
                            'en',
                            languageProvider.languageCode == 'en',
                            languageProvider,
                          ),
                          const SizedBox(height: 8),
                          _buildLanguageTile(
                            context,
                            '🇪🇸 Español',
                            'es',
                            languageProvider.languageCode == 'es',
                            languageProvider,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informações do App
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade400 
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Informações',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    title: Text(
                      'Versão do App',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      '1.0.0',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    leading: Icon(
                      Icons.apps,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                    ),
                  ),
                  
                  ListTile(
                    title: Text(
                      'Desenvolvido por',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      'LiveBs Team',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    leading: Icon(
                      Icons.code,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String title,
    String languageCode,
    bool isSelected,
    LanguageProvider languageProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? (Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade800 
              : Theme.of(context).primaryColor.withOpacity(0.1))
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
          ? Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade500 
                  : Theme.of(context).primaryColor, 
              width: 2
            )
          : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade300 
                  : Theme.of(context).primaryColor)
              : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: isSelected 
          ? Icon(
              Icons.check_circle, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade400 
                  : Theme.of(context).primaryColor,
              size: 24,
            )
          : Icon(
              Icons.circle_outlined,
              color: Colors.grey,
              size: 24,
            ),
        onTap: isSelected 
          ? null 
          : () => languageProvider.changeLanguage(languageCode),
      ),
    );
  }
}