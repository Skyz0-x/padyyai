-- Add tracking_number column to orders table
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(100),
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS shipped_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

-- Create order_notifications table for supplier notifications
CREATE TABLE IF NOT EXISTS public.order_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  notification_type VARCHAR(50) DEFAULT 'new_order',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_status_history table to track status changes
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments
COMMENT ON COLUMN public.orders.tracking_number IS 'Shipping tracking number provided by courier';
COMMENT ON COLUMN public.orders.supplier_id IS 'Reference to supplier who will fulfill this order';
COMMENT ON COLUMN public.orders.approved_at IS 'Timestamp when supplier approved the order';
COMMENT ON COLUMN public.orders.shipped_at IS 'Timestamp when order was shipped';
COMMENT ON COLUMN public.orders.delivered_at IS 'Timestamp when order was delivered';

COMMENT ON TABLE public.order_notifications IS 'Notifications for suppliers about new orders';
COMMENT ON TABLE public.order_status_history IS 'Audit trail of order status changes';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id ON public.orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_tracking_number ON public.orders(tracking_number);
CREATE INDEX IF NOT EXISTS idx_order_notifications_supplier_id ON public.order_notifications(supplier_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_order_id ON public.order_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON public.order_status_history(order_id);

-- Enable RLS
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Suppliers can view their notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "Suppliers can update their notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "Users can view order history" ON public.order_status_history;
DROP POLICY IF EXISTS "Authenticated users can insert order history" ON public.order_status_history;

-- RLS Policies for order_notifications
CREATE POLICY "Suppliers can view their notifications"
ON public.order_notifications
FOR SELECT
USING (auth.uid() = supplier_id);

CREATE POLICY "System can insert notifications"
ON public.order_notifications
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Suppliers can update their notifications"
ON public.order_notifications
FOR UPDATE
USING (auth.uid() = supplier_id);

-- RLS Policies for order_status_history
CREATE POLICY "Users can view order history"
ON public.order_status_history
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE orders.id = order_status_history.order_id 
    AND (orders.user_id = auth.uid() OR orders.supplier_id = auth.uid())
  )
);

CREATE POLICY "Authenticated users can insert order history"
ON public.order_status_history
FOR INSERT
WITH CHECK (auth.uid() = changed_by);

-- Function to assign supplier to order based on products
CREATE OR REPLACE FUNCTION assign_supplier_to_order(order_id_param UUID)
RETURNS VOID AS $$
DECLARE
  supplier_user_id UUID;
BEGIN
  -- Get supplier from the first product in the order
  -- This assumes products table has a supplier_id column
  -- Adjust this logic based on your actual product-supplier relationship
  SELECT DISTINCT u.id INTO supplier_user_id
  FROM public.order_items oi
  JOIN public.products p ON p.id = oi.product_id::UUID
  JOIN auth.users u ON u.id = p.supplier_id
  WHERE oi.order_id = order_id_param
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

-- Function to update order status with history tracking
CREATE OR REPLACE FUNCTION update_order_status_with_history(
  order_id_param UUID,
  new_status_param VARCHAR(50),
  notes_param TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  old_status_val VARCHAR(50);
BEGIN
  -- Get current status
  SELECT status INTO old_status_val
  FROM public.orders
  WHERE id = order_id_param;
  
  -- Update order status
  UPDATE public.orders
  SET status = new_status_param,
      updated_at = NOW(),
      approved_at = CASE WHEN new_status_param = 'to_ship' THEN NOW() ELSE approved_at END,
      shipped_at = CASE WHEN new_status_param = 'to_receive' THEN NOW() ELSE shipped_at END,
      delivered_at = CASE WHEN new_status_param = 'to_review' THEN NOW() ELSE delivered_at END
  WHERE id = order_id_param;
  
  -- Insert into history
  INSERT INTO public.order_status_history (order_id, old_status, new_status, changed_by, notes)
  VALUES (order_id_param, old_status_val, new_status_param, auth.uid(), notes_param);
  
  -- Create notification for customer on status change
  IF new_status_param IN ('to_ship', 'to_receive', 'completed', 'cancelled') THEN
    -- You can extend this to create customer notifications
    NULL;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically assign supplier when order is created
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

DROP TRIGGER IF EXISTS auto_assign_supplier_trigger ON public.orders;
CREATE TRIGGER auto_assign_supplier_trigger
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION trigger_assign_supplier();

-- Update order comments to reflect new status values
COMMENT ON COLUMN public.orders.status IS 'Order status: to_pay, to_ship, to_receive, to_review, completed, cancelled';
