import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class DictionaryData {
  final String word;
  final String phonetic;
  final String engMeaning;
  final String vieMeaning;
  final String example;

  DictionaryData({
    required this.word,
    required this.phonetic,
    required this.engMeaning,
    required this.vieMeaning,
    required this.example,
  });
}

class DictionaryService {
  final GoogleTranslator _translator = GoogleTranslator();

  // 1. Gợi ý từ (Datamuse API) - Giữ nguyên
  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse('https://api.datamuse.com/sug?s=$query&max=5');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e['word'] as String).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      // ignore: avoid_print
      print("Error suggestions: $e");
    }
    return [];
  }

  // 2. HÀM MỚI: Lấy câu ví dụ từ nguồn dự phòng (Datamuse)
  Future<String> _fetchFallbackExample(String word) async {
    // md=e nghĩa là lấy metadata example
    final url = Uri.parse('https://api.datamuse.com/words?sp=$word&md=e&max=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['examples'] != null) {
          List<dynamic> examples = data[0]['examples'];
          if (examples.isNotEmpty) {
            // Datamuse trả về dạng: "Example sentence."
            return examples[0];
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Fallback example error: $e");
    }
    return "";
  }

  // 3. Lấy chi tiết từ vựng (Dictionary API + Fallback)
  Future<DictionaryData?> fetchWordDetails(String query) async {
    if (query.isEmpty) return null;
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$query',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entry = data[0];

        // --- A. Lấy Phiên âm ---
        String phonetic = entry['phonetic'] ?? '';
        if (phonetic.isEmpty && entry['phonetics'] != null) {
          for (var p in entry['phonetics']) {
            if (p['text'] != null && (p['text'] as String).isNotEmpty) {
              phonetic = p['text'];
              break;
            }
          }
        }

        // --- B. Lấy Nghĩa Anh ---
        String engDef = '';
        if (entry['meanings'] != null && entry['meanings'].isNotEmpty) {
          // Ưu tiên lấy định nghĩa ngắn gọn nhất
          engDef = entry['meanings'][0]['definitions'][0]['definition'] ?? '';
        }

        // --- C. Lấy Ví dụ (Logic Nâng cao) ---
        String example = '';
        // C1. Tìm trong DictionaryAPI trước
        if (entry['meanings'] != null) {
          for (var meaning in entry['meanings']) {
            for (var def in meaning['definitions']) {
              if (def['example'] != null &&
                  (def['example'] as String).isNotEmpty) {
                example = def['example'];
                break;
              }
            }
            if (example.isNotEmpty) break;
          }
        }

        // C2. Nếu DictionaryAPI không có ví dụ -> Gọi Datamuse lấy dự phòng
        if (example.isEmpty) {
          example = await _fetchFallbackExample(query);
        }

        // --- D. Dịch sang Tiếng Việt ---
        String vieDef = "";
        if (engDef.isNotEmpty) {
          try {
            var translation = await _translator.translate(
              engDef,
              from: 'en',
              to: 'vi',
            );
            vieDef = translation.text;
          } catch (e) {
            // ignore: avoid_print
            print("Translation error: $e");
          }
        }

        return DictionaryData(
          word: entry['word'],
          phonetic: phonetic,
          engMeaning: engDef,
          vieMeaning: vieDef,
          example: example,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error details: $e");
    }
    return null;
  }
}
