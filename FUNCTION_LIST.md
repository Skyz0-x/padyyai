# PaddyAI Application - Function List by User Access

## 2.3.5 User Access Function Table

| Function | Paddy Farmer | Pesticide Supplier | Administrator |
|----------|:-------------:|:------------------:|:-------------:|
| **Authentication & Account** | | | |
| 01 Register Account | / | / | |
| 02 Login Account | / | / | / |
| Sign Out | / | / | / |
| Google Sign In | / | / | / |
| Create/Update User Profile | / | / | / |
| **Disease Detection (AI)** | | | |
| 03 Capture/Upload Image | / | | |
| 04 Detect Disease | / | | |
| 05 View Detection Results | / | | |
| Save Detection to History | / | | |
| 06 View Detection History | / | | |
| Get Unique Disease Names | / | | |
| Update Detection Record | / | | |
| Delete Detection Record | / | | |
| **Farming Management** | | | |
| Add Field Record | / | | |
| View Field Records | / | | |
| Get Field Records Stats | / | | |
| Update Field Record | / | | |
| Delete Field Record | / | | |
| 07 Create Paddy Monitoring | / | | |
| View Paddy Monitoring | / | | |
| Mark as Harvested | / | | |
| Delete Paddy Monitoring | / | | |
| Update Monitoring Notes | / | | |
| **Farming Calendar & Reminders** | | | |
| 08 Create Farming Reminder | / | | |
| View Reminders | / | | |
| Get Pending Notifications | / | | |
| Mark Reminder Complete | / | | |
| 09 Delete Reminder | / | | |
| **Marketplace & Products** | | | |
| 10 Browse Products | / | | |
| Search Products | / | | |
| View Product Details | / | | |
| 11 Add Product to Cart | / | | |
| **Cart Management** | | | |
| 12 View Cart Items | / | | |
| Update Item Quantity | / | | |
| Remove Item from Cart | / | | |
| Clear Cart | / | | |
| Get Cart Item Count | / | | |
| **Orders (Buyer)** | | | |
| 13 Place Order | / | | |
| 14 View Orders | / | | |
| Track Order | / | | |
| Cancel Order | / | | |
| Get Order Statistics | / | | |
| Get Total Spent | / | | |
| **Payments** | | | |
| Process Payment | / | | |
| **Weather & Alerts** | | | |
| Get Location Name | / | | |
| 15 View Weather Data | / | | |
| Get Weather Alerts | / | | |
| **Chatbot** | | | |
| 16 Send Message to Chatbot | / | / | / |
| Save Chat Message | / | / | / |
| Clear Chat History | / | / | / |
| **Supplier Functions** | | | |
| 17 Submit/Add Product | | / | |
| Edit Product | | / | |
| 18 Manage Product Stock | | / | |
| Delete Product | | / | |
| View Products Dashboard | | / | |
| Get Supplier Profile | | / | |
| Update Supplier Profile | | / | |
| 19 Upload Certificate | | / | |
| View Dashboard Stats | | / | |
| **Supplier Orders** | | | |
| View Received Orders | | / | |
| 20 Approve Order | | / | |
| Ship Order (Add Tracking) | | / | |
| Cancel Order (Supplier) | | / | |
| Mark Notification as Read | | / | |
| Get Unread Notifications | | / | |
| **Admin Functions** | | | |
| View Admin Dashboard | | | / |
| 21 Approve Supplier Account | | | / |
| Reject Supplier Account | | | / |
| Update Supplier Status | | | / |
| Manage Users | | | / |
| View Product Statistics | | | / |
| View Pending Suppliers | | | / |
| Select AI Model | | | / |
| View Supplier Certificate | | | / |
| Get Product Stats | | | / |
| **AI Model Management** | | | |
| Get Selected Model | / | / | / |
| Set Selected Model | | | / |
| Get Normalization Method | / | / | / |
| Set Normalization Method | | | / |
| Run Model Diagnostics | | | / |

---

## Service Layer Functions (Organized by Service)

### 1. Authentication Services

#### AuthService
- `signIn()` - Sign in with email/password
- `signOut()` - Sign out user
- `getCurrentUser()` - Get current user info
- `isAuthenticated()` - Check if user is logged in
- `updateUserProfile()` - Update user information

#### GoogleAuthService
- `signInWithGoogle()` - Google Sign-In
- `_createOrUpdateUserProfile()` - Create/update profile on first sign-in
- `signOut()` - Sign out from Google
- `isSignedIn()` - Check Google sign-in status

---

### 2. AI & Disease Detection Services

#### DiseaseDetectionService
- `loadModel()` - Load TensorFlow Lite model
- `detectDisease()` - Analyze image and detect disease
- `getDiseaseInfo()` - Get disease information and treatment

#### DiseaseRecordsService
- `saveDetection()` - Save detection result to database
- `getDetections()` - Retrieve user's detection history
- `updateDetection()` - Update detection record
- `deleteDetection()` - Delete detection record
- `getUniqueDiseaseNames()` - Get all disease types detected

#### ModelManagerService
- `getSelectedModel()` - Get currently selected AI model
- `setSelectedModel()` - Set active AI model
- `getNormalizationMethod()` - Get image normalization method
- `setNormalizationMethod()` - Set normalization method
- `getModelDisplayName()` - Get model display name
- `getLabelsPathForModel()` - Get labels file path

#### ModelDiagnostic
- `runDiagnostics()` - Validate model configuration and compatibility

---

### 3. Field & Farm Management Services

#### FieldRecordsService
- `addFieldRecord()` - Add new field activity record
- `getFieldRecords()` - Get field records with filters
- `getFieldRecordsStats()` - Get statistics on field costs
- `updateFieldRecord()` - Update field record
- `deleteFieldRecord()` - Delete field record
- `cleanupOldRecords()` - Clean old records

#### PaddyMonitoringService
- `addPaddyMonitoring()` - Add paddy monitoring entry
- `getPaddyMonitoring()` - Get monitoring history
- `markAsHarvested()` - Mark paddy as harvested
- `deletePaddyMonitoring()` - Delete monitoring record
- `updateNotes()` - Update monitoring notes

---

### 4. Farming Reminders Service

#### FarmingRemindersService
- `createReminder()` - Create farming reminder
- `getReminders()` - Get user's reminders
- `markRemindersComplete()` - Mark reminders as done
- `deleteReminder()` - Delete reminder
- `getPendingNotificationsCount()` - Get pending notification count
- `getScheduleReminders()` - Get scheduled reminders
- `calculateSchedule()` - Calculate farming schedule

---

### 5. E-Commerce Services

#### ProductsService
- `getAllProducts()` - Get all marketplace products
- `getProductsByCategory()` - Filter by category
- `searchProducts()` - Search product catalog
- `addProduct()` - Add new product (supplier)
- `updateProduct()` - Update product details
- `deleteProduct()` - Delete product
- `toggleProductStock()` - Enable/disable product
- `getSupplierProducts()` - Get supplier's products

#### CartService
- `addToCart()` - Add product to cart
- `getCartItems()` - Get cart contents
- `updateQuantity()` - Update item quantity
- `removeFromCart()` - Remove item from cart
- `clearCart()` - Empty cart
- `getCartItemCount()` - Get cart item count

#### OrdersService
- `placeOrder()` - Create new order
- `getOrders()` - Get user's orders
- `getOrdersByStatus()` - Get orders by status
- `getOrderDetails()` - Get specific order details
- `updateOrderStatus()` - Update order status
- `cancelOrder()` - Cancel order
- `getTotalSpent()` - Calculate total spending

#### SupplierOrdersService
- `getSupplierOrders()` - Get orders for supplier
- `approveOrder()` - Approve order (supplier)
- `shipOrder()` - Ship order with tracking
- `cancelOrder()` - Cancel order (supplier)
- `markNotificationAsRead()` - Mark notification as read
- `getUnreadNotificationCount()` - Get unread count
- `_recordStatusChange()` - Log status changes

---

### 6. Communication Services

#### ChatService
- `sendMessage()` - Send message to chatbot
- `saveChatMessage()` - Save message to history
- `getChatHistory()` - Get chat conversation history
- `clearChatHistory()` - Clear chat history

#### WeatherService
- `getWeatherData()` - Get weather information
- `getLocationName()` - Get location name from coordinates
- `getWeatherAlerts()` - Get weather alerts

---

### 7. Admin Services

#### (Admin functions implemented in admin_dashboard.dart)
- `_loadPendingSuppliers()` - Get pending supplier approvals
- `_updateSupplierStatus()` - Approve/reject supplier
- `_confirmAndUpdate()` - Confirm supplier status update
- `_loadProductStats()` - Get product statistics
- `_loadSelectedModel()` - Get current AI model
- `_viewCertificate()` - View supplier certificate
- `_showAIModelDialog()` - Display model selection dialog

---

## Screen Functions (User Interaction Layer)

### Authentication Screens

#### LoginScreen
- `_loginUser()` - Handle user login

#### RegisterScreen
- `_signUp()` - Handle user registration
- `_signInWithGoogle()` - Handle Google Sign-In

#### RegistrationScreen
- `_registerUser()` - Register new user

---

### Farmer Screens

#### HomeScreen
- `_selectPlantingDate()` - Pick planting date
- `_loadSavedPaddyMonitoring()` - Load monitoring data
- `_savePaddyMonitoring()` - Save monitoring data
- `_generateScheduleReminders()` - Create reminders
- `_loadFarmingStats()` - Load farm statistics
- `_loadReminders()` - Load farming reminders
- `_loadMonthReminders()` - Load monthly reminders
- `_loadWeatherData()` - Load weather information

#### DetectScreen
- `_loadSettings()` - Load detection settings
- `_loadModel()` - Load AI model
- `_loadLabels()` - Load model labels
- `_loadTFLiteModel()` - Load TFLite model
- `_pickImage()` - Select image from device
- `_analyzeImage()` - Run disease detection
- `_saveDetectionToHistory()` - Save detection result
- `_imageToInputTensor()` - Convert image to tensor
- `_applySoftmax()` - Apply softmax to results

#### DetectHistoryScreen
- `_loadDetections()` - Load detection history

#### FieldRecordsScreen
- `_loadRecords()` - Load field records

#### WeatherAlertScreen
- `_loadWeatherData()` - Load weather alerts

#### ProfileScreen
- `_loadUserProfile()` - Load user profile
- `_loadFarmingStats()` - Load farming statistics

#### FarmerDashboard
- Dashboard overview functions

---

### Marketplace Screens

#### MarketplaceScreen
- `_loadProducts()` - Load product list
- `_loadCartCount()` - Get cart count
- `_addToCart()` - Add product to cart

#### CartScreen
- `_loadCartItems()` - Load cart contents
- `_updateQuantity()` - Update item quantity
- `_removeItem()` - Remove item from cart
- `_clearCart()` - Empty cart

#### PaymentScreen
- `_processPayment()` - Handle payment processing

#### OrdersScreen
- `_loadOrderCounts()` - Load order statistics

---

### Supplier Screens

#### SupplierDashboard
- `_loadUserProfile()` - Load supplier profile
- `_loadProducts()` - Load supplier's products
- `_loadDashboardStats()` - Load sales statistics

#### SupplierDetailsScreen
- `_pickCertificate()` - Pick certificate file
- `_pickFromGallery()` - Pick image from gallery
- `_pickFromCamera()` - Capture image from camera
- `_saveSupplierDetails()` - Save profile details

#### ManageProductsScreen
- `_loadProducts()` - Load supplier's products
- `_toggleProductStock()` - Enable/disable product
- `_deleteProduct()` - Delete product
- `_pickImage()` - Pick product image
- `_saveProduct()` - Save product details
- `_getEffectiveKeysForCategory()` - Get category fields

#### SupplierOrdersScreen
- `_loadOrders()` - Load supplier's orders
- `_handleApproveOrder()` - Approve order
- `_shipOrder()` - Ship order with tracking
- `_cancelOrder()` - Cancel order

#### SupplierSettingsScreen
- Settings management functions

---

### Admin Screens

#### AdminDashboard
- `_loadSelectedModel()` - Load AI model selection
- `_loadProductStats()` - Load product statistics
- `_loadPendingSuppliers()` - Load pending approvals
- `_confirmAndUpdate()` - Update supplier status
- `_updateSupplierStatus()` - Update supplier status
- `_viewCertificate()` - View certificate
- `_showAIModelDialog()` - Show model selection dialog

#### SupplierPendingScreen
- Supplier approval management

---

### Utility & Test Screens

#### NormalizationTestScreen
- `_pickImage()` - Pick image for testing
- `_testAllMethods()` - Test normalization methods

---

## Utility Functions

### RoleUtils
- `hasRole()` - Check if user has specific role
- `hasAnyRole()` - Check if user has any of roles
- `isFarmer()` - Check if user is farmer
- `isSupplier()` - Check if user is supplier
- `isAdmin()` - Check if user is admin
- `getRedirectRoute()` - Get navigation route based on role

---

## Configuration & Initialization

### SupabaseConfig
- `initialize()` - Initialize Supabase connection

### PaddyScheduleConfig
- `getScheduleForVariety()` - Get farming schedule
- `calculateScheduleDates()` - Calculate schedule dates

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Authentication Functions | 5 |
| AI & Disease Detection | 14 |
| Farm Management | 11 |
| Farming Reminders | 7 |
| E-Commerce | 19 |
| Communication | 4 |
| Admin Functions | 7 |
| Farmer Screens | 27 |
| Marketplace Screens | 10 |
| Supplier Screens | 20 |
| Admin Screens | 7 |
| Utility Functions | 6 |
| **TOTAL** | **~137** |

---

**Document Version**: 1.0  
**Last Updated**: December 19, 2025  
**Status**: Complete Function Inventory
