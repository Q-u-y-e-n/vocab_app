import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_model.dart';
import '../providers/auth_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/string_utils.dart';
import 'add_word_screen.dart';
import 'auth/login_screen.dart';
import 'vocabulary_detail_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart'; // Import trang cài đặt

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoritesOnly = false;
  int? _selectedTopicId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user != null) {
        Provider.of<VocabProvider>(context, listen: false).loadData(user.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DIALOG & SHEET ---
  void _showAddTopicDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo Chủ Đề Mới"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Ví dụ: Toeic..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final user = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).currentUser;
                Provider.of<VocabProvider>(
                  context,
                  listen: false,
                ).addTopic(nameController.text.trim(), user!.id!);
                Navigator.pop(context);
              }
            },
            child: const Text("Tạo"),
          ),
        ],
      ),
    );
  }

  void _showAddToTopicSheet(Vocabulary vocab) {
    final provider = Provider.of<VocabProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  "Chọn chủ đề",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (provider.topics.isEmpty)
                          const Text(
                            "Chưa có chủ đề nào.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ...provider.topics.map(
                          (topic) => ListTile(
                            leading: const Icon(
                              Icons.folder_open,
                              color: Colors.amber,
                            ),
                            title: Text(topic.name),
                            trailing: vocab.topicId == topic.id
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () {
                              provider.updateVocabulary(
                                vocab.copyWith(topicId: topic.id),
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Đã chuyển vào: ${topic.name}"),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add, color: Colors.blue),
                          title: const Text(
                            "Tạo chủ đề mới",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showAddTopicDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Vocabulary vocab) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa từ vựng?"),
        content: Text("Bạn có chắc muốn xóa '${vocab.word}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await Provider.of<VocabProvider>(
                context,
                listen: false,
              ).deleteVocabulary(vocab.id!, vocab.userId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabProvider = Provider.of<VocabProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    final vocabList = vocabProvider.vocabList;

    // Kiểm tra DarkMode để chỉnh màu icon
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Màu nền lấy từ Theme (đã cấu hình ở main.dart theo SettingsProvider)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm kiếm...",
            hintStyle: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[600],
            ),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      vocabProvider.search("");
                    },
                  )
                : null,
          ),
          onChanged: (val) => vocabProvider.search(val),
        ),
        actions: [
          // Nút Cài đặt (Mới)
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // --- TOPICS ---
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text("Tất cả"),
                  selected: _selectedTopicId == null,
                  onSelected: (val) {
                    setState(() => _selectedTopicId = null);
                    vocabProvider.filterByTopic(null);
                  },
                ),
                const SizedBox(width: 8),
                ...vocabProvider.topics.map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(topic.name),
                      selected: _selectedTopicId == topic.id,
                      onSelected: (val) {
                        setState(() => _selectedTopicId = topic.id);
                        vocabProvider.filterByTopic(topic.id);
                      },
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text("Chủ đề"),
                  onPressed: _showAddTopicDialog,
                ),
              ],
            ),
          ),

          // --- TOOLS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.style, size: 18),
                    label: const Text("Flashcard"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FlashcardScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.quiz, size: 18),
                    label: const Text("Quiz"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                    vocabProvider.toggleShowFavorite(_showFavoritesOnly);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // --- LIST ---
          Expanded(
            child: vocabList.isEmpty
                ? Center(
                    child: Text(
                      "Không tìm thấy từ vựng nào.",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vocabList.length,
                    itemBuilder: (context, index) {
                      final vocab = vocabList[index];
                      String phonetic = VocabParser.getPhonetic(vocab.meaning);
                      String vietnamese = VocabParser.getVietnamese(
                        vocab.meaning,
                      );

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VocabularyDetailScreen(vocabulary: vocab),
                            ),
                          ),
                          title: Text(
                            vocab.word,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blueAccent,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (phonetic.isNotEmpty)
                                Text(
                                  phonetic,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                vietnamese,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.folder_open,
                                  color: vocab.topicId != null
                                      ? Colors.amber
                                      : Colors.grey[400],
                                ),
                                onPressed: () => _showAddToTopicSheet(vocab),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  vocab.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    vocabProvider.toggleFavorite(vocab),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _confirmDelete(vocab),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddWordScreen()),
        ),
      ),
    );
  }
}
