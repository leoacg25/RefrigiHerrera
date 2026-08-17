-- ============================================================
-- RefrigiHerrera - Supabase Database Setup
-- Ejecuta este SQL en el SQL Editor de tu dashboard Supabase
-- ============================================================

-- Tabla de productos
CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category TEXT DEFAULT '',
  cost_price NUMERIC DEFAULT 0,
  profit_percent NUMERIC DEFAULT 0,
  price NUMERIC DEFAULT 0,
  stock INTEGER DEFAULT 0,
  min_stock INTEGER DEFAULT 5,
  offer_enabled BOOLEAN DEFAULT false,
  offer_qty INTEGER DEFAULT 0,
  offer_price NUMERIC DEFAULT 0,
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

-- Tabla de configuración
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insertar configuración por defecto
INSERT INTO settings (key, value) VALUES
  ('app', '{"storeName":"RefrigiHerrera","whatsapp":"","exchangeRate":0}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Habilitar RLS (Row Level Security)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE combos ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Políticas: permitir todo a usuarios autenticados
CREATE POLICY "Allow all for authenticated" ON products FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for authenticated" ON sales FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for authenticated" ON combos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for authenticated" ON settings FOR ALL USING (true) WITH CHECK (true);

-- Habilitar Realtime (opcional, para sincronización en tiempo real)
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE sales;
ALTER PUBLICATION supabase_realtime ADD TABLE combos;

-- Índices para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date);
CREATE INDEX IF NOT EXISTS idx_combos_code ON combos(code);
