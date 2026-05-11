import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text('Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Header(
            icon: Icons.shield_outlined,
            title: 'Your Privacy Matters',
            subtitle:
                'This app is built to manage your shop records privately and securely. Here is how we handle your data.',
          ),
          SizedBox(height: 24),
          _Section(
            title: '1. Data Storage',
            content:
                'All your data — customer names, phone numbers, debt records, and credit entries — is stored exclusively on the Cloud Server. This app use cloud server, external database, or third-party storage. Your shop records never used for illegal purposes, never sold to advertisers, and never shared with any third parties. You are the sole owner of your data.',
          ),
          _Section(
            title: '2. Encryption',
            content:
                'Your data is encrypted using AES-256 encryption before being saved to local storage. The encryption key is securely stored in your device\'s secure keystore (Android Keystore / iOS Keychain), which is protected by your device\'s hardware security chip. Even if someone accesses your storage directly, they cannot read your data without the key.',
          ),
          _Section(
            title: '3. No Internet Access',
            content:
                'This app does not require an internet connection and does not send any data over the network. There are no analytics libraries, no crash reporting tools, and no advertising SDKs included in this application. What happens in your shop stays in your shop.',
          ),
          _Section(
            title: '4. Personal Information',
            content:
                'This app collects only the information you manually enter — customer names, phone numbers, addresses, debt amounts, credit amounts, and descriptions. This information is used solely to display and manage your shop records. We do not collect, process, or share this information with anyone.',
          ),
          _Section(
            title: '5. Data Deletion',
            content:
                'You are in full control of your data. You can delete individual debt or credit entries, remove customers along with all their records, or uninstall the app entirely to erase all data from your device. There is no backup copy stored anywhere else.',
          ),
          _Section(
            title: '6. Device Security',
            content:
                'Since all data is stored locally, the security of your data depends on the security of your device. We strongly recommend setting a screen lock (PIN, pattern, fingerprint, or face unlock) on your phone to prevent unauthorised access to the app and your shop records.',
          ),
          _Section(
            title: '7. Children\'s Privacy',
            content:
                'This App is intended for use by shop owners and adults managing financial records. The app is not directed at children under the age of 13 and does not knowingly collect any information from minors.',
          ),
          _Section(
            title: '8. Changes to This Policy',
            content:
                'If this privacy policy is updated in a future version of the app, the updated policy will be available within the app itself. Continued use of the app after any changes means you accept the updated policy.',
          ),
          _Section(
            title: '9. Contact',
            content:
                'If you have any questions or concerns about how this App handles your data, please reach out to the developer through the app store listing where you downloaded this app.',
          ),
          SizedBox(height: 16),
          _Footer(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Last updated: May 2026 · Chinthamani Pvt Ltd v1.0.0. All data are stored in secure Cloud Server.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}
