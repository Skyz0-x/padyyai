import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
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
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const PaddyAIApp());
}

class PaddyAIApp extends StatelessWidget {
  const PaddyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
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
      },
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: primaryGradient,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing PaddyAI...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const RoleBasedNavigation();
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
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> result = await _authService.getUserProfileAndNavigationInfo(currentUser.uid);
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
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading your dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt_outlined),
                  activeIcon: Icon(Icons.camera_alt),
                  label: 'Detect',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined),
                  activeIcon: Icon(Icons.shopping_bag),
                  label: 'Marketplace',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
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
      User? currentUser = FirebaseAuth.instance.currentUser;
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
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> result = await _authService.getUserProfileAndNavigationInfo(currentUser.uid);
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
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Verifying access...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
