import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class VocabularyScreen extends StatefulWidget {
  final String level;
  VocabularyScreen({required this.level});

  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  Map<String, String> allWords = {};
  Map<String, String> displayWords = {};
  bool isShuffled = false;
  final Map<String, bool> _showTranslations = {};
  final Map<String, bool> _knownWords = {};
  final Map<String, bool> _removingWords = {}; // Track words being removed
  late FlutterTts flutterTts;
  bool isLoading = true;
  late AnimationController _animationController;

  final Map<String, List<Color>> levelColors = {
    'A1': [Color(0xFF11998e), Color(0xFF38ef7d)],
    'A2': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    'B1': [Color(0xFFfa709a), Color(0xFFfee140)],
    'B2': [Color(0xFFf093fb), Color(0xFFf5576c)],
    'C1': [Color(0xFF667eea), Color(0xFF764ba2)],
  };

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _loadWords();
    _loadKnownWords();
  }

  Future<void> _loadWords() async {
    final String fileName = 'assets/${widget.level}.txt';
    final String response = await rootBundle.loadString(fileName);
    final List<String> lines = response.split('\n');
    final Map<String, String> tempWords = {};
    for (String line in lines) {
      final List<String> parts = line.split('=');
      if (parts.length == 2) {
        tempWords[parts[0].trim()] = parts[1].trim();
      }
    }
    setState(() {
      allWords = tempWords;
      _updateDisplayWords();
      _showTranslations.addAll(
          Map.fromIterable(allWords.keys, key: (k) => k, value: (v) => false));
      isLoading = false;
    });
    _animationController.forward();
  }

  void _updateDisplayWords() {
    Map<String, String> filtered = {};
    allWords.forEach((key, value) {
      if (!(_knownWords[key] ?? false)) {
        filtered[key] = value;
      }
    });
    setState(() {
      displayWords = filtered;
    });
  }

  Future<void> _loadKnownWords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? knownWordsList =
        prefs.getStringList('${widget.level}_known_words');
    if (knownWordsList != null) {
      setState(() {
        for (String word in knownWordsList) {
          _knownWords[word] = true;
        }
      });
      _updateDisplayWords();
    }
  }

  Future<void> _saveKnownWords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> knownWordsList = _knownWords.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    await prefs.setStringList('${widget.level}_known_words', knownWordsList);
  }

  void _toggleTranslation(String word) {
    setState(() {
      _showTranslations[word] = !(_showTranslations[word] ?? false);
    });
  }

  // _toggleKnown fonksiyonunu bu şekilde güncelle (Animasyon mantığı değişti)
  void _toggleKnown(String word) async {
    if (_knownWords[word] == true) {
      // Eğer zaten biliniyorsa geri al
      setState(() {
        _knownWords[word] = false;
        _removingWords.remove(word); // Garanti olsun diye temizle
      });
      _saveKnownWords();
      _updateDisplayWords();
    } else {
      // Biliniyor olarak işaretle
      setState(() {
        _knownWords[word] = true;
        _removingWords[word] = true; // Konfeti modunu aç
      });
      _saveKnownWords();
      
      // 1.5 saniye bekle (Kullanıcı konfetiyi görsün)
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Animasyon bitti, listeden kaldır
      if (mounted) {
        setState(() {
          _removingWords.remove(word);
        });
        _updateDisplayWords(); // Kelimeyi ekrandan tamamen sil
      }
    }
  }

  void _toggleShuffle() {
    setState(() {
      isShuffled = !isShuffled;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = levelColors[widget.level]!;
    final knownCount = _knownWords.values.where((v) => v).length;
    final totalWords = allWords.length;
    final percentage = totalWords > 0 ? (knownCount / totalWords * 100) : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors[0],
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, knownCount, totalWords, percentage, colors),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(colors[0]),
                        ),
                      )
                    : displayWords.isEmpty
                        ? _buildEmptyState()
                        : _buildWordList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int knownCount, int totalWords,
      double percentage, List<Color> colors) {
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
                child: Column(
                  children: [
                    Text(
                      'Level ${widget.level}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '$knownCount / $totalWords words learned',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffled ? Colors.yellow : Colors.white,
                  size: 28,
                ),
                onPressed: _toggleShuffle,
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${displayWords.length} words remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
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
            Icons.celebration_rounded,
            size: 80,
            color: Colors.amber,
          ),
          SizedBox(height: 20),
          Text(
            'Congratulations!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'You\'ve learned all words in Level ${widget.level}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    var wordEntries = displayWords.entries.toList();
    
    if (isShuffled) {
      wordEntries.shuffle(Random());
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemCount: wordEntries.length,
          itemBuilder: (context, index) {
            final entry = wordEntries[index];
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / wordEntries.length) * 0.5,
                  ((index + 1) / wordEntries.length) * 0.5 + 0.5,
                  curve: Curves.easeOut,
                ),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildWordCard(entry.key, entry.value),
              ),
            );
          },
        );
      },
    );
  }

 // BU WIDGET'I KOMPLE DEĞİŞTİRİN
  Widget _buildWordCard(String word, String translation) {
    final showTranslation = _showTranslations[word] ?? false;
    final isRemoving = _removingWords[word] ?? false; // Konfeti modu açık mı?

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      // Dış Kutu Tasarımı (Sabit kalır)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          // Silinirken çerçeve rengi yeşile dönsün
          color: isRemoving ? Color(0xFF38ef7d) : Colors.grey.withOpacity(0.2),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // İçerik Değiştirici (AnimatedSwitcher)
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 600),
        // Geçiş animasyonu: Yeni gelen içerik büyüyerek (Scale) ve netleşerek (Fade) gelir
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        // Hangi içeriğin gösterileceğini seçiyoruz
        child: isRemoving
            ? _buildCelebrationContent() // DURUM 2: Konfeti Modu
            : _buildNormalContent(word, translation, showTranslation, isRemoving), // DURUM 1: Normal Mod
      ),
    );
  }

  // YENİ: Konfeti İçeriği Görünümü
  Widget _buildCelebrationContent() {
    return Container(
      // AnimatedSwitcher'ın farkı anlaması için Key veriyoruz
      key: ValueKey('celebrationBg'), 
      height: 120, // Kartın yüksekliğinin çok değişmemesi için sabit bir yükseklik
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Hafif yeşil bir arka plan
        color: Color(0xFF38ef7d).withOpacity(0.1),
        borderRadius: BorderRadius.circular(13), // Dış çerçeveye uyum
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "🎉🎉🎉", // Konfeti Emojileri
            style: TextStyle(fontSize: 40),
          ),
          SizedBox(height: 5),
          Text(
            "Learned!",
            style: TextStyle(
              color: Color(0xFF11998e),
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  // YENİ: Normal Kelime İçeriği Görünümü (Eski kodun taşınmış hali)
  Widget _buildNormalContent(
      String word, String translation, bool showTranslation, bool isRemoving) {
    return Container(
      // AnimatedSwitcher için Key
      key: ValueKey('normalContent'),
      padding: EdgeInsets.all(18),
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
                    onPressed: isRemoving ? null : () => _toggleTranslation(word),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF4facfe),
                    ),
                    onPressed: isRemoving ? null : () => _speak(word),
                  ),
                  IconButton(
                    icon: Icon(
                      // Tik işareti tıklanınca dolu ve yeşil olsun
                      isRemoving ? Icons.check_circle : Icons.check_circle_outline,
                      color: isRemoving ? Color(0xFF11998e) : Colors.grey[400],
                    ),
                    // Tıklanınca _toggleKnown fonksiyonunu çağır
                    onPressed: isRemoving ? null : () => _toggleKnown(word),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
         
  @override
  void dispose() {
    _saveKnownWords();
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }
  
}