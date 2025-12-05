-- Clean up any recursive/old policies on order_items that join to orders table
DROP POLICY IF EXISTS "Suppliers can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;

-- Simple policies on order_items (NO joins to orders to avoid recursion)
DROP POLICY IF EXISTS "Suppliers can view own order items by supplier_id" ON public.order_items;
CREATE POLICY "Suppliers can view own order items by supplier_id" ON public.order_items
  FOR SELECT
  USING (supplier_id = auth.uid());

-- Users can insert their own order items (during order creation)
-- Keep existing insert policy as-is (doesn't cause recursion)

-- Allow suppliers to view orders that contain their products (safe; order_items no longer joins back to orders)
DROP POLICY IF EXISTS "Suppliers can view orders with their products" ON public.orders;
CREATE POLICY "Suppliers can view orders with their products" ON public.orders
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items
      WHERE order_items.order_id = orders.id
      AND order_items.supplier_id = auth.uid()
    )
  );

-- Allow suppliers to update orders that contain their products (for approval, shipping, etc.)
DROP POLICY IF EXISTS "Suppliers can update orders with their products" ON public.orders;
CREATE POLICY "Suppliers can update orders with their products" ON public.orders
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items
      WHERE order_items.order_id = orders.id
      AND order_items.supplier_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.order_items
      WHERE order_items.order_id = orders.id
      AND order_items.supplier_id = auth.uid()
    )
  );
