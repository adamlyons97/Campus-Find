import 'dart:developer' as developer;

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/item_model.dart';

final aiMatchServiceProvider = Provider<AiMatchService>((ref) {
  return AiMatchService();
});

class AiMatchService {
  late final GenerativeModel _model;

  AiMatchService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  Future<String?> findPotentialMatch({
    required ItemModel newItem,
    required List<ItemModel> existingItems,
  }) async {
    if (existingItems.isEmpty) return null;

    final itemsListString = existingItems
        .map((item) {
          return '''
      ID: ${item.itemId}
      Title: ${item.title}
      Description: ${item.description}
      Location: ${item.locationSeen.name}
      ''';
        })
        .join('\n---\n');

    final prompt =
        '''
    You are an intelligent matching assistant for a university Lost & Found app.
    A user just reported a NEW item:
    Type: ${newItem.type}
    Title: ${newItem.title}
    Description: ${newItem.description}
    Category: ${newItem.categoryName}
    Location: ${newItem.locationSeen.name} - ${newItem.locationSeen.specificDetails}

    Here is a list of active items of the OPPOSITE type currently in the database:
    $itemsListString

    Your task is to analyze the descriptions, categories, and locations. Determine if there is a highly probable match between the NEW item and any of the items in the list.
    
    RULES:
    1. Only consider matches where you are 80% or more confident.
    2. If there IS a match, reply with ABSOLUTELY NOTHING EXCEPT the ID string of the matched item.
    3. If there is NO confident match, reply with exactly the word "NONE".
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String aiAnswer = response.text ?? 'NONE';

      // --- AGGRESSIVE SANITIZATION ENGINE ---
      // 1. Check if the AI decided there is no match
      if (aiAnswer.toUpperCase().contains('NONE') || aiAnswer.isEmpty) {
        return null;
      }

      // 2. Strip away common extra characters LLMs try to add (quotes, markdown, labels)
      aiAnswer = aiAnswer
          .replaceAll(RegExp(r'(ID:|-|\*|`|"|\\|\n|id:)'), '')
          .trim();

      // 3. Extract exactly the alphanumeric Firebase ID (usually 20 characters)
      final idRegex = RegExp(r'[a-zA-Z0-9]{15,30}');
      final match = idRegex.firstMatch(aiAnswer);

      if (match != null) {
        return match.group(0); // Safely returns JUST the pure ID
      }

      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Gemini AI request failed',
        name: 'campus_find.ai_match',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
