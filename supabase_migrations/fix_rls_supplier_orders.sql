-- Check and fix RLS policies for supplier orders access

-- Step 1: Check current RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('orders', 'order_items')
ORDER BY tablename, policyname;

-- Step 2: Enable RLS if not already enabled
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop existing supplier policies if they exist
DROP POLICY IF EXISTS "Suppliers can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Suppliers can view order items" ON public.order_items;

-- Step 4: Create policy for suppliers to view their assigned orders
CREATE POLICY "Suppliers can view their orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
  supplier_id = auth.uid()
  OR user_id = auth.uid()
);

-- Step 5: Create policy for suppliers to view order items
CREATE POLICY "Suppliers can view order items"
ON public.order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_items.order_id
    AND (orders.supplier_id = auth.uid() OR orders.user_id = auth.uid())
  )
);

-- Step 6: Also allow suppliers to update their orders (for shipping, status changes)
DROP POLICY IF EXISTS "Suppliers can update their orders" ON public.orders;
CREATE POLICY "Suppliers can update their orders"
ON public.orders
FOR UPDATE
TO authenticated
USING (supplier_id = auth.uid())
WITH CHECK (supplier_id = auth.uid());

-- Step 7: Verify - Test the query as if you were the supplier
-- This simulates what the app is doing
SET LOCAL role authenticated;
SET LOCAL request.jwt.claim.sub TO 'a6ae6b19-7d64-4118-b6b2-620b6f38f400';

SELECT 
  COUNT(*) as visible_orders
FROM public.orders
WHERE supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400';

-- Reset
RESET role;
