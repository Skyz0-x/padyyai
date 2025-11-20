# Fix Supplier Assignment for Orders

## Problem
Orders placed by farmers are not appearing in the Supplier Orders screen because the `supplier_id` is not being set on orders.

## Root Cause
1. The `products` table doesn't have a `supplier_id` column yet
2. The auto-assignment trigger needs the products to have supplier information

## Solution Steps

### Step 1: Run the Migration
Execute the following SQL in Supabase Dashboard → SQL Editor:

```sql
-- File: supabase_migrations/fix_supplier_assignment.sql
```

Copy and paste the entire content of `fix_supplier_assignment.sql` and run it.

### Step 2: Assign Supplier to Your Products

You need to update your existing products to have a `supplier_id`. 

**Option A: If you know your supplier user ID:**

1. Go to Supabase Dashboard → Authentication → Users
2. Copy the UUID of your supplier user
3. Run this SQL (replace `YOUR_SUPPLIER_UUID` with actual UUID):

```sql
UPDATE public.products 
SET supplier_id = 'YOUR_SUPPLIER_UUID' 
WHERE supplier_id IS NULL;
```

**Option B: Get supplier ID programmatically:**

Run this to see your supplier users:
```sql
SELECT id, email, raw_user_meta_data->>'role' as role 
FROM auth.users 
WHERE raw_user_meta_data->>'role' = 'supplier';
```

Then update products with the appropriate supplier ID.

### Step 3: Fix Existing Orders

After products have `supplier_id`, run this to update existing orders:

```sql
UPDATE public.orders o
SET supplier_id = (
  SELECT DISTINCT p.supplier_id
  FROM public.order_items oi
  JOIN public.products p ON p.id::TEXT = oi.product_id
  WHERE oi.order_id = o.id
    AND p.supplier_id IS NOT NULL
  LIMIT 1
)
WHERE o.supplier_id IS NULL;
```

### Step 4: Test the Flow

1. **As Supplier:**
   - Login to supplier account
   - Go to Products → Add/Edit products
   - Your products should now have `supplier_id` automatically set

2. **As Farmer:**
   - Login as farmer
   - Add products to cart
   - Complete checkout
   - Order should be created

3. **As Supplier:**
   - Go to Supplier Dashboard → View Orders
   - You should now see the order appear in "To Ship" tab
   - The trigger automatically assigned you as the supplier

## How It Works Now

When a farmer places an order:

1. ✅ Order is created in `orders` table
2. ✅ Order items are created in `order_items` table
3. ✅ Trigger `auto_assign_supplier_trigger` fires
4. ✅ Function `assign_supplier_to_order` runs:
   - Looks up products from order_items
   - Finds the supplier_id from products table
   - Updates the order with supplier_id
   - Creates a notification for the supplier
5. ✅ Order appears in Supplier Orders screen

## Verification

Check if an order has a supplier assigned:

```sql
SELECT 
  o.id,
  o.order_number,
  o.supplier_id,
  o.status,
  p.supplier_id as product_supplier,
  p.name as product_name
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id::TEXT = oi.product_id
ORDER BY o.created_at DESC
LIMIT 10;
```

## Troubleshooting

**Q: Orders still not showing for supplier?**
- Check if products have `supplier_id`: `SELECT id, name, supplier_id FROM products;`
- Check if orders have `supplier_id`: `SELECT id, order_number, supplier_id FROM orders;`
- Check trigger is active: `SELECT * FROM pg_trigger WHERE tgname = 'auto_assign_supplier_trigger';`

**Q: How to assign different suppliers to different products?**
- Update each product individually:
  ```sql
  UPDATE products SET supplier_id = 'SUPPLIER_UUID' WHERE id = 'PRODUCT_ID';
  ```

**Q: Can multiple suppliers exist?**
- Yes! Each product can have its own supplier
- If an order has products from multiple suppliers, only the first one found is assigned
- You may need to enhance the logic to split orders by supplier if needed
