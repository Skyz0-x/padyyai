-- Backfill supplier_id in order_items for existing orders
-- This ensures suppliers can see all orders including newly created ones

-- Update order_items to set supplier_id from products table
UPDATE public.order_items oi
SET supplier_id = p.supplier_id
FROM public.products p
WHERE oi.product_id = p.id::text 
  AND oi.supplier_id IS NULL
  AND p.supplier_id IS NOT NULL;

-- Verify the update
SELECT 
  COUNT(*) as total_items,
  COUNT(supplier_id) as items_with_supplier,
  COUNT(*) - COUNT(supplier_id) as items_without_supplier
FROM public.order_items;

-- Show sample of order_items with supplier_id
SELECT 
  oi.id,
  oi.order_id,
  oi.product_id,
  oi.product_name,
  oi.supplier_id,
  p.supplier_id as product_supplier_id
FROM public.order_items oi
LEFT JOIN public.products p ON p.id = oi.product_id::UUID
ORDER BY oi.created_at DESC
LIMIT 10;
