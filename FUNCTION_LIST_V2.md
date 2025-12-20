# FunctionListV2 – Focus Functions for SRS/SDD/STD

## Focus Scope (21 Functions)

| # | Function | Primary Role(s) | Screen Layer | Service Layer |
|---|----------|-----------------|--------------|---------------|
| 01 | Register Account | Farmer, Supplier | [lib/screens/register_screen.dart](lib/screens/register_screen.dart) | [lib/services/auth_service.dart](lib/services/auth_service.dart) |
| 02 | Login Account | Farmer, Supplier, Admin | [lib/screens/login_screen.dart](lib/screens/login_screen.dart) | [lib/services/auth_service.dart](lib/services/auth_service.dart) |
| 03 | Capture/Upload Image | Farmer | [lib/screens/detect_screen.dart](lib/screens/detect_screen.dart#L200) | — |
| 04 | Detect Disease | Farmer | [lib/screens/detect_screen.dart](lib/screens/detect_screen.dart#L223) | [lib/services/disease_detection_service.dart](lib/services/disease_detection_service.dart) |
| 05 | View Detection Results | Farmer | [lib/screens/detect_screen.dart](lib/screens/detect_screen.dart#L223) | — |
| 06 | View Detection History | Farmer | [lib/screens/detect_history_screen.dart](lib/screens/detect_history_screen.dart#L49) | [lib/services/disease_records_service.dart](lib/services/disease_records_service.dart) |
| 07 | Create Paddy Monitoring | Farmer | [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L190) | [lib/services/paddy_monitoring_service.dart](lib/services/paddy_monitoring_service.dart) |
| 08 | Create Farming Reminder | Farmer | [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L246) | [lib/services/farming_reminders_service.dart](lib/services/farming_reminders_service.dart) |
| 09 | Delete Reminder | Farmer | [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L246) | [lib/services/farming_reminders_service.dart](lib/services/farming_reminders_service.dart) |
| 10 | Browse Product | Farmer | [lib/screens/marketplace_screen.dart](lib/screens/marketplace_screen.dart#L84) | [lib/services/products_service.dart](lib/services/products_service.dart) |
| 11 | Add to Cart | Farmer | [lib/screens/marketplace_screen.dart](lib/screens/marketplace_screen.dart#L120) | [lib/services/cart_service.dart](lib/services/cart_service.dart) |
| 12 | View Cart | Farmer | [lib/screens/cart_screen.dart](lib/screens/cart_screen.dart#L28) | [lib/services/cart_service.dart](lib/services/cart_service.dart) |
| 13 | Place Order | Farmer | [lib/screens/payment_screen.dart](lib/screens/payment_screen.dart#L69) | [lib/services/orders_service.dart](lib/services/orders_service.dart) |
| 14 | View Orders | Farmer | [lib/screens/orders_screen.dart](lib/screens/orders_screen.dart#L39) | [lib/services/orders_service.dart](lib/services/orders_service.dart) |
| 15 | View Weather Alerts | Farmer | [lib/screens/weather_alert_screen.dart](lib/screens/weather_alert_screen.dart#L31) | [lib/services/weather_service.dart](lib/services/weather_service.dart) |
| 16 | Send Message Chatbot | Farmer, Supplier, Admin | [lib/screens/chat_bot_screen.dart](lib/screens/chat_bot_screen.dart#L47) | [lib/services/chat_service.dart](lib/services/chat_service.dart) |
| 17 | Submit/Add Product | Supplier | [lib/screens/manage_products_screen.dart](lib/screens/manage_products_screen.dart#L1147) | [lib/services/products_service.dart](lib/services/products_service.dart) |
| 18 | Manage Product (edit/stock/delete) | Supplier | [lib/screens/manage_products_screen.dart](lib/screens/manage_products_screen.dart#L523) | [lib/services/products_service.dart](lib/services/products_service.dart) |
| 19 | Upload Certificate | Supplier | [lib/screens/supplier_details_screen.dart](lib/screens/supplier_details_screen.dart#L44) | Supabase storage via details screen flow |
| 20 | Approve Order | Supplier | [lib/screens/supplier_orders_screen.dart](lib/screens/supplier_orders_screen.dart#L1142) | [lib/services/supplier_orders_service.dart](lib/services/supplier_orders_service.dart) |
| 21 | Approve Supplier Account | Admin | [lib/screens/admin_dashboard.dart](lib/screens/admin_dashboard.dart#L81) | Supabase RPC/queries in admin dashboard |

## Role Emphasis
- Farmer: 01–16 (core user journey: register/login → detect → monitor → remind → shop → order → weather/chat).
- Supplier: 01–02, 16–20 (catalog, certificates, fulfill orders).
- Admin: 02, 16, 21 (approvals, oversight).

## SRS Pointers (what to specify)
- Preconditions: authentication required; role-based guard per function; network/storage available; model loaded (03–05).
- Inputs/Outputs: image file + metadata (03–05); product payloads (17–18); order/cart payloads (10–14); reminder params (08–09); certificate file (19).
- Error Handling: upload failures, inference errors, payment/checkout errors, permission denials, missing tracking number (20), duplicate submissions.
- Non-Functional: latency targets for inference and search; availability for order/cart operations; security for file uploads and PII.

## SDD Pointers (how it’s built)
- Flow: Screen widget → service → Supabase/Storage/TFLite; navigation guarded by role utils.
- Key deps: Supabase auth/db/storage, TFLite model files, payment provider, weather API, image_picker.
- State: local widget state for forms; async loading indicators for detect/cart/orders; caching as needed.
- Data contracts: DTOs for products, orders, reminders, detections; ensure consistent keys with Supabase tables.

## STD Pointers (how to test)
- Auth: positive/negative login/register; role access enforced on protected screens.
- AI: image types/size limits; detect success/fail; history creation/view/delete.
- Reminders: create/delete; due notifications count.
- Commerce: browse/search, add/remove/update cart, place order happy path and failure (payment rejection, stock 0), order status visibility.
- Supplier: add/edit/delete/toggle product; certificate upload validation; approve/ship/cancel order flows with tracking required.
- Admin: approve/reject supplier; visibility of pending suppliers; role-restricted access.

## Keep Everything Else
This file highlights the 21 focus functions only; all other functions in FUNCTION_LIST.md remain in use and unchanged.
