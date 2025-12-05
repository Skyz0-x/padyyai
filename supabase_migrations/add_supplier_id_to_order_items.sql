-- Add supplier_id column to order_items table to track which supplier owns the product
ALTER TABLE public.order_items
ADD COLUMN supplier_id UUID NULL;

-- Add foreign key constraint to link to suppliers (auth.users table)
ALTER TABLE public.order_items
ADD CONSTRAINT order_items_supplier_id_fkey 
FOREIGN KEY (supplier_id) REFERENCES auth.users (id) ON DELETE SET NULL;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_order_items_supplier_id ON public.order_items USING btree (supplier_id) TABLESPACE pg_default;

-- Update existing order_items to populate supplier_id from products table
UPDATE public.order_items oi
SET supplier_id = p.supplier_id
FROM public.products p
WHERE oi.product_id = p.id::text AND oi.supplier_id IS NULL;
