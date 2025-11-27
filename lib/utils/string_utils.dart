class VocabParser {
  static String getPhonetic(String fullMeaning) {
    RegExp exp = RegExp(r'/.+/');
    Match? match = exp.firstMatch(fullMeaning);
    return match?.group(0) ?? "";
  }

  static String getVietnamese(String fullMeaning) {
    if (fullMeaning.contains("🇻🇳")) {
      return fullMeaning.split("🇻🇳").last.trim();
    }
    return fullMeaning; // Trả về nguyên gốc nếu k tìm thấy tag
  }
}
