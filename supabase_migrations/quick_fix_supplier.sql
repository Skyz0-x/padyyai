-- Quick Fix: Assign Supplier to Products and Orders
-- Supplier UUID: a6ae6b19-7d64-4118-b6b2-620b6f38f400

-- Step 1: Add supplier_id column to products (if not exists)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES auth.users(id);

-- Step 2: Assign your supplier ID to all products
UPDATE public.products 
SET supplier_id = 'a6ae6b19-7d64-4118-b6b2-620b6f38f400' 
WHERE supplier_id IS NULL;

-- Step 3: Update orders table to add supplier_id column (if not exists)
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES auth.users(id);

-- Step 4: Assign supplier to existing orders based on products
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

-- Step 5: Create the assignment function
CREATE OR REPLACE FUNCTION assign_supplier_to_order(order_id_param UUID)
RETURNS VOID AS $$
DECLARE
  supplier_user_id UUID;
BEGIN
  -- Get supplier from the first product in the order
  SELECT DISTINCT p.supplier_id INTO supplier_user_id
  FROM public.order_items oi
  JOIN public.products p ON p.id::TEXT = oi.product_id
  WHERE oi.order_id = order_id_param
    AND p.supplier_id IS NOT NULL
  LIMIT 1;
  
  -- Update order with supplier_id
  IF supplier_user_id IS NOT NULL THEN
    UPDATE public.orders
    SET supplier_id = supplier_user_id
    WHERE id = order_id_param;
    
    -- Create notification for supplier (only if table exists)
    BEGIN
      INSERT INTO public.order_notifications (order_id, supplier_id, message, notification_type)
      VALUES (
        order_id_param,
        supplier_user_id,
        'New order received! Please review and approve.',
        'new_order'
      );
    EXCEPTION
      WHEN undefined_table THEN
        NULL; -- Ignore if table doesn't exist yet
    END;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Create trigger function
CREATE OR REPLACE FUNCTION trigger_assign_supplier()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM assign_supplier_to_order(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger
DROP TRIGGER IF EXISTS auto_assign_supplier_trigger ON public.orders;
CREATE TRIGGER auto_assign_supplier_trigger
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION trigger_assign_supplier();

-- Step 8: Verify the setup
SELECT 
  'Products with supplier' as description,
  COUNT(*) as count
FROM public.products 
WHERE supplier_id IS NOT NULL
UNION ALL
SELECT 
  'Orders with supplier' as description,
  COUNT(*) as count
FROM public.orders 
WHERE supplier_id IS NOT NULL;
