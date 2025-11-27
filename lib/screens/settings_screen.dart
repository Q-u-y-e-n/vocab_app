import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Danh sách màu cho người dùng chọn
  final List<Color> _colors = const [
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.redAccent,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Giao diện Tối/Sáng
          SwitchListTile(
            title: const Text(
              "Giao diện Tối (Dark Mode)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Chuyển đổi giữa nền sáng và tối"),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleTheme(val),
            secondary: Icon(
              settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),

          const Divider(),

          // 2. Cỡ chữ
          ListTile(
            title: const Text(
              "Cỡ chữ hiển thị",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Tỉ lệ: ${(settings.textScale * 100).toInt()}%"),
            leading: const Icon(Icons.text_fields),
          ),
          Slider(
            value: settings.textScale,
            min: 0.8, // Nhỏ nhất 80%
            max: 1.4, // Lớn nhất 140%
            divisions: 6,
            label: "${(settings.textScale * 100).toInt()}%",
            onChanged: (val) => settings.setTextScale(val),
          ),

          const Divider(),

          // 3. Màu sắc Flashcard
          ListTile(
            title: const Text(
              "Màu sắc Flashcard",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Chọn màu nền cho thẻ học từ vựng"),
            leading: const Icon(Icons.palette),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: _colors.map((color) {
              bool isSelected =
                  settings.flashcardColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => settings.setFlashcardColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey..withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          // Demo hiển thị thử
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.flashcardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "Demo Flashcard",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
