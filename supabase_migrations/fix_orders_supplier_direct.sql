-- Direct Fix: Assign all orders to the supplier
-- This bypasses the product JOIN issue

-- First, let's see what we have
SELECT 
  'Total orders' as info,
  COUNT(*) as count
FROM public.orders;

-- Directly assign ALL orders to your supplier account
-- (Since you're the only supplier, this is the simplest fix)
UPDATE public.orders
SET supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400'
WHERE supplier_id IS NULL;

-- Verify the update
SELECT 
  'Orders now assigned to supplier' as info,
  COUNT(*) as count
FROM public.orders
WHERE supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400';

-- Show all orders with their details
SELECT 
  id,
  order_number,
  status,
  supplier_id,
  user_id as farmer_id,
  total_amount,
  created_at
FROM public.orders
ORDER BY created_at DESC;
