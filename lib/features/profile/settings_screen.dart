import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          _Section(title: 'Preferences', children: [
            _SwitchTile(
              icon: IconlyLight.show,
              title: 'Appearance',
              subtitle: theme.isDarkMode ? 'Dark' : 'Light',
              value: theme.isDarkMode,
              onChanged: (_) =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
            ),
            _SelectTile(
              icon: IconlyLight.document,
              title: 'Language',
              subtitle: 'English',
              onTap: () => _snack(context, 'Language selector UI placeholder.'),
            ),
            _SwitchTile(
              icon: IconlyLight.notification,
              title: 'Notifications',
              subtitle: 'Booking alerts & offers',
              value: true,
              onChanged: (_) =>
                  _snack(context, 'Notification prefs placeholder.'),
            ),
          ]),
          _Section(title: 'Security & Payment', children: [
            _SwitchTile(
              icon: IconlyLight.lock,
              title: 'Face ID',
              subtitle: 'Enable biometric lock',
              value: false,
              onChanged: (_) => _snack(context, 'Biometrics placeholder.'),
            ),
            _SelectTile(
              icon: IconlyLight.location,
              title: 'Saved Addresses',
              subtitle: 'Manage addresses',
              onTap: () => _snack(context, 'Addresses placeholder.'),
            ),
            _SelectTile(
              icon: IconlyLight.wallet,
              title: 'Payment Methods',
              subtitle: 'Cards / UPI',
              onTap: () => _snack(context, 'Payments placeholder.'),
            ),
          ]),
          _Section(title: 'About', children: [
            _SelectTile(
              icon: Icons.info_outline,
              title: 'Privacy Policy',
              subtitle: 'Open external link',
              onTap: () => _snack(context, 'Add url_launcher to open links.'),
            ),
            _SelectTile(
              icon: IconlyLight.document,
              title: 'Terms of Service',
              subtitle: 'Open external link',
              onTap: () => _snack(context, 'Add url_launcher to open links.'),
            ),
            _SelectTile(
              icon: IconlyLight.delete,
              title: 'Clear Cache',
              subtitle: 'Cached images: ~18 MB',
              onTap: () => _snack(context,
                  'Cache clear placeholder (can wire to imageCache/CacheManager).'),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(IconlyBold.danger, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delete Account',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger)),
                      const SizedBox(height: 4),
                      Text('This action is irreversible.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _snack(context, 'Delete account endpoint not wired.'),
                  child: const Text('Delete',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w900)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        activeThumbColor: AppColors.primaryPurple,
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SelectTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.withValues(alpha: 0.6)),
      ),
    );
  }
}
