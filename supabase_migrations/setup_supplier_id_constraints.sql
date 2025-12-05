-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'order_items_supplier_id_fkey'
  ) THEN
    ALTER TABLE public.order_items
    ADD CONSTRAINT order_items_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES auth.users (id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_order_items_supplier_id ON public.order_items USING btree (supplier_id) TABLESPACE pg_default;

-- Backfill supplier_id from products table for existing orders that don't have it yet
UPDATE public.order_items oi
SET supplier_id = p.supplier_id
FROM public.products p
WHERE oi.product_id = p.id::text 
  AND oi.supplier_id IS NULL
  AND p.supplier_id IS NOT NULL;
