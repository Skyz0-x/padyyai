-- Create orders table to store completed purchases
-- This table stores order history and payment information

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  total_amount DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) DEFAULT 0,
  shipping_fee DECIMAL(10, 2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending',
  payment_method VARCHAR(50),
  payment_status VARCHAR(50) DEFAULT 'pending',
  shipping_address TEXT,
  shipping_name VARCHAR(255),
  shipping_phone VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_items table to store individual items in each order
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id VARCHAR(100) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  product_price DECIMAL(10, 2) NOT NULL,
  product_image VARCHAR(500),
  product_category VARCHAR(100),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  subtotal DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments to document the tables and columns
COMMENT ON TABLE public.orders IS 'Stores completed orders and purchase history';
COMMENT ON COLUMN public.orders.user_id IS 'Reference to the user who placed the order';
COMMENT ON COLUMN public.orders.order_number IS 'Unique order identifier (e.g., ORD-20231115-001)';
COMMENT ON COLUMN public.orders.total_amount IS 'Final total amount including tax and shipping';
COMMENT ON COLUMN public.orders.subtotal IS 'Subtotal before tax and shipping';
COMMENT ON COLUMN public.orders.tax IS 'Tax amount';
COMMENT ON COLUMN public.orders.shipping_fee IS 'Shipping fee';
COMMENT ON COLUMN public.orders.status IS 'Order status: pending, processing, shipped, delivered, cancelled';
COMMENT ON COLUMN public.orders.payment_method IS 'Payment method used: card, bank_transfer, cash_on_delivery';
COMMENT ON COLUMN public.orders.payment_status IS 'Payment status: pending, completed, failed, refunded';

COMMENT ON TABLE public.order_items IS 'Stores individual items within each order';
COMMENT ON COLUMN public.order_items.order_id IS 'Reference to the parent order';
COMMENT ON COLUMN public.order_items.product_id IS 'Product identifier at time of purchase';
COMMENT ON COLUMN public.order_items.subtotal IS 'Line item subtotal (price × quantity)';

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_user_id 
ON public.orders(user_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_number 
ON public.orders(order_number);

CREATE INDEX IF NOT EXISTS idx_orders_status 
ON public.orders(status);

CREATE INDEX IF NOT EXISTS idx_orders_created_at 
ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON public.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id 
ON public.order_items(product_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;

-- Create RLS policies for orders

-- Policy: Users can view their own orders
CREATE POLICY "Users can view own orders"
ON public.orders
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own orders
CREATE POLICY "Users can insert own orders"
ON public.orders
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own orders (limited to certain statuses)
CREATE POLICY "Users can update own orders"
ON public.orders
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for order_items

-- Policy: Users can view items from their own orders
CREATE POLICY "Users can view own order items"
ON public.order_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE orders.id = order_items.order_id 
    AND orders.user_id = auth.uid()
  )
);

-- Policy: Users can insert items to their own orders
CREATE POLICY "Users can insert own order items"
ON public.order_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE orders.id = order_items.order_id 
    AND orders.user_id = auth.uid()
  )
);

-- Drop existing functions and triggers if they exist
DROP TRIGGER IF EXISTS update_orders_updated_at_trigger ON public.orders;
DROP FUNCTION IF EXISTS public.update_orders_updated_at();
DROP FUNCTION IF EXISTS public.generate_order_number();

-- Create function to update orders updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_orders_updated_at_trigger
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.update_orders_updated_at();

-- Create function to generate order number
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT AS $$
DECLARE
  order_num TEXT;
  date_part TEXT;
  sequence_part TEXT;
BEGIN
  -- Format: ORD-YYYYMMDD-XXX
  date_part := TO_CHAR(NOW(), 'YYYYMMDD');
  
  -- Get count of orders today + 1
  SELECT LPAD((COUNT(*) + 1)::TEXT, 3, '0')
  INTO sequence_part
  FROM public.orders
  WHERE DATE(created_at) = CURRENT_DATE;
  
  order_num := 'ORD-' || date_part || '-' || sequence_part;
  
  RETURN order_num;
END;
$$ LANGUAGE plpgsql;
