import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-1.5-flash',
    );
    return _model!;
  }

  static Future<List<String>> generateBookTitles(String description) async {
    try {
      if (description.trim().isEmpty) {
        return [];
      }

      final prompt = '''
Generate 5 creative and engaging book titles based on this description: "$description"

Requirements:
- Make them catchy and marketable
- Keep them concise (under 60 characters each)
- Make them genre-appropriate
- Ensure they capture the essence of the story
- Return only the titles, one per line
- No numbering or bullet points
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null) {
        final titles = response.text!
            .split('\n')
            .where((title) => title.trim().isNotEmpty)
            .map((title) => title.trim())
            .where((title) => title.isNotEmpty && !title.startsWith('-') && !RegExp(r'^\d+\.').hasMatch(title))
            .take(5)
            .toList();

        return titles;
      }

      return [];
    } catch (e) {
      print('Error generating titles: $e');
      return [];
    }
  }
}