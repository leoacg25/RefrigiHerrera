-- ============================================================
-- RefrigiHerrera - Supabase Database Setup
-- Ejecuta este SQL en el SQL Editor de tu dashboard Supabase
-- ============================================================

-- Tabla de usuarios (admin/operadores del POS)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT DEFAULT '',
  role TEXT DEFAULT 'operator' CHECK (role IN ('admin', 'operator')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar usuario admin por defecto
INSERT INTO users (id, username, password_hash, full_name, role) VALUES
  ('usr_001', 'herrera', 'herrera2026', 'Admin Herrera', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Tabla de productos
CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category TEXT DEFAULT '',
  is_service BOOLEAN DEFAULT false,
  cost_price NUMERIC DEFAULT 0,
  profit_percent NUMERIC DEFAULT 0,
  price NUMERIC DEFAULT 0,
  price_ves NUMERIC DEFAULT 0,
  price_cop NUMERIC DEFAULT 0,
  stock INTEGER DEFAULT 0,
  min_stock INTEGER DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de ventas
CREATE TABLE IF NOT EXISTS sales (
  id TEXT PRIMARY KEY,
  date TIMESTAMPTZ DEFAULT now(),
  items JSONB DEFAULT '[]',
  subtotal NUMERIC DEFAULT 0,
  total NUMERIC DEFAULT 0,
  method TEXT DEFAULT 'Efectivo',
  cash_amount NUMERIC DEFAULT 0,
  transfer_amount NUMERIC DEFAULT 0,
  exchange_rate NUMERIC DEFAULT 0,
  cop_amount NUMERIC DEFAULT 0,
  cop_rate NUMERIC DEFAULT 0,
  client_id TEXT REFERENCES clients(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de combos
CREATE TABLE IF NOT EXISTS combos (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  price NUMERIC DEFAULT 0,
  items JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de clientes (para futura página de pedidos)
CREATE TABLE IF NOT EXISTS clients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  address TEXT DEFAULT '',
  id_number TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de pedidos (futura página de pedidos online)
CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  client_id TEXT REFERENCES clients(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled')),
  items JSONB DEFAULT '[]',
  subtotal NUMERIC DEFAULT 0,
  total NUMERIC DEFAULT 0,
  delivery_address TEXT DEFAULT '',
  delivery_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de configuración
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar configuración por defecto
INSERT INTO settings (key, value) VALUES
  ('app', '{"storeName":"RefrigiHerrera","whatsapp":"","exchangeRate":0,"copRate":0}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Habilitar RLS (Row Level Security)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE combos DISABLE ROW LEVEL SECURITY;
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE settings DISABLE ROW LEVEL SECURITY;

-- Habilitar Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE sales;
ALTER PUBLICATION supabase_realtime ADD TABLE combos;
ALTER PUBLICATION supabase_realtime ADD TABLE clients;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Índices
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date);
CREATE INDEX IF NOT EXISTS idx_combos_code ON combos(code);
CREATE INDEX IF NOT EXISTS idx_clients_phone ON clients(phone);
CREATE INDEX IF NOT EXISTS idx_clients_name ON clients(name);
CREATE INDEX IF NOT EXISTS idx_orders_client ON orders(client_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Migración COP (ejecutar si ya tienes la base de datos creada)
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cop_amount NUMERIC DEFAULT 0;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cop_rate NUMERIC DEFAULT 0;

-- Migración precios VES/COP (ejecutar si ya tienes la base de datos creada)
ALTER TABLE products ADD COLUMN IF NOT EXISTS price_ves NUMERIC DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS price_cop NUMERIC DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_service BOOLEAN DEFAULT false;

-- Migración cliente en ventas
ALTER TABLE sales ADD COLUMN IF NOT EXISTS client_id TEXT REFERENCES clients(id) ON DELETE SET NULL;

-- Tabla de cotizaciones
CREATE TABLE IF NOT EXISTS quotes (
  id TEXT PRIMARY KEY,
  client_id TEXT REFERENCES clients(id) ON DELETE SET NULL,
  client_name TEXT DEFAULT '',
  items JSONB DEFAULT '[]'::jsonb,
  currency TEXT DEFAULT 'USD',
  subtotal NUMERIC DEFAULT 0,
  total NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'pending',
  notes TEXT DEFAULT '',
  date TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE quotes DISABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_quotes_date ON quotes(date);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
ALTER PUBLICATION supabase_realtime ADD TABLE quotes;

-- ===================================================================
-- STORAGE: Bucket cotizaciones para PDFs
-- Ejecutar en Supabase SQL Editor si el bucket no existe
-- ===================================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('cotizaciones', 'cotizaciones', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Allow anon upload cotizaciones" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon read cotizaciones" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload cotizaciones" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated read cotizaciones" ON storage.objects;

CREATE POLICY "Allow anon upload cotizaciones" ON storage.objects
  FOR INSERT TO anon WITH CHECK (bucket_id = 'cotizaciones');

CREATE POLICY "Allow anon read cotizaciones" ON storage.objects
  FOR SELECT TO anon USING (bucket_id = 'cotizaciones');

CREATE POLICY "Allow authenticated upload cotizaciones" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'cotizaciones');

CREATE POLICY "Allow authenticated read cotizaciones" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'cotizaciones');
