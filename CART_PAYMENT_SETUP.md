# Shopping Cart & Payment System Setup Guide

## Database Tables Created

### 1. Cart Items Table (`cart_items`)
Stores shopping cart items for users before checkout.

**File:** `supabase_migrations/create_cart_items_table.sql`

**Table Structure:**
- `id` - UUID primary key
- `user_id` - Reference to auth.users
- `product_id` - Unique product identifier
- `product_name` - Product name at time of adding
- `product_price` - Product price at time of adding
- `product_image` - URL/path to product image
- `product_category` - Product category
- `quantity` - Number of items (minimum 1)
- `created_at` - Timestamp
- `updated_at` - Auto-updated timestamp

**Features:**
- Unique constraint prevents duplicate products per user
- Row Level Security (RLS) enabled
- Auto-updating `updated_at` trigger
- Users can only view/modify their own cart items

### 2. Orders Table (`orders`)
Stores completed purchases and order history.

**File:** `supabase_migrations/create_orders_table.sql`

**Table Structure:**
- `id` - UUID primary key
- `user_id` - Reference to auth.users
- `order_number` - Unique order identifier (e.g., ORD-20231115-001)
- `total_amount` - Final total including tax and shipping
- `subtotal` - Subtotal before tax and shipping
- `tax` - Tax amount
- `shipping_fee` - Shipping fee
- `status` - Order status (pending, processing, shipped, delivered, cancelled)
- `payment_method` - Payment method (card, bank_transfer, cash_on_delivery)
- `payment_status` - Payment status (pending, completed, failed, refunded)
- `shipping_name` - Recipient name
- `shipping_phone` - Contact phone
- `shipping_address` - Delivery address
- `notes` - Optional order notes
- `created_at` - Timestamp
- `updated_at` - Auto-updated timestamp

### 3. Order Items Table (`order_items`)
Stores individual items within each order.

**Table Structure:**
- `id` - UUID primary key
- `order_id` - Reference to orders table
- `product_id` - Product identifier
- `product_name` - Product name at purchase
- `product_price` - Product price at purchase
- `product_image` - Product image URL
- `product_category` - Product category
- `quantity` - Number of items
- `subtotal` - Line item total (price × quantity)
- `created_at` - Timestamp

**Special Functions:**
- `generate_order_number()` - Automatically generates unique order numbers in format ORD-YYYYMMDD-XXX

## Setup Instructions

### Step 1: Run SQL Migrations

Execute the following SQL files in your Supabase SQL Editor **in this order**:

1. **Create Cart Items Table:**
   ```sql
   -- File: supabase_migrations/create_cart_items_table.sql
   ```

2. **Create Orders and Order Items Tables:**
   ```sql
   -- File: supabase_migrations/create_orders_table.sql
   ```

### Step 2: Verify Tables Created

Run this query to verify all tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('cart_items', 'orders', 'order_items');
```

### Step 3: Verify RLS Policies

Check that Row Level Security is enabled:

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('cart_items', 'orders', 'order_items');
```

All tables should show `rowsecurity = true`.

### Step 4: Test the Database Functions

Test order number generation:

```sql
SELECT generate_order_number();
```

Expected output: `ORD-20231118-001` (format: ORD-YYYYMMDD-XXX)

## Application Features Implemented

### 1. Cart Service (`lib/services/cart_service.dart`)

**Methods:**
- `addToCart()` - Add item to cart or update quantity
- `getCartItems()` - Get all cart items for current user
- `updateQuantity()` - Update item quantity
- `removeFromCart()` - Remove item from cart
- `clearCart()` - Clear all cart items
- `getCartSummary()` - Get total items and price
- `getCartItemCount()` - Get count for badge display
- `createOrder()` - Create order from cart items
- `getUserOrders()` - Get user's order history
- `getOrderItems()` - Get items for specific order

### 2. Cart Screen (`lib/screens/cart_screen.dart`)

**Features:**
- Displays all cart items with images and details
- Quantity controls (increment/decrement)
- Remove individual items or clear entire cart
- Real-time price calculation
- Subtotal, tax, and shipping fee display
- Free shipping notification (orders > Rs 1000)
- Empty cart state with "Continue Shopping" button
- Proceed to checkout button

**UI Design:**
- Gradient header matching app theme
- Curved white container for content
- Product cards with images and categories
- Fixed bottom summary with totals
- Professional card-based layout

### 3. Payment Screen (`lib/screens/payment_screen.dart`)

**Payment Methods Supported:**
1. **Credit/Debit Card** (Dummy Gateway)
   - Card number input with auto-formatting (XXXX XXXX XXXX XXXX)
   - Card holder name
   - Expiry date (MM/YY format)
   - CVV (3 digits, masked)
   - Secure payment indicator

2. **Bank Transfer**
   - Bank details display
   - Account information
   - Reference instructions

3. **Cash on Delivery**
   - COD information message
   - Payment on delivery instructions

**Features:**
- Shipping information form (name, phone, address, notes)
- Order summary with pricing breakdown
- Payment method selector with radio buttons
- Form validation
- Processing state with loading indicator
- Success dialog with order number
- Professional card-based UI

**Success Flow:**
1. Payment processing animation (2 seconds)
2. Order created in database
3. Cart cleared automatically
4. Success dialog with order details
5. Navigation back to marketplace

### 4. Marketplace Integration

**Updates Made:**
- Cart icon with badge counter in header
- Badge shows total item quantity
- "Add to Cart" button in product details
- Real-time cart count updates
- Navigation to cart screen
- Success snackbar with "VIEW CART" action
- Product availability checking

**Cart Badge:**
- Red circular badge on cart icon
- Shows item count (e.g., "5")
- Displays "99+" for quantities over 99
- Updates automatically after adding items

### 5. Routing Configuration

**Routes Added to `main.dart`:**
```dart
'/cart': CartScreen
'/payment': PaymentScreen
```

## Usage Flow

### Adding Items to Cart

1. User browses marketplace
2. Clicks on product to view details
3. Clicks "Add to Cart" button
4. Item added to cart (or quantity increased if exists)
5. Success message shown with "VIEW CART" action
6. Cart badge updates with new count

### Checkout Process

1. User clicks cart icon in marketplace header
2. Cart screen shows all items
3. User can adjust quantities or remove items
4. Reviews totals (subtotal, tax, shipping)
5. Clicks "Proceed to Checkout"
6. Fills shipping information
7. Selects payment method:
   - **Card**: Enters card details
   - **Bank Transfer**: Views bank details
   - **Cash on Delivery**: Confirms COD
8. Clicks "Pay" button
9. Payment processes (2 second simulation)
10. Order created in database
11. Cart cleared
12. Success dialog shown with order number
13. Returns to marketplace

## Pricing Configuration

**Current Settings:**
- Tax Rate: 0% (can be modified in `CartService.createOrder()`)
- Shipping Fee: Rs 50.00
- Free Shipping Threshold: Orders > Rs 1000.00

**To Modify:**
Edit in `lib/services/cart_service.dart`:
```dart
final tax = subtotal * 0.0; // Change to 0.05 for 5% tax
final shippingFee = subtotal > 1000 ? 0.0 : 50.0; // Change threshold
```

## Security Features

### Row Level Security (RLS)
- Users can only access their own cart items
- Users can only view their own orders
- Order items accessible only to order owners
- All operations require authentication

### Data Validation
- Card number: 16 digits max
- CVV: 3 digits, masked input
- Expiry date: MM/YY format
- Phone number: Required
- Address: Required, multiline
- Quantity: Minimum 1

### Price Integrity
- Product prices captured at time of cart addition
- Order items store historical prices
- Protects against price changes after cart addition

## Testing Checklist

- [ ] Run SQL migration files in Supabase
- [ ] Verify tables created with correct structure
- [ ] Test RLS policies (users can only see own data)
- [ ] Add product to cart from marketplace
- [ ] Update quantity in cart
- [ ] Remove item from cart
- [ ] Clear entire cart
- [ ] Proceed to checkout
- [ ] Fill shipping information
- [ ] Test each payment method
- [ ] Complete order successfully
- [ ] Verify order appears in database
- [ ] Verify cart cleared after order
- [ ] Test cart badge counter updates
- [ ] Test empty cart state

## Payment Gateway Note

**Current Implementation:** Dummy/Mock Payment Gateway

This is a **demonstration payment system** for development and testing purposes. It simulates payment processing without actual transactions.

**For Production:**
Replace the dummy payment processing with real payment gateway integration:
- Stripe
- PayPal
- Razorpay
- Square
- Local payment providers

**Integration Point:**
The payment processing logic is in `lib/screens/payment_screen.dart` in the `_processPayment()` method. Replace the 2-second delay simulation with actual API calls to your chosen payment gateway.

## Database Indexes

Optimized indexes created for:
- User lookups: `idx_cart_items_user_id`, `idx_orders_user_id`
- Product lookups: `idx_cart_items_product_id`, `idx_order_items_product_id`
- Order tracking: `idx_orders_order_number`, `idx_orders_status`
- Date sorting: `idx_cart_items_created_at`, `idx_orders_created_at`
- Order relationships: `idx_order_items_order_id`

## Troubleshooting

### Cart items not appearing
- Check user is authenticated
- Verify RLS policies are enabled
- Check `user_id` matches current auth user

### Order creation fails
- Ensure cart has items
- Verify shipping form is validated
- Check `generate_order_number()` function exists
- Verify `order_items` table has correct foreign key

### Cart badge not updating
- Check `_loadCartCount()` is called after cart operations
- Verify `getCartItemCount()` returns correct sum
- Ensure state updates trigger UI refresh

### Payment processing errors
- Check all required fields are filled
- Verify cart service is imported
- Check order creation in database
- Review error messages in console

## Future Enhancements

Potential improvements:
- Order tracking and status updates
- Email notifications for orders
- Product recommendations
- Wishlist functionality
- Order history screen
- Delivery tracking integration
- Real payment gateway integration
- Coupon/discount codes
- Multi-currency support
- Saved addresses
- Multiple payment cards
- Order cancellation
- Return/refund processing
