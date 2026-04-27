-- ============================================================
-- Ruta Épica — Supabase Schema
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- DESTINATIONS
-- ============================================================
CREATE TABLE destinations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  gallery JSONB DEFAULT '[]',
  price_from NUMERIC(10,2),
  currency TEXT DEFAULT 'COP',
  includes JSONB DEFAULT '[]',
  duration_days INTEGER,
  rating NUMERIC(3,2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  is_promotion BOOLEAN DEFAULT FALSE,
  discount_percent NUMERIC(5,2),
  category TEXT, -- beach, city, adventure, cultural, international
  metadata JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- PACKAGES
-- ============================================================
CREATE TABLE packages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  destination_id UUID REFERENCES destinations(id),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2),
  currency TEXT DEFAULT 'COP',
  includes JSONB DEFAULT '[]',
  duration_days INTEGER,
  max_people INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- BOOKINGS
-- ============================================================
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  destination_id UUID REFERENCES destinations(id),
  destination_name TEXT NOT NULL,
  travel_date DATE NOT NULL,
  adults INTEGER NOT NULL DEFAULT 1,
  children INTEGER DEFAULT 0,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  observations TEXT,
  status TEXT DEFAULT 'pending', -- pending, confirmed, cancelled
  total_price NUMERIC(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- FAVORITES
-- ============================================================
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  destination_id UUID REFERENCES destinations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, destination_id)
);

-- ============================================================
-- PROMOTIONS
-- ============================================================
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subtitle TEXT,
  image_url TEXT,
  destination_id UUID REFERENCES destinations(id),
  discount_percent NUMERIC(5,2),
  valid_until TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- REVIEWS
-- ============================================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  destination_id UUID REFERENCES destinations(id),
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- PROVIDERS (for future flight/hotel/car APIs)
-- ============================================================
CREATE TABLE providers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL, -- Despegar, TiquetesBaratos, Booking, etc.
  api_endpoint TEXT,
  api_key_encrypted TEXT,
  is_active BOOLEAN DEFAULT FALSE,
  provider_type TEXT, -- flights, hotels, packages, cars
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- SEARCH LOGS
-- ============================================================
CREATE TABLE search_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  query TEXT,
  filters JSONB DEFAULT '{}',
  results_count INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  body TEXT,
  type TEXT, -- promo, booking_update, system
  is_read BOOLEAN DEFAULT FALSE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only see/edit their own
CREATE POLICY "Users see own profile"
  ON profiles FOR ALL
  USING (auth.uid() = id);

-- Bookings: users manage only their own
CREATE POLICY "Users manage own bookings"
  ON bookings FOR ALL
  USING (auth.uid() = user_id);

-- Favorites: users manage only their own
CREATE POLICY "Users manage own favorites"
  ON favorites FOR ALL
  USING (auth.uid() = user_id);

-- Notifications: users see only their own
CREATE POLICY "Users see own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Destinations: public read for active destinations
CREATE POLICY "Public read destinations"
  ON destinations FOR SELECT
  USING (is_active = TRUE);

-- Promotions: public read for active promotions
CREATE POLICY "Public read promotions"
  ON promotions FOR SELECT
  USING (is_active = TRUE);

-- Packages: public read for active packages
CREATE POLICY "Public read packages"
  ON packages FOR SELECT
  USING (is_active = TRUE);

-- Reviews: public read
CREATE POLICY "Public read reviews"
  ON reviews FOR SELECT
  USING (TRUE);

-- Reviews: authenticated users can insert
CREATE POLICY "Auth users insert reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on new auth user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================
-- SEED DATA
-- ============================================================
INSERT INTO destinations (
  name, country, description, image_url, price_from, currency,
  includes, duration_days, rating, review_count,
  is_featured, is_promotion, discount_percent, category
) VALUES
(
  'San Andrés',
  'Colombia',
  'El paraíso del Caribe colombiano con playas de aguas cristalinas y arrecifes de coral únicos en el mundo. Disfruta del famoso mar de los siete colores, ideal para snorkeling y buceo.',
  'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
  890000, 'COP',
  '["Tiquetes aéreos", "Hotel 4 noches", "Traslados", "Seguro de viaje"]',
  5, 4.8, 256, TRUE, FALSE, NULL, 'beach'
),
(
  'Cartagena',
  'Colombia',
  'La ciudad amurallada más hermosa de América Latina, con arquitectura colonial, playas espectaculares y una vibrante vida nocturna en el Caribe colombiano.',
  'https://images.unsplash.com/photo-1599689018034-48e2ead82951?w=800',
  650000, 'COP',
  '["Tiquetes aéreos", "Hotel 3 noches", "City tour", "Traslados"]',
  4, 4.7, 312, TRUE, FALSE, NULL, 'city'
),
(
  'Santa Marta',
  'Colombia',
  'Naturaleza, playa y ciudad en perfecta armonía. Puerta de entrada a la Sierra Nevada, Tayrona y las aguas cristalinas del Caribe colombiano.',
  'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
  520000, 'COP',
  '["Tiquetes aéreos", "Hotel 3 noches", "Traslados"]',
  4, 4.6, 189, TRUE, FALSE, NULL, 'beach'
),
(
  'Punta Cana',
  'República Dominicana',
  'All-inclusive en el Caribe con playas de arena blanca y aguas turquesas interminables. El destino perfecto para relajarse y disfrutar en familia o en pareja.',
  'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
  2890000, 'COP',
  '["Tiquetes aéreos", "Hotel all-inclusive 5 noches", "Traslados"]',
  6, 4.9, 428, TRUE, TRUE, 15.0, 'beach'
),
(
  'Cancún',
  'México',
  'La zona hotelera más famosa del mundo con vida nocturna increíble, ruinas mayas cercanas y playas perfectas de arena blanca bañadas por el Mar Caribe.',
  'https://images.unsplash.com/photo-1510097467424-192d713fd8b2?w=800',
  3200000, 'COP',
  '["Tiquetes aéreos", "Hotel all-inclusive 5 noches", "Traslados", "Chichen Itzá tour"]',
  6, 4.8, 367, TRUE, TRUE, 10.0, 'beach'
),
(
  'Europa Clásica',
  'Europa',
  'París, Roma y Barcelona en un solo viaje. Vive la cultura, gastronomía y arquitectura del viejo continente en un itinerario perfectamente organizado.',
  'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
  8900000, 'COP',
  '["Tiquetes aéreos", "Hoteles 10 noches", "Traslados entre ciudades", "Tours incluidos"]',
  12, 4.9, 156, TRUE, FALSE, NULL, 'cultural'
),
(
  'Medellín',
  'Colombia',
  'La ciudad de la eterna primavera, transformada en un epicentro cultural, gastronómico y tecnológico. Parque Explora, Pueblito Paisa y más te esperan.',
  'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=800',
  380000, 'COP',
  '["Tiquetes aéreos", "Hotel 2 noches", "Traslados", "City tour"]',
  3, 4.6, 203, FALSE, FALSE, NULL, 'city'
),
(
  'Miami',
  'Estados Unidos',
  'La ciudad más latina de EEUU. South Beach, Art Deco, shopping en Brickell y Wynwood Arts District te esperan en este destino único.',
  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
  4500000, 'COP',
  '["Tiquetes aéreos", "Hotel 4 noches", "Traslados"]',
  5, 4.7, 289, FALSE, TRUE, 20.0, 'international'
);

-- Sample promotions
INSERT INTO promotions (title, subtitle, image_url, discount_percent, valid_until, is_active)
VALUES
(
  'San Andrés en Semana Santa',
  'Desde $890.000 COP — Todo incluido',
  'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
  20,
  NOW() + INTERVAL '30 days',
  TRUE
),
(
  'Cancún 6 noches All-Inclusive',
  'Oferta limitada — Solo esta semana',
  'https://images.unsplash.com/photo-1510097467424-192d713fd8b2?w=800',
  15,
  NOW() + INTERVAL '7 days',
  TRUE
),
(
  'Europa Clásica — 12 días',
  'París, Roma y Barcelona te esperan',
  'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
  10,
  NOW() + INTERVAL '60 days',
  TRUE
);
