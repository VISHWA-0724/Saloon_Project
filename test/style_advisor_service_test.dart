import 'package:flutter_test/flutter_test.dart';
import 'package:salonease/data/services/style_advisor_service.dart';

void main() {
  group('StyleAdvisorService', () {
    test('suggests trendy male styles for young oval wavy input', () {
      final advice = StyleAdvisorService().recommend(
        '24 male oval face wavy hair',
      );

      expect(advice.detectedSummary, contains('Age 24'));
      expect(advice.detectedSummary, contains('Oval face'));
      expect(advice.text, contains('Low Fade'));
      expect(advice.text, contains('Quiff'));
      expect(advice.text, contains('Hair Spa'));
    });

    test('uses structured fields when prompt is empty', () {
      final advice = StyleAdvisorService().recommend(
        '',
        age: 35,
        gender: 'female',
        hairType: 'straight',
        faceShape: 'round',
      );

      expect(advice.detectedSummary, contains('Female'));
      expect(advice.text, contains('Long Layers'));
      expect(advice.text, contains('Salon services'));
    });

    test('responds to greetings without repeating a style recommendation', () {
      final service = StyleAdvisorService();

      final advice = service.recommend('hii');

      expect(advice.detectedSummary, 'Greeting');
      expect(advice.text, contains('Tell me'));
      expect(advice.text, isNot(contains('Recommended for you')));
    });
  });
}
