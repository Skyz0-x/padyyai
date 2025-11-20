# Supplier Orders Screen - Quick Guide

## Overview
New screen created for suppliers to view and manage orders from farmers.

## Features

### 📊 Order Management Dashboard
- **4 Tabs**: All Orders, To Ship, Shipped, Completed
- **Real-time counts**: Badge indicators showing pending orders in each tab
- **Farmer information**: See which farmer placed each order
- **Order details**: View order number, items, quantities, and total amount

### 🚚 Order Actions by Status

#### To Ship (Pending Orders)
- **Ship Order**: Add tracking number and mark as shipped
- **Cancel Order**: Cancel with optional reason

#### Shipped (In Transit)
- **View Details**: Check tracking number and delivery information

#### Completed
- **View Receipt**: See full order history

### 💡 Features
- Pull to refresh
- Gradient themed UI matching app design
- Order filtering by status
- Farmer contact information display
- Product images and details
- Date formatting
- Error handling with retry option

## How to Access

1. **From Supplier Dashboard**: Click "View Orders" button
2. **Direct Route**: `/supplier-orders`

## Database Integration

The screen uses `SupplierOrdersService` which:
- Fetches orders assigned to the logged-in supplier
- Filters by `supplier_id` from orders table
- Joins with:
  - `order_items` - Order line items
  - `products` - Product details and images
  - `profiles` - Farmer/customer information

## Order Flow for Suppliers

```
1. Order appears in "To Ship" tab
   ↓
2. Supplier reviews order details
   ↓
3. Supplier ships order with tracking number
   ↓
4. Order moves to "Shipped" tab
   ↓
5. Farmer confirms receipt
   ↓
6. Order moves to "Completed" tab
```

## Actions Available

### Ship Order Dialog
- Enter tracking number (required)
- Automatically updates status to "to_receive"
- Records timestamp in `shipped_at`

### Cancel Order Dialog
- Enter cancellation reason (optional)
- Updates status to "cancelled"
- Logs reason in order history

### View Details
- Order number
- Payment method
- Tracking number
- Delivery address
- Total amount

## Technical Details

**File**: `lib/screens/supplier_orders_screen.dart`
**Service**: `lib/services/supplier_orders_service.dart`
**Route**: `/supplier-orders`
**Role Required**: `supplier`

## UI Components

- **Header**: Gradient green header with back button
- **Tab Bar**: Rounded white container with badges
- **Order Cards**: 
  - Gradient header with order number and farmer name
  - Product list with images
  - Status badges with icons
  - Action buttons based on status
- **Empty States**: Friendly messages when no orders
- **Error States**: Retry button on failures

## Related Files Modified

1. `lib/main.dart` - Added route for supplier orders
2. `lib/screens/supplier_dashboard.dart` - Updated "View Orders" button
3. `lib/services/supplier_orders_service.dart` - Added farmer profile join

## Next Steps

To fully utilize this feature:
1. Ensure `orders` table has `supplier_id` column
2. Run `update_orders_flow.sql` migration
3. Test order placement from farmer side
4. Verify orders appear in supplier dashboard
