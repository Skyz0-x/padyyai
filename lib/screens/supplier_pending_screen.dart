import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../services/auth_service.dart';
import '../l10n/app_locale.dart';

class SupplierPendingScreen extends StatefulWidget {
  const SupplierPendingScreen({super.key});

  @override
  State<SupplierPendingScreen> createState() => _SupplierPendingScreenState();
}

class _SupplierPendingScreenState extends State<SupplierPendingScreen> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.changeLanguage.getString(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: _localization.currentLocale?.languageCode,
                onChanged: (value) {
                  _localization.translate('en');
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              onTap: () {
                _localization.translate('en');
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('Bahasa Melayu'),
              leading: Radio<String>(
                value: 'ms',
                groupValue: _localization.currentLocale?.languageCode,
                onChanged: (value) {
                  _localization.translate('ms');
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              onTap: () {
                _localization.translate('ms');
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
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
              Colors.orange.shade700,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language button at top right
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showLanguageDialog,
                      icon: const Icon(Icons.language, size: 20),
                      label: Text(AppLocale.changeLanguage.getString(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Center content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pending Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.orange,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Title
                            Text(
                              AppLocale.accountUnderReviewTitle.getString(context),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            Text(
                              AppLocale.thanksForRegistering.getString(context),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              AppLocale.emailNotificationOnApproval.getString(context),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await AuthService().signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => false,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.logout),
                                label: Text(AppLocale.logout.getString(context)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}