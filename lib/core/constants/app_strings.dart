import 'package:flutter/foundation.dart';

class AppStrings {
  static const _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _productionApiBaseUrl =
      'https://vishwam2007-salonease-backend.hf.space';

  static String get apiBaseUrl {
    final configured = _normalizeApiBaseUrl(_definedApiBaseUrl);
    if (configured.isNotEmpty) {
      return configured;
    }
    if (kReleaseMode) {
      return _productionApiBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static String _normalizeApiBaseUrl(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.toLowerCase() != 'huggingface.co') {
      return trimmed;
    }

    final segments = uri.pathSegments;
    final spacesIndex =
        segments.indexWhere((segment) => segment.toLowerCase() == 'spaces');
    if (spacesIndex < 0 || segments.length <= spacesIndex + 2) {
      return trimmed;
    }

    final owner = segments[spacesIndex + 1].toLowerCase();
    final space = segments[spacesIndex + 2].toLowerCase();
    return 'https://$owner-$space.hf.space';
  }

  static const appName = 'SalonEase';
  static const currencySymbol = 'Rs. ';

  static const unsplashHairSalon =
      'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=600';
  static const unsplashSpaFacial =
      'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=600';
  static const unsplashGelNails =
      'https://images.unsplash.com/photo-1607779097040-26e80aa78e66?w=600';
  static const unsplashMakeupArtist =
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=600';
  static const unsplashLuxuryInterior =
      'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=700';
  static const unsplashBeautyInterior =
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1000';
  static const unsplashProfile =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300';
}
