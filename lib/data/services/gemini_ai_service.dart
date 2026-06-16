import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/item_model.dart';

/// Result of a single AI match suggestion.
class AiMatch {
  final String itemId;
  final int confidence; // 0–100
  final String reason;

  const AiMatch({
    required this.itemId,
    required this.confidence,
    required this.reason,
  });
}

/// Wraps the Google Gemini SDK to power the "AI-Powered Smart Match"
/// (Feature 6.3 / Objective 4.2). It compares a query item against a set of
/// candidate listings and returns ranked matches.
///
/// The API key is injected via a Riverpod provider so it is never hard-coded
/// in widgets. See SETUP.md for how to supply it with `--dart-define`.
class GeminiAiService {
  GeminiAiService(this._apiKey);

  final String _apiKey;

  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns matches ranked by confidence (highest first).
  ///
  /// [query] is the newly reported item; [candidates] are the opposite-type
  /// active listings to compare against (e.g. a new LOST item vs all FOUND).
  Future<List<AiMatch>> findMatches({
    required ItemModel query,
    required List<ItemModel> candidates,
  }) async {
    if (!isConfigured || candidates.isEmpty) return const [];

    final candidateBlock = candidates
        .map((c) => '- id: ${c.id}\n  text: ${c.toMatchableText()}')
        .join('\n');

    final prompt = '''
You are the matching engine for a university lost-and-found app called CampusFind.
A user reported this item:
"${query.toMatchableText()}"

Compare it against these candidate listings:
$candidateBlock

Return ONLY a JSON array (no markdown, no prose). Each element:
{"itemId": "<id>", "confidence": <0-100 integer>, "reason": "<short reason>"}

Include only candidates with confidence >= 40, sorted by confidence descending.
Consider item type, category, colour, brand, distinctive features and location.
If nothing matches, return [].
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final raw = response.text?.trim() ?? '[]';
    return _parse(raw);
  }

  List<AiMatch> _parse(String raw) {
    try {
      // Strip accidental code fences just in case.
      final cleaned =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => AiMatch(
                itemId: m['itemId']?.toString() ?? '',
                confidence: (m['confidence'] as num?)?.toInt() ?? 0,
                reason: m['reason']?.toString() ?? '',
              ))
          .where((m) => m.itemId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Holds the Gemini API key. Default is read from a compile-time environment
/// variable so it stays out of source control.
final geminiApiKeyProvider = Provider<String>(
  (ref) => const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
);

final geminiAiServiceProvider = Provider<GeminiAiService>(
  (ref) => GeminiAiService(ref.watch(geminiApiKeyProvider)),
);
