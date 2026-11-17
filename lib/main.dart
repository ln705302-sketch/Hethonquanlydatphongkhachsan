import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/app_reloader.dart';
import 'data/local_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/hotel_provider.dart';
import 'providers/promo_provider.dart';
import 'providers/search_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // URL dạng /rooms thay vì /#/rooms
  final storage = await LocalStorage.init();
  runApp(SunriseApp(storage: storage, api: ApiClient()));
}

class SunriseApp extends StatefulWidget {
  const SunriseApp({super.key, required this.storage, required this.api});

  final LocalStorage storage;
  final ApiClient api;

  @override
  State<SunriseApp> createState() => _SunriseAppState();
}

class _SunriseAppState extends State<SunriseApp> {
  late final AuthProvider _auth = AuthProvider(widget.api, widget.storage);
  late final HotelProvider _hotels = HotelProvider(widget.api);
  late final BookingProvider _bookings = BookingProvider(widget.api, _hotels);
  late final PromoProvider _promos = PromoProvider(widget.api);
  late final GoRouter _router = createRouter(_auth);
  String? _sessionUserId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _auth.init();
    await Future.wait([_hotels.load(), _reloadSession()]);
    _auth.addListener(_onAuthChanged);
    if (mounted) setState(() => _ready = true);
  }

  /// Đăng nhập / đăng xuất / đổi tài khoản -> tải lại dữ liệu theo quyền
  void _onAuthChanged() {
    if (_auth.currentUser?.id == _sessionUserId) return;
    _reloadSession();
  }

  Future<void> _reloadSession() async {
    final user = _auth.currentUser;
    _sessionUserId = user?.id;
    await Future.wait([
      _bookings.load(loggedIn: user != null),
      _promos.load(customer: user != null && !user.isStaff),
      _auth.loadUsers(),
      _hotels.loadReviews(),
    ]);
  }

  /// Tải lại toàn bộ (sau khi khôi phục dữ liệu mẫu hoặc khi kết nối lại)
  Future<void> _reloadAll() async {
    await _auth.init();
    await Future.wait([_hotels.load(), _reloadSession()]);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _hotels),
        ChangeNotifierProvider.value(value: _bookings),
        ChangeNotifierProvider.value(value: _promos),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        Provider<AppReloader>.value(value: AppReloader(_reloadAll)),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => _ready
            ? child!
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

