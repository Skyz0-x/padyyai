import 'package:flutter_localization/flutter_localization.dart';

class AppLocale {
  static const String appName = 'appName';
  static const String welcome = 'welcome';
  static const String riceCultivation = 'riceCultivation';
  static const String pestManagement = 'pestManagement';
  static const String waterManagement = 'waterManagement';
  static const String plantingTips = 'plantingTips';
  static const String weatherConsiderations = 'weatherConsiderations';
  static const String howCanIHelp = 'howCanIHelp';
  static const String loadingDashboard = 'loadingDashboard';
  static const String verifyingAccess = 'verifyingAccess';
  static const String accessDenied = 'accessDenied';
  static const String accountUnderReview = 'accountUnderReview';
  static const String signInToAccess = 'signInToAccess';
  static const String switchLanguage = 'switchLanguage';
  static const String profile = 'profile';
  static const String home = 'home';
  static const String detect = 'detect';
  static const String marketplace = 'marketplace';
  static const String orders = 'orders';
  static const String chat = 'chat';
  static const String cart = 'cart';
  static const String settings = 'settings';
  static const String editProfile = 'editProfile';
  static const String updatePersonalInfo = 'updatePersonalInfo';
  static const String myOrders = 'myOrders';
  static const String trackOrders = 'trackOrders';
  static const String detectionHistory = 'detectionHistory';
  static const String viewScans = 'viewScans';
  static const String viewCart = 'viewCart';
  static const String notifications = 'notifications';
  static const String manageAlerts = 'manageAlerts';
  static const String helpSupport = 'helpSupport';
  static const String getAssistance = 'getAssistance';
  static const String privacyPolicy = 'privacyPolicy';
  static const String readPolicies = 'readPolicies';
  static const String signOut = 'signOut';
  static const String logoutAccount = 'logoutAccount';
  static const String memberSince = 'memberSince';
  static const String yourFarmingJourney = 'yourFarmingJourney';
  static const String scansCompleted = 'scansCompleted';
  static const String diseasesFound = 'diseasesFound';
  static const String ordersPlaced = 'ordersPlaced';
  static const String healthyPlants = 'healthyPlants';
  static const String totalInvested = 'totalInvested';
  static const String version = 'version';
  static const String smartFarming = 'smartFarming';
  static const String rateApp = 'rateApp';
  static const String share = 'share';
  static const String signOutConfirm = 'signOutConfirm';
  static const String cancel = 'cancel';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String riceFarmingAssistant = 'riceFarmingAssistant';
  static const String expertAdvice = 'expertAdvice';
  static const String clearChat = 'clearChat';
  static const String clearConversation = 'clearConversation';
  static const String clear = 'clear';
  static const String typeMessage = 'typeMessage';
  static const String send = 'send';
  static const String error = 'error';
  static const String tryAgain = 'tryAgain';
  static const String loading = 'loading';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String all = 'all';
  static const String sortBy = 'sortBy';
  static const String priceLowest = 'priceLowest';
  static const String priceHighest = 'priceHighest';
  static const String newest = 'newest';
  static const String popular = 'popular';
  static const String addToCart = 'addToCart';
  static const String buyNow = 'buyNow';
  static const String outOfStock = 'outOfStock';
  static const String inStock = 'inStock';
  static const String price = 'price';
  static const String quantity = 'quantity';
  static const String total = 'total';
  static const String checkout = 'checkout';
  static const String emptyCart = 'emptyCart';
  static const String continueShopping = 'continueShopping';
  static const String toPay = 'toPay';
  static const String toShip = 'toShip';
  static const String toReceive = 'toReceive';
  static const String toReview = 'toReview';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String orderDetails = 'orderDetails';
  static const String trackOrder = 'trackOrder';
  static const String contactSeller = 'contactSeller';
  static const String leaveReview = 'leaveReview';
  static const String cancelOrder = 'cancelOrder';
  static const String detectDisease = 'detectDisease';
  static const String takePhoto = 'takePhoto';
  static const String chooseFromGallery = 'chooseFromGallery';
  static const String analyzing = 'analyzing';
  static const String aiReady = 'aiReady';
  static const String loadingAI = 'loadingAI';
  static const String aiModelReady = 'aiModelReady';
  static const String tapToDetect = 'tapToDetect';
  static const String recommendations = 'recommendations';
  static const String treatment = 'treatment';
  static const String prevention = 'prevention';
  static const String dashboard = 'dashboard';
  static const String weatherToday = 'weatherToday';
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String rainfall = 'rainfall';
  static const String windSpeed = 'windSpeed';
  static const String forecast = 'forecast';
  static const String quickActions = 'quickActions';
  static const String scanCrop = 'scanCrop';
  static const String viewHistory = 'viewHistory';
  static const String shopProducts = 'shopProducts';
  static const String chatBot = 'chatBot';
  static const String recentActivity = 'recentActivity';
  static const String noActivity = 'noActivity';
  static const String viewAll = 'viewAll';
  static const String readyToTakeCare = 'readyToTakeCare';
  static const String scanCrops = 'scan_crops';
  static const String findSupplies = 'find_supplies';
  static const String weatherAlert = 'weather_alert';
  static const String checkForecast = 'check_forecast';

  static final List<MapLocale> LOCALES = [
    MapLocale(
      'en',
      LocaleData.en,
    ),
    MapLocale(
      'ms',
      LocaleData.ms,
    ),
  ];
}

mixin LocaleData {
  static const Map<String, dynamic> en = {
    'appName': 'PaddyAI',
    'welcome': 'Hello! 👋 I\'m your rice farming assistant.',
    'riceCultivation': 'Rice cultivation techniques',
    'pestManagement': 'Pest and disease management',
    'waterManagement': 'Water and fertilizer management',
    'plantingTips': 'Planting and harvesting tips',
    'weatherConsiderations': 'Weather considerations',
    'howCanIHelp': 'How can I help you today?',
    'loadingDashboard': 'Loading your dashboard...',
    'verifyingAccess': 'Verifying access...',
    'accessDenied': 'Access Denied',
    'accountUnderReview': 'Account Under Review',
    'signInToAccess': 'Sign in to access your account',
    'switchLanguage': 'Switch Language',
    'profile': 'Profile',
    'home': 'Home',
    'detect': 'Detect',
    'marketplace': 'Marketplace',
    'orders': 'Orders',
    'chat': 'Chat',
    'cart': 'Cart',
    'settings': 'Settings',
    'editProfile': 'Edit Profile',
    'updatePersonalInfo': 'Update your personal information',
    'myOrders': 'My Orders',
    'trackOrders': 'Track and manage your orders',
    'detectionHistory': 'History',
    'viewScans': 'Previous scans',
    'viewCart': 'View items in your shopping cart',
    'notifications': 'Notifications',
    'manageAlerts': 'Manage your alert preferences',
    'helpSupport': 'Help & Support',
    'getAssistance': 'Get assistance and report issues',
    'privacyPolicy': 'Privacy Policy',
    'readPolicies': 'Read our privacy and data policies',
    'signOut': 'Sign Out',
    'logoutAccount': 'Log out of your account',
    'memberSince': 'Member since',
    'yourFarmingJourney': 'Your Farming Journey',
    'scansCompleted': 'Scans Completed',
    'diseasesFound': 'Diseases Found',
    'ordersPlaced': 'Orders Placed',
    'healthyPlants': 'Healthy Plants',
    'totalInvested': 'Total Invested',
    'version': 'Version',
    'smartFarming': 'Smart farming solutions for better crop health',
    'rateApp': 'Rate App',
    'share': 'Share',
    'signOutConfirm': 'Are you sure you want to sign out of your account?',
    'cancel': 'Cancel',
    'yes': 'Yes',
    'no': 'No',
    'riceFarmingAssistant': 'Rice Farming Assistant',
    'expertAdvice': 'Get expert farming advice',
    'clearChat': 'Clear Chat',
    'clearConversation': 'Are you sure you want to clear the conversation?',
    'clear': 'Clear',
    'typeMessage': 'Type a message...',
    'send': 'Send',
    'error': 'Error',
    'tryAgain': 'Please try again',
    'loading': 'Loading...',
    'search': 'Search',
    'filter': 'Filter',
    'all': 'All',
    'sortBy': 'Sort By',
    'priceLowest': 'Price: Low to High',
    'priceHighest': 'Price: High to Low',
    'newest': 'Newest',
    'popular': 'Most Popular',
    'addToCart': 'Add to Cart',
    'buyNow': 'Buy Now',
    'outOfStock': 'Out of Stock',
    'inStock': 'In Stock',
    'price': 'Price',
    'quantity': 'Quantity',
    'total': 'Total',
    'checkout': 'Checkout',
    'emptyCart': 'Your cart is empty',
    'continueShopping': 'Continue Shopping',
    'toPay': 'To Pay',
    'toShip': 'To Ship',
    'toReceive': 'To Receive',
    'toReview': 'To Review',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'orderDetails': 'Order Details',
    'trackOrder': 'Track Order',
    'contactSeller': 'Contact Seller',
    'leaveReview': 'Leave Review',
    'cancelOrder': 'Cancel Order',
    'detectDisease': 'Detect Disease',
    'takePhoto': 'Take Photo',
    'chooseFromGallery': 'Choose from Gallery',
    'analyzing': 'Analyzing...',
    'aiReady': 'AI Ready',
    'loadingAI': 'Loading AI...',
    'aiModelReady': 'AI Model Ready',
    'tapToDetect': 'Tap to detect diseases',
    'recommendations': 'Recommendations',
    'treatment': 'Treatment',
    'prevention': 'Prevention',
    'dashboard': 'Dashboard',
    'weatherToday': 'Weather Today',
    'temperature': 'Temperature',
    'humidity': 'Humidity',
    'rainfall': 'Rainfall',
    'windSpeed': 'Wind Speed',
    'forecast': 'Forecast',
    'quickActions': 'Quick Actions',
    'scanCrop': 'Scan Crop',
    'viewHistory': 'View History',
    'shopProducts': 'Shop Products',
    'chatBot': 'Chat Bot',
    'recentActivity': 'Recent Activity',
    'noActivity': 'No recent activity',
    'viewAll': 'View All',
    'readyToTakeCare': 'Ready to take care of your crops today?',
    'scan_crops': 'Scan your crops',
    'find_supplies': 'Find supplies',
    'weather_alert': 'Weather Alert',
    'check_forecast': 'Check forecast',
  };

  static const Map<String, dynamic> ms = {
    'appName': 'PaddyAI',
    'welcome': 'Hai! 👋 Saya pembantu penanaman padi anda.',
    'riceCultivation': 'Teknik penanaman padi',
    'pestManagement': 'Pengurusan perosak dan penyakit',
    'waterManagement': 'Pengurusan air dan baja',
    'plantingTips': 'Petua penanaman dan penuaian',
    'weatherConsiderations': 'Pertimbangan cuaca',
    'howCanIHelp': 'Bagaimana saya boleh membantu anda hari ini?',
    'loadingDashboard': 'Memuatkan papan pemuka anda...',
    'verifyingAccess': 'Mengesahkan akses...',
    'accessDenied': 'Akses Ditolak',
    'accountUnderReview': 'Akaun Dalam Semakan',
    'signInToAccess': 'Log masuk untuk mengakses akaun anda',
    'switchLanguage': 'Tukar Bahasa',
    'profile': 'Profil',
    'home': 'Utama',
    'detect': 'Kesan',
    'marketplace': 'Pasaran',
    'orders': 'Pesanan',
    'chat': 'Sembang',
    'cart': 'Troli',
    'settings': 'Tetapan',
    'editProfile': 'Sunting Profil',
    'updatePersonalInfo': 'Kemas kini maklumat peribadi anda',
    'myOrders': 'Pesanan Saya',
    'trackOrders': 'Jejak dan urus pesanan anda',
    'detectionHistory': 'Sejarah Imbasan',
    'viewScans': 'Lihat imbasan anda',
    'viewCart': 'Lihat item dalam troli beli-belah anda',
    'notifications': 'Notifikasi',
    'manageAlerts': 'Urus keutamaan makluman anda',
    'helpSupport': 'Bantuan & Sokongan',
    'getAssistance': 'Dapatkan bantuan dan laporkan masalah',
    'privacyPolicy': 'Dasar Privasi',
    'readPolicies': 'Baca dasar privasi dan data kami',
    'signOut': 'Log Keluar',
    'logoutAccount': 'Log keluar dari akaun anda',
    'memberSince': 'Ahli sejak',
    'yourFarmingJourney': 'Perjalanan Pertanian Anda',
    'scansCompleted': 'Imbasan Selesai',
    'diseasesFound': 'Penyakit Ditemui',
    'ordersPlaced': 'Pesanan Dibuat',
    'healthyPlants': 'Tanaman Sihat',
    'totalInvested': 'Jumlah Pelaburan',
    'version': 'Versi',
    'smartFarming': 'Penyelesaian pertanian pintar untuk kesihatan tanaman yang lebih baik',
    'rateApp': 'Nilai Aplikasi',
    'share': 'Kongsi',
    'signOutConfirm': 'Adakah anda pasti mahu log keluar dari akaun anda?',
    'cancel': 'Batal',
    'yes': 'Ya',
    'no': 'Tidak',
    'riceFarmingAssistant': 'Pembantu Pertanian Padi',
    'expertAdvice': 'Dapatkan nasihat pertanian pakar',
    'clearChat': 'Kosongkan Sembang',
    'clearConversation': 'Adakah anda pasti mahu mengosongkan perbualan?',
    'clear': 'Kosongkan',
    'typeMessage': 'Taip mesej...',
    'send': 'Hantar',
    'error': 'Ralat',
    'tryAgain': 'Sila cuba lagi',
    'loading': 'Memuatkan...',
    'search': 'Cari',
    'filter': 'Tapis',
    'all': 'Semua',
    'sortBy': 'Isih Mengikut',
    'priceLowest': 'Harga: Rendah ke Tinggi',
    'priceHighest': 'Harga: Tinggi ke Rendah',
    'newest': 'Terbaharu',
    'popular': 'Paling Popular',
    'addToCart': 'Tambah ke Troli',
    'buyNow': 'Beli Sekarang',
    'outOfStock': 'Kehabisan Stok',
    'inStock': 'Dalam Stok',
    'price': 'Harga',
    'quantity': 'Kuantiti',
    'total': 'Jumlah',
    'checkout': 'Bayar',
    'emptyCart': 'Troli anda kosong',
    'continueShopping': 'Teruskan Membeli-belah',
    'toPay': 'Untuk Bayar',
    'toShip': 'Untuk Hantar',
    'toReceive': 'Untuk Terima',
    'toReview': 'Untuk Ulasan',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    'orderDetails': 'Butiran Pesanan',
    'trackOrder': 'Jejak Pesanan',
    'contactSeller': 'Hubungi Penjual',
    'leaveReview': 'Tinggalkan Ulasan',
    'cancelOrder': 'Batal Pesanan',
    'detectDisease': 'Kesan Penyakit',
    'takePhoto': 'Ambil Gambar',
    'chooseFromGallery': 'Pilih dari Galeri',
    'analyzing': 'Menganalisis...',
    'aiReady': 'AI Sedia',
    'loadingAI': 'Memuatkan AI...',
    'aiModelReady': 'Model AI Sedia',
    'tapToDetect': 'Ketik untuk mengesan penyakit',
    'recommendations': 'Cadangan',
    'treatment': 'Rawatan',
    'prevention': 'Pencegahan',
    'dashboard': 'Papan Pemuka',
    'weatherToday': 'Cuaca Hari Ini',
    'temperature': 'Suhu',
    'humidity': 'Kelembapan',
    'rainfall': 'Hujan',
    'windSpeed': 'Kelajuan Angin',
    'forecast': 'Ramalan',
    'quickActions': 'Tindakan Pantas',
    'scanCrop': 'Imbas Tanaman',
    'viewHistory': 'Lihat Sejarah',
    'shopProducts': 'Beli Produk',
    'chatBot': 'Bot Sembang',
    'recentActivity': 'Aktiviti Terkini',
    'noActivity': 'Tiada aktiviti terkini',
    'viewAll': 'Lihat Semua',
    'readyToTakeCare': 'Bersedia untuk menjaga tanaman anda hari ini?',
    'scan_crops': 'Imbas tanaman anda',
    'find_supplies': 'Cari bekalan',
    'weather_alert':  'Cuaca',
    'check_forecast': 'Semak ramalan',
  };
}
