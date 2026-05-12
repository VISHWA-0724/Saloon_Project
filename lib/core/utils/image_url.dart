import '../constants/app_strings.dart';

class ImageUrl {
  static String resolve(
    String? value, {
    String fallback = AppStrings.unsplashHairSalon,
  }) {
    final trimmed = value?.trim() ?? '';
    if (_isUsableUrl(trimmed)) return trimmed;
    return fallback;
  }

  static String first(
    Iterable<String> values, {
    String fallback = AppStrings.unsplashHairSalon,
  }) {
    for (final value in values) {
      final trimmed = value.trim();
      if (_isUsableUrl(trimmed)) return trimmed;
    }
    return fallback;
  }

  static String profile(String? value) {
    return resolve(value, fallback: AppStrings.unsplashProfile);
  }

  static bool _isUsableUrl(String value) {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
