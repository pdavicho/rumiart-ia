import 'package:flutter_test/flutter_test.dart';
import 'package:museum_vision_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('aiBackendUrl has a valid default value', () {
      expect(AppConstants.aiBackendUrl, isNotEmpty);
      expect(AppConstants.aiBackendUrl, startsWith('https://'));
    });

    test('mlConfidenceThreshold is within valid range', () {
      expect(AppConstants.mlConfidenceThreshold, greaterThan(0));
      expect(AppConstants.mlConfidenceThreshold, lessThan(256));
    });

    test('mlInputSize is positive', () {
      expect(AppConstants.mlInputSize, greaterThan(0));
    });

    test('Firestore collection names are not empty', () {
      expect(AppConstants.artworksCollection, isNotEmpty);
      expect(AppConstants.recognitionLogsCollection, isNotEmpty);
    });

    test('Hive box names are not empty', () {
      expect(AppConstants.historyBox, isNotEmpty);
      expect(AppConstants.favoritesBox, isNotEmpty);
    });

    test('maxHistoryEntries is positive', () {
      expect(AppConstants.maxHistoryEntries, greaterThan(0));
    });
  });
}
