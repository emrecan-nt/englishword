import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelStatusScreen extends StatefulWidget {
  @override
  _LevelStatusScreenState createState() => _LevelStatusScreenState();
}

class _LevelStatusScreenState extends State<LevelStatusScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, int> levels = {
    'A1': 895,
    'A2': 864,
    'B1': 802,
    'B2': 1432,
    'C1': 1313,
  };

  final Map<String, List<Color>> levelColors = {
    'A1': [Color(0xFF11998e), Color(0xFF38ef7d)],
    'A2': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    'B1': [Color(0xFFfa709a), Color(0xFFfee140)],
    'B2': [Color(0xFFf093fb), Color(0xFFf5576c)],
    'C1': [Color(0xFF667eea), Color(0xFF764ba2)],
  };

  Map<String, int> knownWords = {};
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _loadKnownWords();
  }

  Future<void> _loadKnownWords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> tempKnownWords = {};

    for (String level in levels.keys) {
      final List<String>? knownWordsList =
          prefs.getStringList('${level}_known_words');
      tempKnownWords[level] = knownWordsList?.length ?? 0;
    }

    setState(() {
      knownWords = tempKnownWords;
      isLoading = false;
    });
    _animationController.forward();
  }

  int getTotalKnownWords() {
    return knownWords.values.fold(0, (sum, count) => sum + count);
  }

  int getTotalWords() {
    return levels.values.fold(0, (sum, count) => sum + count);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalKnown = getTotalKnownWords();
    final totalWords = getTotalWords();
    final overallPercentage =
        totalWords > 0 ? (totalKnown / totalWords * 100) : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, totalKnown, totalWords, overallPercentage),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _buildLevelsList(),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, int totalKnown, int totalWords, double percentage) {
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
                  'Your Progress',
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
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Complete',
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
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Words', '$totalWords'),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem('Learned', '$totalKnown'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelsList() {
    final levelsList = levels.keys.toList();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: levelsList.length,
          itemBuilder: (context, index) {
            final level = levelsList[index];
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index * 0.15).clamp(0.0, 0.5),
                  ((index * 0.15) + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildLevelCard(level),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLevelCard(String level) {
    int totalWords = levels[level]!;
    int knownCount = knownWords[level] ?? 0;
    double percentage = totalWords > 0 ? (knownCount / totalWords) : 0.0;
    final colors = levelColors[level]!;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: percentage,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(0)}%',
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
                          'Level $level',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Known: $knownCount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Total: $totalWords',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}