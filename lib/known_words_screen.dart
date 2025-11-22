import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

class KnownWordsScreen extends StatefulWidget {
  @override
  _KnownWordsScreenState createState() => _KnownWordsScreenState();
}

class _KnownWordsScreenState extends State<KnownWordsScreen> {
  Map<String, Map<String, String>> allKnownWords = {};
  late FlutterTts flutterTts;
  bool isLoading = true;
  final Map<String, bool> _showTranslations = {};

  final List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _loadAllKnownWords();
  }

  Future<void> _loadAllKnownWords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, Map<String, String>> tempKnownWords = {};

    for (String level in levels) {
      final List<String>? knownWordsList =
          prefs.getStringList('${level}_known_words');

      if (knownWordsList != null && knownWordsList.isNotEmpty) {
        final String fileName = 'assets/$level.txt';
        final String response = await rootBundle.loadString(fileName);
        final List<String> lines = response.split('\n');

        Map<String, String> levelWords = {};
        for (String line in lines) {
          final List<String> parts = line.split('=');
          if (parts.length == 2) {
            String word = parts[0].trim();
            String translation = parts[1].trim();
            if (knownWordsList.contains(word)) {
              levelWords[word] = translation;
              _showTranslations[word] = false;
            }
          }
        }

        if (levelWords.isNotEmpty) {
          tempKnownWords[level] = levelWords;
        }
      }
    }

    setState(() {
      allKnownWords = tempKnownWords;
      isLoading = false;
    });
  }

  Future<void> _removeFromKnown(String word, String level) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? knownWordsList =
        prefs.getStringList('${level}_known_words');

    if (knownWordsList != null) {
      knownWordsList.remove(word);
      await prefs.setStringList('${level}_known_words', knownWordsList);

      setState(() {
        allKnownWords[level]?.remove(word);
        if (allKnownWords[level]?.isEmpty ?? false) {
          allKnownWords.remove(level);
        }
      });

      
    }
  }

  void _toggleTranslation(String word) {
    setState(() {
      _showTranslations[word] = !(_showTranslations[word] ?? false);
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.speak(text);
  }

  int _getTotalKnownWords() {
    int total = 0;
    allKnownWords.forEach((level, words) {
      total += words.length;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalKnown = _getTotalKnownWords();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF11998e),
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, totalKnown),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : totalKnown == 0
                        ? _buildEmptyState()
                        : _buildKnownWordsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int totalKnown) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Known Words',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  '$totalKnown Words Learned',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No known words yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'Start learning and mark words as known!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnownWordsList() {
    List<Widget> levelSections = [];

    allKnownWords.forEach((level, words) {
      levelSections.add(_buildLevelSection(level, words));
    });

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      children: levelSections,
    );
  }

  Widget _buildLevelSection(String level, Map<String, String> words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level $level',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${words.length} words',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ...words.entries.map((entry) {
          return _buildWordCard(entry.key, entry.value, level);
        }).toList(),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildWordCard(String word, String translation, String level) {
    final showTranslation = _showTranslations[word] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _toggleTranslation(word),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Color(0xFF11998e).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          if (showTranslation) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                translation,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            showTranslation
                                ? Icons.translate
                                : Icons.translate_outlined,
                            color: showTranslation
                                ? Color(0xFF667eea)
                                : Colors.grey[600],
                          ),
                          onPressed: () => _toggleTranslation(word),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF4facfe),
                          ),
                          onPressed: () => _speak(word),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: Colors.red[400],
                          ),
                          onPressed: () => _removeFromKnown(word, level),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}