import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'widgets/common/index.dart';
import 'ad_helper.dart';
import 'question_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'constants.dart';
import 'ad_state.dart';

class QuestionSelectPage extends StatefulWidget {
  @override
  _QuestionSelectPageState createState() => _QuestionSelectPageState();
}

// 라운드별 통계 정보
class RoundStat {
  final String roundName;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int wrongCount;
  final double correctRate;

  RoundStat({
    required this.roundName,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.wrongCount,
    required this.correctRate,
  });
}

class _QuestionSelectPageState extends State<QuestionSelectPage>
    with TickerProviderStateMixin {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // 라운드별 통계를 담을 Future
  late Future<List<RoundStat>> _roundStatsFuture;
  bool _isAdStateInitialized = false;

  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _roundStatsFuture = _loadRoundStats();
    _initializeAdState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeAdState() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adState = Provider.of<AdState>(context, listen: false);
      await adState.isInitialized;

      if (mounted) {
        setState(() {
          _isAdStateInitialized = true;
        });

        if (!adState.adsRemoved) {
          _loadRewardedAd();
        }
      }
    });
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              final adState = Provider.of<AdState>(context, listen: false);
              if (!adState.adsRemoved) {
                _loadRewardedAd();
              }
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              final adState = Provider.of<AdState>(context, listen: false);
              if (!adState.adsRemoved) {
                _loadRewardedAd();
              }
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  Future<List<RoundStat>> _loadRoundStats() async {
    final prefs = await SharedPreferences.getInstance();
    List<RoundStat> list = [];
    final rounds = reverseRoundMapping.values.toList();
    for (String roundName in rounds) {
      int totalQuestions = await _getTotalQuestionsForRound(roundName);
      List<String> roundCorrectAnswers =
          prefs.getStringList('correctAnswers_${roundName}') ?? [];
      List<String> roundWrongAnswers =
          prefs.getStringList('wrongAnswers_${roundName}') ?? [];

      final prefix = '${roundName}|';
      int correctCount =
          roundCorrectAnswers.where((s) => s.startsWith(prefix)).length;
      int wrongCount =
          roundWrongAnswers.where((s) => s.startsWith(prefix)).length;
      int answeredCount = correctCount + wrongCount;

      double rate = 0.0;
      if (answeredCount > 0) {
        rate = (correctCount / answeredCount) * 100.0;
      }

      list.add(RoundStat(
        roundName: roundName,
        totalQuestions: totalQuestions,
        answeredCount: answeredCount,
        correctCount: correctCount,
        wrongCount: wrongCount,
        correctRate: rate,
      ));
    }
    return list;
  }

  Future<int> _getTotalQuestionsForRound(String roundName) async {
    int? roundValue = reverseRoundMapping.entries
        .firstWhere((entry) => entry.value == roundName,
            orElse: () => MapEntry(-1, '기타'))
        .key;
    if (roundValue == -1) return 0;
    final dbPath = getDbPath(roundName);
    final dbHelper = DatabaseHelper.getInstance(dbPath);
    int cnt = await dbHelper.getQuestionsCount(roundValue);
    return cnt;
  }

  String getDbPath(String round) {
    int? roundValue = reverseRoundMapping.entries
        .firstWhere((entry) => entry.value == round,
            orElse: () => MapEntry(-1, '기타'))
        .key;
    if (roundValue != -1) {
      return 'assets/question${roundValue}.db';
    } else {
      return 'assets/question_default.db';
    }
  }

  void onRoundSelected(String round) {
    final adState = Provider.of<AdState>(context, listen: false);

    if (adState.adsRemoved) {
      _navigateToNextPage(round);
      return;
    }

    if (!_isRewardedAdLoaded) {
      _loadRewardedAd();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF8E9AAF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_circle_outline, color: Color(0xFF8E9AAF)),
            ),
            SizedBox(width: 12),
            Text("광고 시청"),
          ],
        ),
        content: Text("문제를 풀기 위해 광고를 시청하시겠습니까?"),
        actions: [
          TextButton(
            child: Text("아니요", style: TextStyle(color: Colors.grey[600])),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8E9AAF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("예: 시청하기", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAdAndNavigate(round);
            },
          ),
        ],
      ),
    );
  }

  void _showRewardedAdAndNavigate(String round) {
    if (_rewardedAd != null && _isRewardedAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          _navigateToNextPage(round);
        },
      );
    } else {
      Fluttertoast.showToast(
        msg: '광고가 아직 준비되지 않았습니다.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      _navigateToNextPage(round);
    }
  }

  void _navigateToNextPage(String round) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreenPage(
          round: round,
          dbPath: getDbPath(round),
        ),
      ),
    ).then((_) {
      setState(() {
        _roundStatsFuture = _loadRoundStats();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ThemedBackgroundWidget(
        isDarkMode: isDarkMode,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  CommonHeaderWidget(
                    title: '연도별 문제풀기',
                    subtitle: '원하는 회차를 선택하세요',
                    onHomePressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                      (route) => false,
                    ),
                  ),
                  Expanded(
                    child: _buildMainContent(isDarkMode),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return FutureBuilder<List<RoundStat>>(
      future: _roundStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFF8E9AAF)));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('데이터를 불러올 수 없습니다.'));
        }

        final statsList = snapshot.data!;

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8, // 에러 해결 포인트: 카드 비율 조정
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: reverseRoundMapping.length,
          itemBuilder: (context, index) {
            final roundName = reverseRoundMapping.values.toList()[index];
            final stat = statsList.firstWhere(
              (s) => s.roundName == roundName,
              orElse: () => RoundStat(
                roundName: roundName,
                totalQuestions: 0,
                answeredCount: 0,
                correctCount: 0,
                wrongCount: 0,
                correctRate: 0.0,
              ),
            );

            return _buildRoundCard(stat, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildRoundCard(RoundStat stat, bool isDarkMode) {
    final progressValue = (stat.totalQuestions == 0)
        ? 0.0
        : (stat.answeredCount / stat.totalQuestions);
    final rateStr = stat.correctRate.toStringAsFixed(0);

    return GestureDetector(
      key: Key('round_card_${stat.roundName}'),
      onTap: () => onRoundSelected(stat.roundName),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8E9AAF), Color(0xFF8E9AAF).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Color(0xFF8E9AAF).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(12), // 여백 소폭 축소
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 회차 제목: 한 줄로 제한하거나 크기 축소
                Text(
                  stat.roundName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8)),
                  ),
                ),
                // 에러 해결 포인트: Expanded 내부 Column을 주축 정렬 방식 수정 및 유연성 확보
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatRow(
                          icon: Icons.task_alt_rounded,
                          label: '${stat.answeredCount}/${stat.totalQuestions}',
                          subtitle: '완료',
                        ),
                        _buildStatRow(
                          icon: Icons.check_circle_rounded,
                          label: '${stat.correctCount}',
                          subtitle: '정답',
                        ),
                        _buildStatRow(
                          icon: Icons.star_rounded,
                          label: '$rateStr%',
                          subtitle: '정답률',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 12),
        SizedBox(width: 6),
        // 텍스트가 겹치지 않도록 가로로 배치
        Expanded(
          child: Text(
            "$subtitle: $label",
            style: TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
