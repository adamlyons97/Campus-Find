import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/api_constants.dart';
import '../models/item_model.dart';

class AiMatchService {
  late final GenerativeModel _model;

  AiMatchService() {
    // We are using gemini-1.5-flash as it is extremely fast and perfect for text comparison
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// Compares a newly reported item against a list of active items from the database
  Future<String?> findPotentialMatch({
    required ItemModel newItem,
    required List<ItemModel> existingItems,
  }) async {
    if (existingItems.isEmpty) return null;

    // 1. Format the existing items into a readable list for the AI
    final itemsListString = existingItems.map((item) {
      return '''
      ID: ${item.itemId}
      Title: ${item.title}
      Description: ${item.description}
      Location: ${item.locationSeen.name}
      ''';
    }).join('\n---\n');

    // 2. Craft the Prompt Instructions
    final prompt = '''
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
    2. If there IS a match, reply with ONLY the ID string of the matched item. Do not include any other text, punctuation, or explanation.
    3. If there is NO confident match, reply with exactly the word "NONE".
    ''';

    try {
      // 3. Send the request to Gemini
      final response = await _model.generateContent([Content.text(prompt)]);
      final aiAnswer = response.text?.trim() ?? 'NONE';

      // 4. Parse the response
      if (aiAnswer == 'NONE' || aiAnswer.isEmpty) {
        return null;
      }
      return aiAnswer; // Returns the itemId of the match!
      
    } catch (e) {
      print('Gemini AI Error: $e');
      return null; // Fail gracefully so the app doesn't crash
    }
  }
}