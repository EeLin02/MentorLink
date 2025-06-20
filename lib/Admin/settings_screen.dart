import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme_notifier.dart';
import '../font_size_notifier.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final fontSizeNotifier = Provider.of<FontSizeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: Text("Enable Notifications"),
              subtitle: Text("Toggle app notifications on/off"),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            SwitchListTile(
              title: Text("Dark Mode"),
              subtitle: Text("Switch between light and dark themes"),
              value: themeNotifier.isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme(value);
              },
            ),
            ListTile(
              title: Text("Font Size (${fontSizeNotifier.fontSize.toInt()})"),
              subtitle: Slider(
                min: 12,
                max: 24,
                divisions: 6,
                value: fontSizeNotifier.fontSize,
                label: fontSizeNotifier.fontSize.toInt().toString(),
                onChanged: (value) {
                  fontSizeNotifier.setFontSize(value);
                },
              ),
            ),
            Divider(height: 40, thickness: 1),
            ListTile(
              title: Text("About"),
              subtitle: Text("Learn more about this app"),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Edu Mentor",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2025 Edu Mentor Inc.",
                );
              },
            ),
            ListTile(
              title: Text("Privacy Policy"),
              onTap: () {
                _showLegalDialog("Privacy Policy", """
This is the privacy policy of the Edu Mentor app. We value your privacy and do not share your personal information with third parties.
""");
              },
            ),
            ListTile(
              title: Text("Terms of Use"),
              onTap: () {
                _showLegalDialog("Terms of Use", """
By using this app, you agree to the terms and conditions set forth by Edu Mentor. Use the app responsibly.
""");
              },
            ),
          ],
        ),
      ),
    );
  }
}
