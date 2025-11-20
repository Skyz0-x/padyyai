# Order Flow Implementation Guide

## 📋 Overview
This guide explains the improved order management system with supplier notifications and approval workflow.

## 🔄 Order Flow Diagram

```
1. Customer places order + payment
   ↓
2. Order created with status: 'to_pay' (COD) or 'to_ship' (paid)
   ↓
3. System auto-assigns supplier based on products
   ↓
4. Supplier receives notification
   ↓
5. Supplier approves and ships order (status: 'to_receive')
   ↓
6. Customer confirms receipt (status: 'to_review')
   ↓
7. Customer writes review (status: 'completed')
```

## 📊 Order Status Flow

| Status | Description | Who can update |
|--------|-------------|----------------|
| `to_pay` | Awaiting payment (COD orders) | Customer pays on delivery |
| `to_ship` | Paid, awaiting supplier approval | Supplier approves |
| `to_receive` | Shipped, awaiting customer receipt | Customer confirms |
| `to_review` | Delivered, awaiting review | Customer reviews |
| `completed` | Order completed | System (after review) |
| `cancelled` | Order cancelled | Customer or Supplier |

## 🗄️ Database Changes Required

### 1. Run SQL Migration

Execute the following SQL file in Supabase Dashboard:
```
supabase_migrations/update_orders_flow.sql
```

This will:
- ✅ Add new columns to `orders` table (tracking_number, supplier_id, timestamps)
- ✅ Create `order_notifications` table for supplier alerts
- ✅ Create `order_status_history` table for audit trail
- ✅ Create function to auto-assign supplier to orders
- ✅ Create function to update status with history tracking
- ✅ Set up RLS policies for security
- ✅ Create trigger to notify supplier on new order

### 2. Update Products Table

**IMPORTANT**: You need to add `supplier_id` column to your `products` table:

```sql
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES auth.users(id);

-- Update existing products with a default supplier
-- Replace 'YOUR_SUPPLIER_USER_ID' with actual supplier UUID
UPDATE public.products 
SET supplier_id = 'YOUR_SUPPLIER_USER_ID' 
WHERE supplier_id IS NULL;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_products_supplier_id 
ON public.products(supplier_id);
```

## 🔧 Implementation Steps

### Step 1: Run Database Migrations

1. Open Supabase Dashboard → SQL Editor
2. Copy and paste `update_orders_flow.sql`
3. Click "Run"
4. Add `supplier_id` to products table (see above)

### Step 2: Update Existing Orders (Optional)

If you have existing orders, update their status:

```sql
-- Update existing pending orders to 'to_ship'
UPDATE public.orders 
SET status = 'to_ship' 
WHERE status = 'pending' AND payment_status = 'completed';

-- Update existing pending COD orders to 'to_pay'
UPDATE public.orders 
SET status = 'to_pay' 
WHERE status = 'pending' AND payment_method = 'cash_on_delivery';
```

### Step 3: Test the Flow

1. **Place an order** as a customer
2. **Check supplier dashboard** → Should see notification
3. **Supplier approves** → Order moves to 'to_ship'
4. **Supplier ships** → Order moves to 'to_receive' (add tracking number)
5. **Customer confirms receipt** → Order moves to 'to_review'
6. **Customer reviews** → Order moves to 'completed'

## 📱 How It Works

### For Customers:

1. **Place Order** → Payment screen
2. **Track Order** → Orders screen shows status
3. **Receive Order** → Click "Confirm Receipt"
4. **Review** → Write product review

### For Suppliers:

1. **Receive Notification** → New order alert
2. **Review Order** → Check order details
3. **Approve & Ship** → Add tracking number
4. **Order Updates** → Customer can track

## 🎯 Services Available

### `OrdersService` (Customer)
- `getUserOrders()` - Get all customer orders
- `getOrdersByStatus(status)` - Filter by status
- `updateOrderStatus(orderId, status)` - Update status
- `getOrderStatusCounts()` - Get counts for each status

### `SupplierOrdersService` (Supplier)
- `getSupplierOrders()` - Get all supplier orders
- `getPendingApprovalOrders()` - Orders awaiting approval
- `approveOrder(orderId, trackingNumber)` - Approve and ship
- `shipOrder(orderId, trackingNumber)` - Mark as shipped
- `getSupplierNotifications()` - Get notifications
- `markNotificationAsRead(notificationId)` - Mark as read
- `cancelOrder(orderId, reason)` - Cancel order
- `getOrderHistory(orderId)` - View status history

### `CartService` (Updated)
- `createOrder()` - Now sets correct initial status

## 🔔 Notification System

Suppliers receive notifications when:
- ✅ New order is placed
- ✅ Customer cancels order
- ✅ Payment is completed (for COD)

Customers receive updates when:
- ✅ Order is approved
- ✅ Order is shipped (with tracking)
- ✅ Order status changes

## 🛡️ Security (RLS Policies)

- ✅ Customers can only view their own orders
- ✅ Suppliers can only view orders for their products
- ✅ Suppliers can only see their own notifications
- ✅ Status history is visible to both customer and supplier
- ✅ Only authenticated users can update order status

## 📝 Example Usage

### Customer Confirms Receipt:
```dart
await _ordersService.updateOrderStatus(orderId, 'to_review');
```

### Supplier Ships Order:
```dart
await _supplierOrdersService.shipOrder(orderId, 'TRACK123456');
```

### Get Supplier Notifications:
```dart
final notifications = await _supplierOrdersService.getSupplierNotifications(unreadOnly: true);
```

## ⚠️ Important Notes

1. **Products Must Have Supplier**: Ensure all products have `supplier_id` set
2. **Initial Status**: Orders are created with `to_pay` (COD) or `to_ship` (paid)
3. **Auto-Assignment**: Supplier is automatically assigned when order is created
4. **Tracking Numbers**: Optional for approval, required for shipping
5. **Status History**: All status changes are logged for audit trail

## 🎨 UI Components Needed

### For Supplier Dashboard:
- [ ] Supplier orders screen
- [ ] Order approval dialog
- [ ] Shipping form (tracking number)
- [ ] Notifications panel
- [ ] Order details view

### For Customer:
- ✅ Orders screen (already themed)
- ✅ Order status badges
- ✅ Track order button
- [ ] Review form (when status is 'to_review')

## 🚀 Next Steps

1. **Run the SQL migration** in Supabase
2. **Add supplier_id to products table**
3. **Test the complete flow**
4. **Create supplier dashboard UI**
5. **Implement notification UI**
6. **Add review system**

## 💡 Benefits

- ✅ Clear order workflow
- ✅ Automatic supplier notification
- ✅ Audit trail for all changes
- ✅ Better customer experience
- ✅ Supplier can manage orders efficiently
- ✅ Tracking number support
- ✅ Secure with RLS policies
