-- Update shipping fee from RM 50 to RM 6 for existing orders
-- and recalculate total_amount

UPDATE public.orders
SET 
  shipping_fee = 6.0,
  total_amount = subtotal + COALESCE(tax, 0) + 6.0
WHERE shipping_fee = 50.0;

-- Verify the update
SELECT 
  id,
  order_number,
  subtotal,
  shipping_fee,
  tax,
  total_amount,
  created_at
FROM public.orders
ORDER BY created_at DESC
LIMIT 10;
