-- Add benefits column to products table
-- This allows suppliers to add custom key benefits for their products

-- Add benefits column as JSONB array (text array)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS benefits TEXT[] DEFAULT '{}';

-- Add comment to describe the column
COMMENT ON COLUMN products.benefits IS 'Array of key benefits/features for the product as defined by the supplier';

-- Create an index for better query performance if searching by benefits
CREATE INDEX IF NOT EXISTS idx_products_benefits ON products USING GIN(benefits);

-- Example of how to update benefits for a product:
-- UPDATE products 
-- SET benefits = ARRAY[
--   'Quality assured product',
--   'Trusted by farmers',
--   'Easy to use and apply',
--   'Fast-acting formula',
--   'Long-lasting protection'
-- ]
-- WHERE id = 'your-product-id';

-- Example of adding a single benefit:
-- UPDATE products 
-- SET benefits = array_append(benefits, 'New benefit text')
-- WHERE id = 'your-product-id';

-- Example of removing a benefit:
-- UPDATE products 
-- SET benefits = array_remove(benefits, 'Benefit to remove')
-- WHERE id = 'your-product-id';

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name = 'benefits';
