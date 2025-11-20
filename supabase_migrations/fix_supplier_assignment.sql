-- Fix supplier assignment for orders
-- This migration adds supplier_id to products table and updates the assignment logic

-- Step 1: Add supplier_id column to products table if it doesn't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES auth.users(id);

-- Step 2: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_products_supplier_id 
ON public.products(supplier_id);

-- Step 3: Update existing products to assign current suppliers
-- You need to run this manually with your actual supplier user IDs
-- Example: UPDATE public.products SET supplier_id = 'YOUR_SUPPLIER_UUID' WHERE supplier_id IS NULL;

-- Step 4: Fix the assign_supplier_to_order function to work with VARCHAR product_id
CREATE OR REPLACE FUNCTION assign_supplier_to_order(order_id_param UUID)
RETURNS VOID AS $$
DECLARE
  supplier_user_id UUID;
BEGIN
  -- Get supplier from the first product in the order
  -- This now handles product_id as VARCHAR by converting it
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
    
    -- Create notification for supplier
    INSERT INTO public.order_notifications (order_id, supplier_id, message, notification_type)
    VALUES (
      order_id_param,
      supplier_user_id,
      'New order received! Please review and approve.',
      'new_order'
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Update the trigger function (no changes needed, just ensuring it exists)
CREATE OR REPLACE FUNCTION trigger_assign_supplier()
RETURNS TRIGGER AS $$
BEGIN
  -- Only assign supplier for new orders
  IF TG_OP = 'INSERT' THEN
    PERFORM assign_supplier_to_order(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Recreate trigger
DROP TRIGGER IF EXISTS auto_assign_supplier_trigger ON public.orders;
CREATE TRIGGER auto_assign_supplier_trigger
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION trigger_assign_supplier();

-- Step 7: Manually assign supplier to existing orders (run after updating products)
-- This is a one-time fix for existing orders
-- You can run this after setting supplier_id on products:
/*
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
*/
