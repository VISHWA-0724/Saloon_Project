class StyleAdvisorService {
  int _greetingTurn = 0;

  StyleAdvice welcome() {
    return const StyleAdvice(
      text:
          'Tell me your age, gender, hair type, and face shape. I will suggest haircut, beard, and salon service ideas that fit.',
      detectedSummary: 'Ready',
    );
  }

  StyleAdvice recommend(
    String prompt, {
    int? age,
    String? gender,
    String? hairType,
    String? faceShape,
  }) {
    final lower = prompt.toLowerCase();
    final parsedAge = age ?? _parseAge(lower);
    final parsedGender =
        _normalizeOption(gender) ?? _parseOption(lower, _genderTerms);
    final parsedHair =
        _normalizeOption(hairType) ?? _parseOption(lower, _hairTerms);
    final parsedFace =
        _normalizeOption(faceShape) ?? _parseOption(lower, _faceTerms);

    if (_isGreeting(lower)) {
      return _greetingReply();
    }

    if (prompt.trim().isEmpty &&
        parsedAge == null &&
        parsedGender == null &&
        parsedHair == null &&
        parsedFace == null) {
      return const StyleAdvice(
        text:
            'Share a few details first: age, gender, hair type, and face shape.',
        detectedSummary: 'Need details',
      );
    }

    if (parsedAge == null &&
        parsedGender == null &&
        parsedHair == null &&
        parsedFace == null) {
      return StyleAdvice(
        text: _nextDetailReply(prompt),
        detectedSummary: 'Need style details',
      );
    }

    final isFeminine = parsedGender == 'female' || parsedGender == 'woman';
    final styles = <String>{};
    final beard = <String>{};
    final services = <String>{};
    final reasons = <String>[];

    _addAgeIdeas(parsedAge, isFeminine, styles, beard, services, reasons);
    _addFaceIdeas(parsedFace, isFeminine, styles, beard, reasons);
    _addHairIdeas(parsedHair, styles, services, reasons);

    if (styles.isEmpty) {
      styles.addAll(isFeminine
          ? const ['Soft Layers', 'Curtain Bangs', 'Blowout Styling']
          : const ['Textured Crop', 'Low Fade', 'Side Part']);
      reasons.add(
          'A balanced starter set works well until face shape and hair type are known.');
    }
    if (!isFeminine && beard.isEmpty) {
      beard.addAll(const ['Clean Line-up', 'Short Boxed Beard']);
    }
    if (services.isEmpty) {
      services.addAll(const ['Haircut Consultation', 'Wash and Styling']);
    }

    final summary = _summary(
      age: parsedAge,
      gender: parsedGender,
      hairType: parsedHair,
      faceShape: parsedFace,
    );

    final buffer = StringBuffer()
      ..writeln('Recommended for you:')
      ..writeln(_bulletList(styles.take(4)))
      ..writeln()
      ..writeln(isFeminine ? 'Styling add-ons:' : 'Beard and grooming:')
      ..writeln(_bulletList((isFeminine ? services : beard).take(3)))
      ..writeln()
      ..writeln('Salon services:')
      ..writeln(_bulletList(services.take(3)));

    if (reasons.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Why this fits:')
        ..writeln(_bulletList(reasons.take(3)));
    }

    return StyleAdvice(
      text: buffer.toString().trim(),
      detectedSummary: summary,
    );
  }

  bool _isGreeting(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^a-z\s]'), '').trim();
    return RegExp(r'^(hi+|hey+|hello+|vanakkam|hlo|hai+)$').hasMatch(cleaned);
  }

  StyleAdvice _greetingReply() {
    const replies = [
      'Hi! Tell me your age, hair type, and face shape. I will suggest a haircut and salon service that actually fits you.',
      'Hello! I can help you pick a look. Share details like “24 male oval face wavy hair” or choose the profile fields above.',
      'Hey there. Want a sharp recommendation? Send your age, gender, hair type, and face shape, then I will narrow it down.',
    ];
    final text = replies[_greetingTurn % replies.length];
    _greetingTurn += 1;
    return StyleAdvice(text: text, detectedSummary: 'Greeting');
  }

  String _nextDetailReply(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return 'Share a few details first: age, gender, hair type, and face shape.';
    }
    return 'I can help with that. To make it personal, send your age, gender, hair type, and face shape. Example: “24 male oval face wavy hair”.';
  }

  static const _genderTerms = {
    'male': ['male', 'man', 'men', 'boy', 'guy'],
    'female': ['female', 'woman', 'women', 'girl', 'lady'],
  };

  static const _hairTerms = {
    'straight': ['straight'],
    'wavy': ['wavy', 'wave'],
    'curly': ['curly', 'curl'],
    'coily': ['coily', 'kinky'],
    'thick': ['thick', 'dense'],
    'thin': ['thin', 'fine', 'flat'],
    'dry': ['dry', 'frizzy'],
    'oily': ['oily', 'greasy'],
  };

  static const _faceTerms = {
    'round': ['round'],
    'oval': ['oval'],
    'square': ['square'],
    'heart': ['heart'],
    'diamond': ['diamond'],
    'long': ['long', 'oblong', 'rectangular'],
  };

  int? _parseAge(String text) {
    for (final match in RegExp(r'\b(\d{2})\b').allMatches(text)) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= 10 && value <= 80) return value;
    }
    return null;
  }

  String? _parseOption(String text, Map<String, List<String>> terms) {
    for (final entry in terms.entries) {
      for (final alias in entry.value) {
        if (RegExp('\\b$alias\\b').hasMatch(text)) return entry.key;
      }
    }
    return null;
  }

  String? _normalizeOption(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _addAgeIdeas(
    int? age,
    bool isFeminine,
    Set<String> styles,
    Set<String> beard,
    Set<String> services,
    List<String> reasons,
  ) {
    if (age == null) return;
    if (age <= 17) {
      styles.addAll(isFeminine
          ? const ['Layered Lob', 'Soft Waves']
          : const ['Textured Fringe', 'Low Taper']);
      services.addAll(const ['Wash and Styling', 'Hair Spa']);
      reasons.add('Younger styles should stay fresh but easy to maintain.');
    } else if (age <= 25) {
      styles.addAll(isFeminine
          ? const ['Butterfly Layers', 'Curtain Bangs', 'Glossy Blowout']
          : const ['Low Fade', 'Textured Crop', 'Messy Quiff']);
      beard.addAll(const ['Light Stubble', 'Sharp Beard Line-up']);
      services.addAll(const ['Hair Spa', 'Texture Styling']);
      reasons.add(
          'The 18-25 range can carry trendier texture, fades, and movement.');
    } else if (age <= 35) {
      styles.addAll(isFeminine
          ? const ['Long Layers', 'Face-framing Layers', 'Sleek Blowout']
          : const ['Taper Fade', 'Side Part', 'Modern Pompadour']);
      beard.addAll(const ['Short Boxed Beard', 'Beard Styling']);
      services.addAll(const ['Scalp Cleanse', 'Haircut Consultation']);
      reasons.add(
          'The 26-35 range usually looks best with polished, work-ready structure.');
    } else {
      styles.addAll(isFeminine
          ? const ['Soft Layers', 'Classic Bob', 'Volume Blowout']
          : const ['Classic Taper', 'Crew Cut', 'Ivy League']);
      beard.addAll(const ['Neat Full Beard', 'Salt-and-pepper Blend']);
      services.addAll(const ['Hair Spa', 'Scalp Treatment']);
      reasons.add('Classic shapes stay sharp and easy to style after 35.');
    }
  }

  void _addFaceIdeas(
    String? faceShape,
    bool isFeminine,
    Set<String> styles,
    Set<String> beard,
    List<String> reasons,
  ) {
    switch (faceShape) {
      case 'round':
        styles.addAll(isFeminine
            ? const ['Long Layers', 'Side Part', 'Layered Lob']
            : const ['High-volume Quiff', 'Angular Fringe', 'Mid Fade']);
        beard.addAll(const ['Boxed Beard', 'Defined Jaw Line-up']);
        reasons
            .add('Round faces benefit from height on top and cleaner sides.');
        break;
      case 'oval':
        styles.addAll(isFeminine
            ? const ['Soft Waves', 'Curtain Bangs', 'Blunt Bob']
            : const ['Pompadour', 'Quiff', 'Fade Cut']);
        beard.addAll(const ['Light Stubble', 'Balanced Beard Shape']);
        reasons.add(
            'Oval faces are flexible, so both volume and clean fades work well.');
        break;
      case 'square':
        styles.addAll(isFeminine
            ? const ['Soft Layers', 'Side-swept Fringe', 'Loose Waves']
            : const ['Textured Crop', 'Side Part', 'Classic Taper']);
        beard.addAll(const ['Short Boxed Beard', 'Rounded Beard Edges']);
        reasons.add('Square faces suit softer edges with controlled texture.');
        break;
      case 'heart':
        styles.addAll(isFeminine
            ? const ['Curtain Bangs', 'Collarbone Layers', 'Soft Curls']
            : const ['Side-swept Fringe', 'Medium Taper', 'Textured Top']);
        beard.addAll(const ['Chin-focused Beard', 'Light Stubble']);
        reasons.add(
            'Heart faces look balanced when the lower face gets a little visual weight.');
        break;
      case 'diamond':
        styles.addAll(isFeminine
            ? const ['Chin-length Bob', 'Side Part', 'Soft Waves']
            : const ['Textured Fringe', 'Side Part', 'Medium Length Top']);
        beard.addAll(const ['Short Beard', 'Natural Jaw Blend']);
        reasons
            .add('Diamond faces benefit from width near the forehead and jaw.');
        break;
      case 'long':
        styles.addAll(isFeminine
            ? const ['Full Fringe', 'Shoulder Layers', 'Side Volume Waves']
            : const ['Crew Cut', 'Side Fringe', 'Low Taper']);
        beard.addAll(const ['Fuller Beard', 'Short Rounded Beard']);
        reasons.add(
            'Long faces should avoid too much height and add some side balance.');
        break;
    }
  }

  void _addHairIdeas(
    String? hairType,
    Set<String> styles,
    Set<String> services,
    List<String> reasons,
  ) {
    switch (hairType) {
      case 'straight':
        styles.addAll(const ['Textured Crop', 'Side Part']);
        services.add('Matte Texture Styling');
        reasons.add(
            'Straight hair needs texture so the shape does not look flat.');
        break;
      case 'wavy':
        styles.addAll(const ['Layered Quiff', 'Natural Waves']);
        services.add('Curl Cream Styling');
        reasons.add(
            'Wavy hair looks best when the natural movement is shaped, not hidden.');
        break;
      case 'curly':
      case 'coily':
        styles.addAll(const ['Curly Fade', 'Tapered Curls']);
        services.add('Curl Definition Treatment');
        reasons.add(
            'Curly hair needs controlled sides and moisture-friendly styling.');
        break;
      case 'thick':
        styles.addAll(const ['Undercut', 'Layered Taper']);
        services.add('Weight Reduction Cut');
        reasons.add(
            'Thick hair benefits from removing weight while keeping shape.');
        break;
      case 'thin':
        styles.addAll(const ['Short Quiff', 'French Crop']);
        services.add('Volumizing Blow-dry');
        reasons.add(
            'Fine hair looks fuller with shorter texture and light products.');
        break;
      case 'dry':
        services.addAll(const ['Hair Spa', 'Hydration Treatment']);
        reasons.add('Dry hair needs moisture before heavy styling.');
        break;
      case 'oily':
        services.addAll(const ['Scalp Cleanse', 'Lightweight Styling']);
        reasons.add(
            'Oily hair works better with lighter products and clean volume.');
        break;
    }
  }

  String _summary({
    required int? age,
    required String? gender,
    required String? hairType,
    required String? faceShape,
  }) {
    final parts = <String>[
      if (age != null) 'Age $age',
      if (gender != null) _title(gender),
      if (hairType != null) '${_title(hairType)} hair',
      if (faceShape != null) '${_title(faceShape)} face',
    ];
    return parts.isEmpty ? 'General recommendation' : parts.join(' | ');
  }

  String _bulletList(Iterable<String> items) {
    return items.map((item) => '- $item').join('\n');
  }

  String _title(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class StyleAdvice {
  final String text;
  final String detectedSummary;

  const StyleAdvice({
    required this.text,
    required this.detectedSummary,
  });
}
