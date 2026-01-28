import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'splash_screen.dart';
import 'home.dart';
import 'ad_state.dart';
import 'event.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화를 가장 먼저 수행
  print("Initializing Firebase...");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase initialized successfully");
  
  // Firebase Analytics 인스턴스 생성 및 초기화
  final analytics = FirebaseAnalytics.instance;
  
  // 테스트 이벤트 전송
  await analytics.logEvent(
    name: 'app_started',
    parameters: {
      'time': DateTime.now().toIso8601String(),
    },
  );
  print("Firebase Analytics test event sent");
  
  // AdMob 초기화 및 어댑터 상태 확인
  final initializationStatus = await MobileAds.instance.initialize();

  // Test device ID from logcat
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: [
        '6673EFF8A126813194B692A7ABA57858', // Samsung SM-A325N test device
      ],
    ),
  );

  // 디버그용: 어댑터 로드 상태 출력
  print("=== ADAPTER INITIALIZATION STATUS ===");
  initializationStatus.adapterStatuses.forEach((key, value) {
    print("$key: ${value.state.name}");
    if (key.toLowerCase().contains('unity')) {
      print(">>> Unity Ads 어댑터 발견!");
    }
  });
  print("=====================================");

  // Give the SDK a moment to fully initialize adapters
  await Future.delayed(const Duration(milliseconds: 500));
  
  await initializeDateFormatting('ko_KR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AdState>(create: (_) => AdState()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Widget? _initialWidget;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initializeApp() async {
    try {
      // Check for initial deep link first
      _appLinks = AppLinks();
      
      // Set up listener for future deep links FIRST
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          print('Deep link stream received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          print('Deep link error: $err');
        },
      );
      
      final initialLink = await _appLinks.getInitialLink();
      print('Initial link check: $initialLink');
      
      if (initialLink != null && _shouldHandleDeepLink(initialLink)) {
        print('App launched with deep link: $initialLink');
        print('Setting initial widget to EventPage');
        setState(() {
          _initialWidget = EventPage();
          _isInitialized = true;
        });
      } else {
        print('No deep link found, showing SplashScreen');
        setState(() {
          _initialWidget = SplashScreen(onThemeChanged: (_) {});
          _isInitialized = true;
        });
      }
      
    } catch (e) {
      print('Failed to initialize app: $e');
      setState(() {
        _initialWidget = SplashScreen(onThemeChanged: (_) {});
        _isInitialized = true;
      });
    }
  }

  bool _shouldHandleDeepLink(Uri uri) {
    return uri.scheme == 'gigecha' && (uri.host == 'event' || uri.path == '/event');
  }


  void _handleDeepLink(Uri uri) {
    print('Received deep link: $uri');
    print('Current navigator state: ${navigatorKey.currentState}');
    
    if (uri.scheme == 'gigecha') {
      if (uri.host == 'event' || uri.path == '/event') {
        // If navigator is not ready, update the initial widget
        if (navigatorKey.currentState == null) {
          print('Navigator not ready, updating initial widget');
          setState(() {
            _initialWidget = EventPage();
          });
        } else {
          // Navigate directly to EventPage, bypassing splash screen and ads
          print('Navigator ready, pushing EventPage');
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => EventPage(),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show a loading indicator while determining initial route
      return MaterialApp(
        navigatorKey: navigatorKey,
        title: '지게차운전기능사 기출문제',
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          scaffoldBackgroundColor: Color(0xFFf2f4f8),
        ),
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        navigatorObservers: [observer],
      );
    }
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '지게차운전기능사 기출문제',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFf2f4f8),
      ),
      themeMode: ThemeMode.light,
      home: _initialWidget,
      navigatorObservers: [observer],
    );
  }
}