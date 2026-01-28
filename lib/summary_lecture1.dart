import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // StreamSubscription을 위해 추가
import 'dart:typed_data';
import 'database_helper.dart';
import 'home.dart';
import 'constants.dart';
import 'ad_helper.dart';
import 'ad_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 학습노트 데이터 (기존과 동일)
final Map<String, Map<String, dynamic>> studyNotes = {
  "1. 엔진 냉각 시스템과 과열 방지": {
    'description':
        '''- 냉각팬은 냉각수 온도에 따라 전동팬이 가·정지하고, 워터 펌프는 크랭크축에 의해 항상 구동되므로 두 장치는 독립적으로 작동한다.
- 주요 과열 원인: 라디에이터 코어 막힘, 냉각수 부족·물때, 팬벨트 이완, 펌프 불량 등 냉각 효율 저하 요인.
- 과열 후 나타나는 현상: 실린더 헤드 열변형·가스켓 손상, 출력 저하, 윤활유 열화.
- 냉각수가 정상 온도로 상승하지 않을 때는 서모스탯가 열림 고착, 팬 과회전 등 ‘과냉’ 상황을 의심한다.
- 정비 요령: 팬벨트 장력·펌프 누수·서모스탯 작동 확인, 냉각수 농도·수량 유지, 라디에이터 청소.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 1},
      {'date': '2011년 10월', 'question_id': 2},
      {'date': '2011년 7월', 'question_id': 11},
      {'date': '2011년 7월', 'question_id': 12},
      {'date': '2011년 7월', 'question_id': 6},
    ],
  },
  "2. 디젤 연료계통 고장 진단과 공기빼기": {
    'description':
        '''- 분사노즐은 핀틀･스로틀･홀형을 사용하며 싱글포인트는 가솔린용이다.
- 연료라인에 공기가 혼입되면 시동 불량·부조·출력 저하가 발생하므로 ‘공급펌프→여과기→분사펌프’ 순으로 에어빼기를 실시한다.
- 인젝터 공급관 누설, 거버너·분사시기 불량, 연료압송 부족은 부조의 대표 원인이다.
- 에어클리너 막힘은 과농 혼합 → 검은 연기·출력 감소로 나타난다.
- 예열플러그 과오염은 불완전 연소·노킹의 결과이며, 시동 불량 시 배터리 전압부터 우선 점검한다.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 6},
      {'date': '2011년 10월', 'question_id': 7},
      {'date': '2011년 10월', 'question_id': 8},
      {'date': '2011년 4월', 'question_id': 6},
      {'date': '2011년 4월', 'question_id': 7},
      {'date': '2011년 7월', 'question_id': 10},
      {'date': '2011년 7월', 'question_id': 9},
    ],
  },
  "3. 윤활 시스템의 압력·소비 이상": {
    'description':
        '''- 윤활유 기능: 마찰‧마모 감소, 냉각, 방청, 밀봉. 연소 작용과는 무관.
- 고압 발생 요인: 점도 과대, 오일 통로 막힘. 저압 요인: 펌프 성능 저하, 유량 부족, 과마모.
- 오일 소비 과다의 최대 원인은 피스톤 링 마멸로 인한 연소실 유입.
- 오일량 증가 = 냉각수·연료의 혼입 가능성을 의미하며 즉시 누설 부위 점검.
- 기관 윤활 방식은 ‘압송 급유식’이 표준이며, 일상 점검은 오일량·압력계 경고등 확인이 필수.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 11},
      {'date': '2011년 10월', 'question_id': 9},
      {'date': '2011년 4월', 'question_id': 3},
      {'date': '2011년 4월', 'question_id': 9},
      {'date': '2011년 7월', 'question_id': 1},
      {'date': '2011년 7월', 'question_id': 5},
    ],
  },
  "4. 시동·충전·축전지 전기 시스템": {
    'description':
        '''- 스타터 회전 불량 점검 순서: 배터리 전압 → 단자·스위치 접촉 → 브러시 밀착 → 전기자 시험(무부하·회전력).
- 발전기 원리: 로터가 자계를 만들고, 스테이터 코일에서 교류가 유기되어 다이오드 정류.
- 전압 조정기는 접점식·카본파일식·트랜지스터식이 있으며 ‘저항식’ 없음.
- 충전 경고등 점등 = 충전 불능, 즉시 벨트·발전기·배선 이상을 확인.
- 납산축전지 급속충전은 정전류(용량의 1/2~1/3)로, 과전류는 극판 손상·가스 폭발 위험. MF 배터리는 보수수 보충이 불필요.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 13},
      {'date': '2011년 10월', 'question_id': 14},
      {'date': '2011년 10월', 'question_id': 16},
      {'date': '2011년 10월', 'question_id': 17},
      {'date': '2011년 10월', 'question_id': 18},
      {'date': '2011년 10월', 'question_id': 4},
      {'date': '2011년 4월', 'question_id': 14},
      {'date': '2011년 4월', 'question_id': 15},
      {'date': '2011년 4월', 'question_id': 16},
      {'date': '2011년 4월', 'question_id': 18},
      {'date': '2011년 7월', 'question_id': 13},
      {'date': '2011년 7월', 'question_id': 14},
      {'date': '2011년 7월', 'question_id': 15},
      {'date': '2011년 7월', 'question_id': 16},
      {'date': '2011년 7월', 'question_id': 18},
    ],
  },
  "5. 유압 시스템 기본 원리와 구성": {
    'description':
        '''- 파스칼 원리: 밀폐 계 내 압력은 모든 방향에 동일 전달 → 실린더는 유압을 직선 운동으로, 모터는 회전 운동으로 변환.
- 펌프: 기어·베인·피스톤·트로코이드 등. 회전수 증가 시 유량이 직접 증가.
- 제어밸브: 릴리프(압력 한계), 시퀀스(작동 순서), 유량제어(미터-인/아웃), 체크(역류 방지).
- 탱크 구성: 스트레이너, 배플, 드레인플러그(압력조절기는 별도). 오일 고온·고점도는 동력 손실·산화 촉진을 유발.
- 축압기는 공기압축형(피스톤·다이어프램·블래더)과 스프링식이 있으며, 회로 충격 흡수·에너지 저장용.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 37},
      {'date': '2011년 10월', 'question_id': 38},
      {'date': '2011년 10월', 'question_id': 39},
      {'date': '2011년 10월', 'question_id': 40},
      {'date': '2011년 10월', 'question_id': 41},
      {'date': '2011년 10월', 'question_id': 42},
      {'date': '2011년 10월', 'question_id': 43},
      {'date': '2011년 10월', 'question_id': 44},
      {'date': '2011년 10월', 'question_id': 45},
      {'date': '2011년 10월', 'question_id': 46},
      {'date': '2011년 4월', 'question_id': 37},
      {'date': '2011년 4월', 'question_id': 38},
      {'date': '2011년 4월', 'question_id': 39},
      {'date': '2011년 4월', 'question_id': 40},
      {'date': '2011년 4월', 'question_id': 41},
      {'date': '2011년 4월', 'question_id': 42},
      {'date': '2011년 4월', 'question_id': 43},
      {'date': '2011년 4월', 'question_id': 44},
      {'date': '2011년 4월', 'question_id': 45},
      {'date': '2011년 4월', 'question_id': 46},
      {'date': '2011년 7월', 'question_id': 37},
      {'date': '2011년 7월', 'question_id': 38},
      {'date': '2011년 7월', 'question_id': 39},
      {'date': '2011년 7월', 'question_id': 40},
      {'date': '2011년 7월', 'question_id': 41},
      {'date': '2011년 7월', 'question_id': 42},
      {'date': '2011년 7월', 'question_id': 43},
      {'date': '2011년 7월', 'question_id': 44},
      {'date': '2011년 7월', 'question_id': 45},
      {'date': '2011년 7월', 'question_id': 46},
    ],
  },
  "6. 도로교통 규정 및 사고 대응": {
    'description':
        '''- 노면 결빙·폭설·안개(가시 100 m 이하)는 최고속도의 50 % 감속 운행.
- 최고속도 제한, 비보호 좌회전, 우회전 전 차로 변경(편도 4차로 4차로 진입) 등 표지·신호 준수.
- 정차·주차 금지: 교차로 모서리 5 m 이내, 건널목·횡단보도 등.
- 교통사고 시 최우선 조치: 사상자 구호 후 즉시 경찰 신고. 통고처분 불이행·거부 시 즉결심판 회부.
- 신호·수신호 위반, 두 차로 걸친 주행, 앞지르기 제한 조건(좌측에 차량 병행) 등을 숙지.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 29},
      {'date': '2011년 10월', 'question_id': 30},
      {'date': '2011년 10월', 'question_id': 32},
      {'date': '2011년 10월', 'question_id': 33},
      {'date': '2011년 10월', 'question_id': 35},
      {'date': '2011년 4월', 'question_id': 27},
      {'date': '2011년 4월', 'question_id': 28},
      {'date': '2011년 4월', 'question_id': 30},
      {'date': '2011년 4월', 'question_id': 32},
      {'date': '2011년 4월', 'question_id': 33},
      {'date': '2011년 4월', 'question_id': 36},
      {'date': '2011년 7월', 'question_id': 28},
      {'date': '2011년 7월', 'question_id': 29},
      {'date': '2011년 7월', 'question_id': 30},
      {'date': '2011년 7월', 'question_id': 31},
      {'date': '2011년 7월', 'question_id': 33},
      {'date': '2011년 7월', 'question_id': 35},
      {'date': '2011년 7월', 'question_id': 36},
    ],
  },
  "7. 건설기계 운전·정비 핵심": {
    'description':
        '''- 트랙 장력은 아이들러-상부롤러 사이 처짐으로 점검, 과장력 시 핀·부싱·스프로킷 마모 가속.
- 토크컨버터 스테이터는 유류 흐름 방향을 전환, 토크 증대 기능. 전 변속단 출력 저하는 오일 부족·컨버터 고장 의심.
- 파워스티어링 무거움 → 조향펌프 오일 부족, 휠 로더 붐+버킷 동시 조작 시 복합 유압 회로 이해 필요.
- 지게차 경사 하향 운행 시 후진, 클러치 미끄러짐은 연료 소비·출력 손실을 초래.
- 기중기 붐 각도(20°~78°), 내부 확장식 드럼 클러치, 작업 시 신호자 규정 준수 및 하중은 수직 인양.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 19},
      {'date': '2011년 10월', 'question_id': 20},
      {'date': '2011년 10월', 'question_id': 21},
      {'date': '2011년 10월', 'question_id': 22},
      {'date': '2011년 10월', 'question_id': 23},
      {'date': '2011년 10월', 'question_id': 24},
      {'date': '2011년 10월', 'question_id': 25},
      {'date': '2011년 10월', 'question_id': 26},
      {'date': '2011년 7월', 'question_id': 19},
      {'date': '2011년 7월', 'question_id': 20},
      {'date': '2011년 7월', 'question_id': 21},
      {'date': '2011년 7월', 'question_id': 22},
      {'date': '2011년 7월', 'question_id': 23},
      {'date': '2011년 7월', 'question_id': 24},
      {'date': '2011년 7월', 'question_id': 25},
      {'date': '2011년 7월', 'question_id': 26},
    ],
  },
  "8. 작업장 안전·화재·전기·공구 관리": {
    'description':
        '''- 화재 3요소(가연물-산소-점화원) 제거가 예방의 핵심. 엔진 화재 시 즉시 시동 OFF 후 ABC 소화기 사용.
- 산업안전보건표지: 보행금지·물체이동금지 등 원형 금지 표지, 응급구호·비상구 등 안내 표지 파악.
- 벨트·회전체 재해 다발, 정지 전 손 접촉 금지. 전력케이블·가스표지시트 노출 시 즉시 작업 중지·관계기관 연락.
- 전기 정전 시 스위치 OFF, 퓨즈 반복 단선 시 원인 회로 수리. 접지선 표지색은 녹색. 고압선 근접만으로도 감전 위험.
- 안전공구: 토크렌치로 정확한 체결, 복스렌치는 완전 감싸 미끄럼 방지, 조정렌치는 몸 쪽으로 당겨 사용.''',
    'related_questions': [
      {'date': '2011년 10월', 'question_id': 48},
      {'date': '2011년 10월', 'question_id': 50},
      {'date': '2011년 10월', 'question_id': 51},
      {'date': '2011년 10월', 'question_id': 52},
      {'date': '2011년 10월', 'question_id': 53},
      {'date': '2011년 10월', 'question_id': 54},
      {'date': '2011년 10월', 'question_id': 55},
      {'date': '2011년 10월', 'question_id': 56},
      {'date': '2011년 10월', 'question_id': 57},
      {'date': '2011년 10월', 'question_id': 60},
      {'date': '2011년 4월', 'question_id': 47},
      {'date': '2011년 4월', 'question_id': 48},
      {'date': '2011년 4월', 'question_id': 49},
      {'date': '2011년 4월', 'question_id': 50},
      {'date': '2011년 4월', 'question_id': 51},
      {'date': '2011년 4월', 'question_id': 52},
      {'date': '2011년 4월', 'question_id': 53},
      {'date': '2011년 4월', 'question_id': 54},
      {'date': '2011년 4월', 'question_id': 55},
      {'date': '2011년 4월', 'question_id': 56},
      {'date': '2011년 4월', 'question_id': 57},
      {'date': '2011년 4월', 'question_id': 58},
      {'date': '2011년 4월', 'question_id': 59},
      {'date': '2011년 4월', 'question_id': 60},
      {'date': '2011년 7월', 'question_id': 47},
      {'date': '2011년 7월', 'question_id': 48},
      {'date': '2011년 7월', 'question_id': 49},
      {'date': '2011년 7월', 'question_id': 50},
      {'date': '2011년 7월', 'question_id': 51},
      {'date': '2011년 7월', 'question_id': 52},
      {'date': '2011년 7월', 'question_id': 53},
      {'date': '2011년 7월', 'question_id': 54},
      {'date': '2011년 7월', 'question_id': 55},
      {'date': '2011년 7월', 'question_id': 56},
      {'date': '2011년 7월', 'question_id': 57},
      {'date': '2011년 7월', 'question_id': 58},
      {'date': '2011년 7월', 'question_id': 59},
      {'date': '2011년 7월', 'question_id': 60},
    ],
  },
};

class SummaryLecture1Page extends StatefulWidget {
  final String dbPath;

  SummaryLecture1Page({required this.dbPath});

  @override
  _SummaryLecture1PageState createState() => _SummaryLecture1PageState();
}

class _SummaryLecture1PageState extends State<SummaryLecture1Page>
    with WidgetsBindingObserver {
  late DatabaseHelper dbHelper;
  bool isLoading = false;

  // 오디오 플레이어 관련 변수
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  final List<double> _speedOptions = [0.8, 1.0, 1.2, 1.5, 2.0];
  double _currentSpeed = 1.0;
  bool _isAudioInitialized = false; // 오디오 초기화 상태 추가

  // 오디오 플레이어 리스너 구독을 관리하기 위한 변수 추가
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processingStateSubscription;

  // 테스트 모드 관련 변수 추가
  bool _isTestMode = false;
  Timer? _testModeTimer;
  static const Duration _testModeDuration = Duration(seconds: 10);

  // 광고 관련 변수 추가
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  int _lastAdShowTime = 0;
  final int _adInterval = 240;
  bool _isAdShowing = false;
  bool _wasPlayingBeforeAd = false;
  int _adRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 테스트 모드 감지
    _isTestMode =
        const bool.fromEnvironment('DISABLE_ADS', defaultValue: false);
    print('SummaryLecture1Page: Test mode enabled: $_isTestMode');

    dbHelper = DatabaseHelper(widget.dbPath);

    // 오디오 초기화를 별도로 실행하여 UI 렌더링을 차단하지 않도록 함
    _initAudioPlayerAsync();

    // 광고 로드는 별도로 실행
    Future.microtask(() {
      if (mounted) {
        _loadInterstitialAd();
      }
    });
  }

  // 오디오 초기화를 비동기로 처리
  void _initAudioPlayerAsync() {
    // UI는 즉시 표시되도록 하고, 오디오 초기화는 백그라운드에서 처리
    Future.microtask(() async {
      if (mounted) {
        await _initAudioPlayer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 테스트 모드 타이머 정리
    _cancelTestModeTimer();

    // 가장 먼저 오디오 플레이어 중지 및 구독 취소
    _audioPlayer.stop(); // 플레이를 즉시 멈춤
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;

    _audioPlayer.dispose(); // 그 다음 플레이어 리소스 해제
    dbHelper.dispose();
    _interstitialAd?.dispose(); // 광고 리소스 해제
    super.dispose();
  }

  // 테스트 모드 타이머 시작
  void _startTestModeTimer() {
    if (!_isTestMode) return;

    _cancelTestModeTimer(); // 기존 타이머가 있다면 취소

    print(
        'SummaryLecture1Page: Starting test mode timer: ${_testModeDuration.inSeconds} seconds');
    _testModeTimer = Timer(_testModeDuration, () {
      print('SummaryLecture1Page: Test mode timer expired - stopping audio');
      if (mounted && _isPlaying) {
        _audioPlayer.pause();
      }
    });
  }

  // 테스트 모드 타이머 취소
  void _cancelTestModeTimer() {
    if (_testModeTimer != null) {
      print('SummaryLecture1Page: Cancelling test mode timer');
      _testModeTimer!.cancel();
      _testModeTimer = null;
    }
  }

  void _loadInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    print("DEBUG: 전면 광고 로드 시도 (시도 횟수: $_adRetryCount)");
    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 제거됨 또는 테스트 모드임");
      return;
    }

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            // 콜백 내에서도 mounted 확인
            ad.dispose(); // 로드되었지만 페이지가 사라졌으면 광고도 해제
            return;
          }
          print("DEBUG: 전면 광고 로드 성공");
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _adRetryCount = 0;
          });

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (!mounted) return;
              print("DEBUG: 광고 닫힘");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (!mounted) return;
              print("DEBUG: 광고 표시 실패: $error");
              ad.dispose();
              setState(() {
                _isInterstitialAdLoaded = false;
                _isAdShowing = false;
              });

              if (_wasPlayingBeforeAd) {
                _audioPlayer.play();
              }

              if (!adState.adsRemoved && !kDisableAdsForTesting) {
                if (mounted) _loadInterstitialAd();
              }
            },
            onAdShowedFullScreenContent: (ad) {
              print("DEBUG: 광고 전체화면으로 표시됨");
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          print('DEBUG: 전면 광고 로드 실패: $error');
          setState(() => _isInterstitialAdLoaded = false);

          _adRetryCount++;
          Future.delayed(Duration(seconds: 30), () {
            if (mounted) _loadInterstitialAd();
          });

          if (_isAdShowing && _wasPlayingBeforeAd) {
            if (mounted) {
              setState(() => _isAdShowing = false);
              _audioPlayer.play();
            }
          }
        },
      ),
    );
  }

  // _initAudioPlayer 메서드를 다음과 같이 완전히 교체하세요:

  Future<void> _initAudioPlayer() async {
    try {
      print('DEBUG: 오디오 플레이어 초기화 시작');

      if (!mounted) return;

      setState(() {
        _isAudioLoading = true;
        _errorMessage = '';
      });

      // 방법 1: AssetSource 직접 사용 (가장 권장되는 방법)
      try {
        print('DEBUG: AssetSource로 오디오 로딩 시도');

        // 경로에서 'assets/' 제거하고 시도
        await _audioPlayer.setAudioSource(
          AudioSource.asset('audio/summary/lecture1.mp3'),
          preload: true,
        );
        print('DEBUG: AssetSource 오디오 로딩 성공');
      } catch (assetError) {
        print('DEBUG: AssetSource 실패: $assetError');

        // 방법 2: 다른 경로로 시도
        try {
          print('DEBUG: 전체 경로로 AssetSource 시도');
          await _audioPlayer.setAudioSource(
            AudioSource.asset('assets/audio/summary/lecture1.mp3'),
            preload: true,
          );
          print('DEBUG: 전체 경로 AssetSource 성공');
        } catch (fullPathError) {
          print('DEBUG: 전체 경로도 실패: $fullPathError');

          // 방법 3: BytesAudioSource (마지막 수단)
          try {
            print('DEBUG: BytesAudioSource로 fallback 시도');
            final ByteData data =
                await rootBundle.load('assets/audio/summary/lecture1.mp3');
            print('DEBUG: 오디오 파일 로드 성공, 크기: ${data.lengthInBytes} bytes');

            if (!mounted) return;

            final Uint8List bytes = data.buffer.asUint8List();

            // BytesAudioSource 사용 시 preload 제거
            await _audioPlayer.setAudioSource(BytesAudioSource(bytes));
            print('DEBUG: BytesAudioSource 오디오 설정 완료');
          } catch (bytesError) {
            print('DEBUG: BytesAudioSource도 실패: $bytesError');

            // 방법 4: 임시 파일로 저장 후 로드
            try {
              print('DEBUG: 임시 파일 방식 시도');
              await _loadAudioFromTempFile();
              print('DEBUG: 임시 파일 방식 성공');
            } catch (tempError) {
              print('DEBUG: 모든 방법 실패: $tempError');
              throw Exception('모든 오디오 로딩 방법이 실패했습니다: $tempError');
            }
          }
        }
      }

      if (!mounted) return;

      // 성공적으로 로드된 경우에만 리스너 설정
      await _setupAudioListeners();
      await _audioPlayer.setSpeed(_currentSpeed);

      if (!mounted) return;

      setState(() {
        _isAudioLoading = false;
        _isAudioInitialized = true;
      });

      print('DEBUG: 오디오 플레이어 초기화 완료');
    } catch (e) {
      print("DEBUG: 오디오 초기화 전체 오류: $e");
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _errorMessage = '오디오 초기화 오류: $e';
          _isAudioInitialized = false;
        });
      }
    }
  }

// 임시 파일을 사용한 오디오 로딩 메서드 추가
  Future<void> _loadAudioFromTempFile() async {
    final ByteData data =
        await rootBundle.load('assets/audio/summary/lecture1.mp3');
    final Uint8List bytes = data.buffer.asUint8List();

    // 임시 디렉토리에 파일 저장
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/temp_lecture1.mp3');
    await tempFile.writeAsBytes(bytes);

    // 임시 파일로부터 오디오 로드
    await _audioPlayer.setAudioSource(AudioSource.file(tempFile.path));

    print('DEBUG: 임시 파일에서 오디오 로드 완료: ${tempFile.path}');
  }

// 오디오 리스너 설정을 별도 메서드로 분리
  Future<void> _setupAudioListeners() async {
    // 기존 구독이 있다면 취소
    await _cancelAudioSubscriptions();

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.playing != _isPlaying) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null) {
        setState(() => _duration = d);
        print('DEBUG: 오디오 길이 설정: ${d.inMinutes}:${d.inSeconds % 60}');
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);

      int currentPositionInSeconds = p.inSeconds;
      if (_isPlaying &&
          _isInterstitialAdLoaded &&
          !_isAdShowing &&
          currentPositionInSeconds > 0 &&
          currentPositionInSeconds - _lastAdShowTime >= _adInterval) {
        print(
            "DEBUG: 광고 표시 조건 충족. 현재 시간: $currentPositionInSeconds, 마지막 광고 시간: $_lastAdShowTime");
        if (mounted) {
          setState(() {
            _isAdShowing = true;
            _wasPlayingBeforeAd = _isPlaying;
          });
        }
        _audioPlayer.pause();
        _lastAdShowTime = currentPositionInSeconds;
        if (mounted) _showInterstitialAd();
      }
    });

    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        _cancelTestModeTimer();
        setState(() {
          _isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

// 구독 취소 메서드
  Future<void> _cancelAudioSubscriptions() async {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processingStateSubscription?.cancel();
    _processingStateSubscription = null;
  }

  void _showInterstitialAd() {
    if (!mounted) return; // 메서드 시작 시 mounted 확인

    final adState = Provider.of<AdState>(context, listen: false);
    if (adState.adsRemoved || kDisableAdsForTesting) {
      print("DEBUG: 광고 표시 스킵 - 광고 제거됨 또는 테스트 모드");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      return;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      print("DEBUG: 광고 표시 실패 - 광고가 로드되지 않음");
      if (mounted) setState(() => _isAdShowing = false);
      if (_wasPlayingBeforeAd) {
        _audioPlayer.play();
      }
      if (mounted) _loadInterstitialAd();
      return;
    }

    print("DEBUG: 전면 광고 표시 시도");
    _interstitialAd!.show().catchError((error) {
      print("DEBUG: 광고 표시 중 오류 발생: $error");
      if (mounted) {
        setState(() => _isAdShowing = false);
        if (_wasPlayingBeforeAd) {
          _audioPlayer.play();
        }
        _loadInterstitialAd();
      }
    });
  }

  void _playPause() {
    if (!mounted || !_isAudioInitialized) return;

    if (_audioPlayer.playing) {
      // 일시정지 시 타이머 취소
      _cancelTestModeTimer();
      _audioPlayer.pause();
    } else {
      // 재생 시 테스트 모드에서 타이머 시작
      _audioPlayer.play();
      if (_isTestMode) {
        _startTestModeTimer();
      }
    }
  }

  void _changePlaybackSpeed(double speed) {
    if (!mounted || !_isAudioInitialized) return;
    setState(() {
      _currentSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

// summary_lecture1.dart 파일

void _showQuestionDialog(BuildContext context, String date, int questionId) async {
  if (!mounted) return;

  // --- 제안해주신 로직 시작 ---

  // 1. 날짜 문자열 정규화 (예: '2022년 04월' -> '2022년 4월')
  // '04월'과 '4월'의 불일치 가능성을 처리합니다.
  final normalizedDate = date.replaceAll(' 0', ' ');

  // 2. 맵핑(constants.dart)을 통해 DB 파일 번호(examSession) 찾기
  int? examSession;
  // reverseRoundMapping은 constants.dart에 정의되어 있다고 가정합니다.
  // 이 파일이 import 되어 있는지 확인하세요. 예: import 'constants.dart';
  reverseRoundMapping.forEach((key, value) {
    if (value == normalizedDate) {
      examSession = key;
    }
  });

  // 맵핑되는 DB가 없으면 사용자에게 알림
  if (examSession == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: "$date"에 해당하는 시험 회차 정보를 찾을 수 없습니다.')),
    );
    return;
  }

  try {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // 3. 해당 DB 파일 경로 지정 (예: question1.db)
    String dbPath = 'assets/question$examSession.db';
    DatabaseHelper questionDb = DatabaseHelper.getInstance(dbPath);

    // 4. 새로 추가한 getQuestion 메서드 호출 (Question_id만 사용)
    final question = await questionDb.getQuestion(questionId);
    
    // --- 로직 종료 ---

    if (!mounted) {
      // questionDb.dispose(); // 개별 인스턴스 dispose는 필요시 사용
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (question != null) {
      // 다이얼로그를 보여주는 코드는 기존과 동일하게 작동합니다.
      // ... (기존 다이얼로그 코드) ...
       final correctOption = question['Correct_Option'] != null
            ? int.tryParse(question['Correct_Option'].toString())
            : null;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          title: Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blue),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$date - Question $questionId',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question['Big_Question'] != null &&
                    question['Big_Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildContent(
                      question['Big_Question'],
                      context,
                      isBold: true,
                    ),
                  ),
                if (question['Question'] != null &&
                    question['Question'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Question'],
                      context,
                    ),
                  ),
                if (question['Image'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContent(
                      question['Image'],
                      context,
                      isImage: true,
                    ),
                  ),
                ...List.generate(4, (index) {
                  final optionKey = 'Option${index + 1}';
                  final optionData = question[optionKey];
                  if (optionData == null ||
                      (optionData is String && optionData.isEmpty)) {
                    return SizedBox.shrink();
                  }
                  final isCorrect = correctOption == index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${['➀', '➁', '➂', '➃'][index]} ',
                          style: TextStyle(
                            fontSize: 16,
                            color: isCorrect
                                ? Colors.blue
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black),
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Expanded(
                          child: _buildContent(
                            optionData,
                            context,
                            isCorrect: isCorrect,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey[300],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '정답 설명',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue
                          : Colors.blue[700],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    question['Answer_description']?.toString() ?? '설명 없음',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '닫기',
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('question$examSession.db에서 Question_id $questionId에 해당하는 문제를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // 데이터베이스 인스턴스는 앱 전체에서 관리되므로 여기서 개별적으로 닫지 않는 것이 좋습니다.
    // DatabaseHelper.disposeInstance(dbPath); 
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 데이터를 로드하는 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildContent(dynamic data, BuildContext context,
      {bool isBold = false, bool isCorrect = false, bool isImage = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Uint8List? imageBytes;

    try {
      if (data is Uint8List) {
        imageBytes = data;
      } else if (data is List<dynamic>) {
        try {
          imageBytes = Uint8List.fromList(data.cast<int>());
        } catch (e) {
          // 변환 실패 시 아무것도 하지 않음
        }
      }
    } catch (e) {
      // 데이터 변환 중 오류 발생 시 아무것도 하지 않음
    }

    if (imageBytes != null && imageBytes.length > 100) {
      bool isValidImage = false;
      if (imageBytes.length > 4) {
        if (imageBytes[0] == 0xFF &&
            imageBytes[1] == 0xD8 &&
            imageBytes[2] == 0xFF) {
          // JPEG
          isValidImage = true;
        } else if (imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47) {
          // PNG
          isValidImage = true;
        } else if (imageBytes[0] == 0x47 &&
            imageBytes[1] == 0x49 &&
            imageBytes[2] == 0x46) {
          // GIF
          isValidImage = true;
        }
      }

      if (isValidImage) {
        return Container(
          constraints: BoxConstraints(maxWidth: 280, maxHeight: 400),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text('이미지를 표시할 수 없습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 14));
            },
          ),
        );
      } else {
        return Text('[이미지 데이터 - 표시할 수 없음]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
    } else {
      String text = data?.toString() ?? '';
      if (text.length > 100 && RegExp(r'^\d+$').hasMatch(text)) {
        return Text('[이미지 데이터로 추정됨]',
            style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey : Colors.grey[700]));
      }
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isCorrect
              ? Colors.blue
              : (isDarkMode ? Colors.white : Colors.black),
          fontWeight: isBold
              ? FontWeight.bold
              : (isCorrect ? FontWeight.bold : FontWeight.normal),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비법노트',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF3A4A68) : Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              if (!mounted) return; // 네비게이션 전 mounted 확인
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF1C1C28) : Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 테스트 모드 표시 배너 추가
            if (_isTestMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.orange.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '테스트 모드: 10초 자동 정지',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // 오디오 플레이어 UI - 항상 표시
            Container(
              color: isDarkMode ? Color(0xFF252535) : Colors.grey[100],
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 타이틀
                  Text(
                    "강의 듣기",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // 오디오 상태에 따른 UI 표시
                  if (_isAudioLoading)
                    // 로딩 중
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.blue[300]! : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '오디오를 준비하고 있습니다...',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage.isNotEmpty)
                    // 오류 발생
                    Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                              _isAudioLoading = true;
                            });
                            _initAudioPlayer();
                          },
                          child: Text('다시 시도'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    // 정상 오디오 플레이어 UI
                    Column(
                      children: [
                        // 재생/일시정지 버튼
                        ElevatedButton(
                          onPressed: _isAudioInitialized ? _playPause : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.blueGrey[700]
                                : Color(0xFF4A90E2),
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isPlaying ? '일시정지' : '강의 재생',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // 컨트롤
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '재생 속도: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                ),
                                DropdownButton<double>(
                                  value: _currentSpeed,
                                  isDense: true,
                                  underline: Container(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                  dropdownColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  onChanged: _isAudioInitialized
                                      ? (double? newValue) {
                                          if (newValue != null) {
                                            _changePlaybackSpeed(newValue);
                                          }
                                        }
                                      : null,
                                  items: _speedOptions
                                      .map<DropdownMenuItem<double>>(
                                          (double value) {
                                    return DropdownMenuItem<double>(
                                      value: value,
                                      child: Text(
                                        '${value}x',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            Text(
                              '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            inactiveTrackColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            thumbColor:
                                isDarkMode ? Colors.blue[300] : Colors.blue,
                            overlayColor: isDarkMode
                                ? Colors.blue.withAlpha(32)
                                : Colors.blue.withAlpha(32),
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble() > 0
                                ? _duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: _isAudioInitialized
                                ? (value) async {
                                    if (!mounted) return; // seek 전 mounted 확인
                                    await _audioPlayer
                                        .seek(Duration(seconds: value.toInt()));
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 노트 내용
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: studyNotes.entries.map((mainTopicEntry) {
                        final mainTopic = mainTopicEntry.key;
                        final mainValue = mainTopicEntry.value;
                        final mainDesc = mainValue['description'] as String;
                        List<Map<String, dynamic>> relatedQuestions = [];
                        if (mainValue.containsKey('related_questions') &&
                            mainValue['related_questions'] != null) {
                          final rawQuestions =
                              mainValue['related_questions'] as List<dynamic>;
                          if (rawQuestions.isNotEmpty) {
                            relatedQuestions = rawQuestions
                                .map((q) => q as Map<String, dynamic>)
                                .toList();
                          }
                        }
                        return Card(
                          margin: EdgeInsets.only(bottom: 24),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: isDarkMode ? Color(0xFF2A2A3C) : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getTopicColor(mainTopic),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mainTopic.split('.').first,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        mainTopic.split('. ').last,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24,
                                    color: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    mainDesc,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                                if (relatedQuestions.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Color(0xFF22222E)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              size: 16,
                                              color: isDarkMode
                                                  ? Colors.blue[300]
                                                  : Colors.blue[700],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '관련 문제',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8.0,
                                          runSpacing: 8.0,
                                          children:
                                              relatedQuestions.map((question) {
                                            final date = question['date'];
                                            final questionId =
                                                question['question_id'];
                                            final shortDate = date
                                                .toString()
                                                .replaceAll('년 ', '.')
                                                .replaceAll('월', '');
                                            return InkWell(
                                              onTap: () => _showQuestionDialog(
                                                  context, date, questionId),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.blueGrey[800]
                                                      : Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '$shortDate (#$questionId)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDarkMode
                                                        ? Colors.blue[200]
                                                        : Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
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

  Color _getTopicColor(String topic) {
    int topicNumber = int.tryParse(topic.split('.').first) ?? 0;
    switch (topicNumber) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.pink;
      case 6:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}

class BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start = start ?? 0;
    end = end ?? _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
