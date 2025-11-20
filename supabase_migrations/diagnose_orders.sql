-- Diagnostic: Check what's actually in the database

-- 1. Check if orders table has any data at all
SELECT 
  'Total orders in database' as check_name,
  COUNT(*) as result
FROM public.orders;

-- 2. Show all orders with their supplier_id values
SELECT 
  id,
  order_number,
  status,
  supplier_id,
  user_id as farmer_id,
  total_amount,
  created_at
FROM public.orders
ORDER BY created_at DESC
LIMIT 20;

-- 3. Count orders by supplier_id (including NULL)
SELECT 
  COALESCE(supplier_id::text, 'NULL') as supplier_id_value,
  COUNT(*) as count
FROM public.orders
GROUP BY supplier_id;

-- 4. Force update ALL orders regardless of current supplier_id
UPDATE public.orders
SET supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400';

-- 5. Verify the force update
SELECT 
  'Orders after force update' as check_name,
  COUNT(*) as result
FROM public.orders
WHERE supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400';

-- 6. Show the updated orders
SELECT 
  id,
  order_number,
  status,
  supplier_id,
  user_id as farmer_id,
  total_amount
FROM public.orders
ORDER BY created_at DESC
LIMIT 10;
