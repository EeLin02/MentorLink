import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeNotifier extends ChangeNotifier {
  double _fontSize = 16.0;

  double get fontSize => _fontSize;

  FontSizeNotifier() {
    _loadFontSize();
  }

  setFontSize(double size) {
    _fontSize = size;
    _saveFontSize(size);
    notifyListeners();
  }

  _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    notifyListeners();
  }

  _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', size);
  }
}
