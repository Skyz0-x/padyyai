import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../utils/constants.dart';
import '../l10n/app_locale.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterLocalization _localization = FlutterLocalization.instance;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _currentLanguage = _localization.currentLocale?.languageCode ?? 'en';
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    _localization.translate(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildSectionHeader('Language Settings'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: cardDecoration,
                            child: Column(
                              children: [
                                _buildLanguageTile(
                                  'English',
                                  'en',
                                  Icons.language,
                                ),
                                const Divider(height: 1),
                                _buildLanguageTile(
                                  'Bahasa Melayu',
                                  'ms',
                                  Icons.translate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('App Settings'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: cardDecoration,
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  AppLocale.notifications.getString(context),
                                  'Manage notification preferences',
                                  Icons.notifications_outlined,
                                  () {
                                    // TODO: Navigate to notifications settings
                                  },
                                ),
                                const Divider(height: 1),
                                _buildSettingTile(
                                  AppLocale.privacyPolicy.getString(context),
                                  AppLocale.readPolicies.getString(context),
                                  Icons.privacy_tip_outlined,
                                  () {
                                    // TODO: Show privacy policy
                                  },
                                ),
                                const Divider(height: 1),
                                _buildSettingTile(
                                  AppLocale.helpSupport.getString(context),
                                  AppLocale.getAssistance.getString(context),
                                  Icons.help_outline,
                                  () {
                                    // TODO: Show help & support
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('About'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: cardDecoration,
                            child: _buildInfoTile(
                              AppLocale.version.getString(context),
                              '1.0.0',
                              Icons.info_outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.settings.getString(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Manage app preferences',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: subHeadingStyle.copyWith(
          fontSize: 14,
          color: textLightColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String title, String languageCode, IconData icon) {
    final isSelected = _currentLanguage == languageCode;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : textLightColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? primaryColor : textDarkColor,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: primaryColor)
          : const Icon(Icons.circle_outlined, color: textLightColor),
      onTap: () => _changeLanguage(languageCode),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textDarkColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: captionStyle,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textDarkColor,
        ),
      ),
      trailing: Text(
        value,
        style: bodyStyle.copyWith(
          color: textLightColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
