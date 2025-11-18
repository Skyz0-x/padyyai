-- Create cart_items table to store shopping cart items
-- This table stores products added to cart by users before checkout

CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id VARCHAR(100) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  product_price DECIMAL(10, 2) NOT NULL,
  product_image VARCHAR(500),
  product_category VARCHAR(100),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments to document the table and columns
COMMENT ON TABLE public.cart_items IS 'Stores shopping cart items for users before checkout';
COMMENT ON COLUMN public.cart_items.user_id IS 'Reference to the user who owns this cart item';
COMMENT ON COLUMN public.cart_items.product_id IS 'Unique identifier for the product';
COMMENT ON COLUMN public.cart_items.product_name IS 'Name of the product at time of adding to cart';
COMMENT ON COLUMN public.cart_items.product_price IS 'Price of the product at time of adding to cart';
COMMENT ON COLUMN public.cart_items.product_image IS 'URL or path to product image';
COMMENT ON COLUMN public.cart_items.product_category IS 'Category of the product (fertilizer, pesticide, etc.)';
COMMENT ON COLUMN public.cart_items.quantity IS 'Number of items in cart';

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id 
ON public.cart_items(user_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_product_id 
ON public.cart_items(product_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_created_at 
ON public.cart_items(created_at DESC);

-- Create unique constraint to prevent duplicate products per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_cart_items_user_product 
ON public.cart_items(user_id, product_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Policy: Users can view their own cart items
CREATE POLICY "Users can view own cart items"
ON public.cart_items
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own cart items
CREATE POLICY "Users can insert own cart items"
ON public.cart_items
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own cart items
CREATE POLICY "Users can update own cart items"
ON public.cart_items
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own cart items
CREATE POLICY "Users can delete own cart items"
ON public.cart_items
FOR DELETE
USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_cart_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_cart_items_updated_at_trigger
BEFORE UPDATE ON public.cart_items
FOR EACH ROW
EXECUTE FUNCTION public.update_cart_items_updated_at();
