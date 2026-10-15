import 'package:flutter_test/flutter_test.dart';

import 'package:german_a1/models.dart';

void main() {
  test('answers are compared without case, punctuation and umlaut spelling', () {
    expect(normalizeAnswer('  Wo wohnst du? '), 'wo wohnst du');
    expect(normalizeAnswer('Äpfel'), normalizeAnswer('aepfel'));
    expect(normalizeAnswer('heißt'), normalizeAnswer('heisst'));
  });
}
