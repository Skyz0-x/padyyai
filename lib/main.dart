import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'utils/constants.dart';
import 'widgets/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/farmer_dashboard.dart';
import 'screens/supplier_dashboard.dart';
import 'screens/supplier_details_screen.dart';
import 'screens/supplier_pending_screen.dart';
import 'screens/supplier_orders_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/cart_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/chat_bot_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/detect_history_screen.dart';
import 'services/auth_service.dart';
import 'l10n/app_locale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase instead of Firebase
    await SupabaseConfig.initialize();
    debugPrint("Supabase initialized successfully");
  } catch (e) {
    debugPrint("Supabase initialization failed: $e");
  }
  
  // Initialize FlutterLocalization
  final localization = FlutterLocalization.instance;
  await localization.ensureInitialized();
  
  runApp(const PaddyAIApp());
}

class PaddyAIApp extends StatefulWidget {
  const PaddyAIApp({super.key});

  @override
  State<PaddyAIApp> createState() => _PaddyAIAppState();
}

class _PaddyAIAppState extends State<PaddyAIApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {
    super.initState();
    _localization.init(
      mapLocales: AppLocale.LOCALES,
      initLanguageCode: 'en',
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaddyAI',
      debugShowCheckedModeBanner: false,
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineSmall: headingStyle,
          bodyMedium: bodyStyle,
          labelLarge: bodyStyle,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: primaryButtonStyle,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      // Add named routes
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const RoleGuard(allowedRoles: ['farmer'], child: MainAppScreen()),
        '/farmer-dashboard': (context) => const RoleGuard(allowedRoles: ['farmer'], child: FarmerDashboard()),
        '/supplier-dashboard': (context) => const RoleGuard(allowedRoles: ['supplier'], child: SupplierDashboard()),
        '/supplier-details': (context) => const RoleGuard(allowedRoles: ['supplier'], child: SupplierDetailsScreen()),
        '/supplier-pending': (context) => const RoleGuard(allowedRoles: ['supplier'], child: SupplierPendingScreen()),
        '/supplier-orders': (context) => const RoleGuard(allowedRoles: ['supplier'], child: SupplierOrdersScreen()),
        '/admin-dashboard': (context) => const RoleGuard(allowedRoles: ['admin'], child: AdminDashboard()),
        '/cart': (context) => const RoleGuard(allowedRoles: ['farmer'], child: CartScreen()),
        '/payment': (context) => const RoleGuard(allowedRoles: ['farmer'], child: PaymentScreen()),
        '/chat': (context) => const RoleGuard(allowedRoles: ['farmer'], child: ChatBotScreen()),
        '/orders': (context) => const RoleGuard(allowedRoles: ['farmer'], child: OrdersScreen()),
        '/detect-history': (context) => const RoleGuard(allowedRoles: ['farmer'], child: DetectHistoryScreen()),
      },
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Center(
                child: Image.asset(
                  'assets/video/loading screen.gif',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const RoleBasedNavigation();
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}

class RoleBasedNavigation extends StatefulWidget {
  const RoleBasedNavigation({super.key});

  @override
  State<RoleBasedNavigation> createState() => _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends State<RoleBasedNavigation> {
  final AuthService _authService = AuthService();
  String? _navigationRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineNavigationRoute();
  }

  Future<void> _determineNavigationRoute() async {
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> result = await _authService.getUserProfileAndNavigationInfo(currentUser.id);
        setState(() {
          _navigationRoute = result['navigationRoute'];
          _isLoading = false;
        });
      } else {
        // No user, redirect to login
        setState(() {
          _navigationRoute = '/login';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error determining navigation route: $e');
      // If there's an error, log out the user and redirect to login
      await _authService.signOut();
      setState(() {
        _navigationRoute = '/login';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    // Navigate to the appropriate screen based on user role
    switch (_navigationRoute) {
      case '/home':
        return const MainAppScreen(); // Farmers go to main app
      case '/supplier-dashboard':
        return const SupplierDashboard(); // Approved suppliers
      case '/supplier-pending':
        return const SupplierPendingScreen(); // Pending suppliers
      case '/supplier-details':
        return const SupplierDetailsScreen(); // Suppliers need to complete details
      case '/admin-dashboard':
        return const AdminDashboard(); // Admin dashboard
      case '/login':
      default:
        return const LoginScreen(); // Fallback to login
    }
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => MainAppScreenState();
}

class MainAppScreenState extends State<MainAppScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;
  String? _diseaseFilter;

  List<Widget> get _screens => [
    const HomeScreen(),
    const DetectScreen(),
    MarketplaceScreen(diseaseFilter: _diseaseFilter),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeInOut,
    ));
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void navigateToMarketplaceWithFilter(String diseaseFilter) {
    setState(() {
      _diseaseFilter = diseaseFilter;
      _selectedIndex = 2; // Marketplace tab
    });
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _navAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: AppLocale.home.getString(context),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.camera_alt_outlined),
                  activeIcon: const Icon(Icons.camera_alt),
                  label: AppLocale.detect.getString(context),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  activeIcon: const Icon(Icons.shopping_bag),
                  label: AppLocale.marketplace.getString(context),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: AppLocale.profile.getString(context),
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class RoleGuard extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      User? currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser != null) {
        Map<String, dynamic>? userProfile = await _authService.getCurrentUserProfile();
        
        if (userProfile != null) {
          String userRole = userProfile['role'] ?? '';
          bool isAuthorized = widget.allowedRoles.contains(userRole);
          
          setState(() {
            _isAuthorized = isAuthorized;
            _isLoading = false;
          });

          if (!isAuthorized) {
            // User is not authorized for this screen, redirect them to their appropriate screen
            _redirectToUserScreen(userProfile);
          }
        } else {
          _redirectToLogin();
        }
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      print('❌ Error checking user role: $e');
      _redirectToLogin();
    }
  }

  void _redirectToUserScreen(Map<String, dynamic> userProfile) async {
    try {
      User? currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> result = await _authService.getUserProfileAndNavigationInfo(currentUser.id);
        String correctRoute = result['navigationRoute'] ?? '/login';
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, correctRoute);
        }
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      print('❌ Error redirecting user: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    if (!_isAuthorized) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Redirecting to your dashboard...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
