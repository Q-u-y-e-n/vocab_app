import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/string_utils.dart';
import 'add_word_screen.dart';
import 'auth/login_screen.dart';
import 'vocabulary_detail_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

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

  // --- 1. DIALOG & SHEET ---
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Chọn chủ đề",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
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
                              Icons.folder,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Provider.of<VocabProvider>(
                context,
                listen: false,
              ).deleteVocabulary(vocab.id!, vocab.userId);
              // ignore: use_build_context_synchronously
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  // 1. Header
  Widget _buildHeader(User? user, VocabProvider provider) {
    return Stack(
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xin chào, ${user?.username ?? ''}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Cùng học nào! 🚀",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              // SỬA: Dùng .withOpacity thay vì ..withValues để an toàn
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm từ vựng...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          provider.search("");
                        },
                      )
                    : null,
              ),
              onChanged: (val) => provider.search(val),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Action Card (ĐÃ SỬA LỖI MẤT HÌNH)
  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            // SỬA QUAN TRỌNG: Dùng .withOpacity (1 dấu chấm)
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Topic Chip (ĐÃ SỬA LỖI MÀU CHỮ)
  Widget _buildTopicChip(
    int? id,
    String label,
    VocabProvider provider,
    bool isDark,
  ) {
    bool isSelected = _selectedTopicId == id;

    // Màu chữ khi CHƯA chọn: Nếu Dark mode thì xám nhạt, Light mode thì xám đậm
    Color unselectedTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTopicId = id);
          provider.filterByTopic(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent
                  : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : unselectedTextColor, // Sửa màu chữ
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabProvider = Provider.of<VocabProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    final vocabList = vocabProvider.vocabList;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(user, vocabProvider),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 20),

                // QUICK ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildActionCard(
                        "Flashcard",
                        Icons.style,
                        Colors.indigo,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FlashcardScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      _buildActionCard(
                        "Quiz",
                        Icons.school,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                        ),
                      ),
                      const SizedBox(width: 15),
                      _buildActionCard(
                        "Yêu thích",
                        _showFavoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        Colors.redAccent,
                        () {
                          setState(
                            () => _showFavoritesOnly = !_showFavoritesOnly,
                          );
                          vocabProvider.toggleShowFavorite(_showFavoritesOnly);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // TOPIC BAR (Sửa lỗi hiển thị)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTopicChip(null, "Tất cả", vocabProvider, isDark),
                      ...vocabProvider.topics.map(
                        (t) => _buildTopicChip(
                          t.id,
                          t.name,
                          vocabProvider,
                          isDark,
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                        label: const Text(
                          "Chủ đề",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Sửa background color dùng 1 dấu chấm
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        onPressed: _showAddTopicDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Danh sách từ vựng",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (vocabList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          Icon(Icons.notes, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            "Không có từ vựng nào.",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: vocabList.length,
                    itemBuilder: (context, index) {
                      final vocab = vocabList[index];
                      String phonetic = VocabParser.getPhonetic(vocab.meaning);
                      String vietnamese = VocabParser.getVietnamese(
                        vocab.meaning,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VocabularyDetailScreen(vocabulary: vocab),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // ICON AVATAR (SỬA LỖI MẤT HÌNH)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      // SỬA: Dùng 1 dấu chấm .withOpacity
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      vocab.word.isNotEmpty
                                          ? vocab.word[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vocab.word,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (phonetic.isNotEmpty)
                                          Text(
                                            phonetic,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        Text(
                                          vietnamese,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            vocabProvider.toggleFavorite(vocab),
                                        child: Icon(
                                          vocab.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: vocab.isFavorite
                                              ? Colors.red
                                              : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () =>
                                            _showAddToTopicSheet(vocab),
                                        child: Icon(
                                          Icons.folder_open,
                                          color: vocab.topicId != null
                                              ? Colors.amber
                                              : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () => _confirmDelete(vocab),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Thêm từ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddWordScreen()),
        ),
      ),
    );
  }
}
