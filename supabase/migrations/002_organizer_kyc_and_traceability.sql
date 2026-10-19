-- ============================================================
-- Sunu Tikeu — KYC organisateur, acheteurs, traçabilité
-- ============================================================

-- Profils : infos client + WhatsApp
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS whatsapp TEXT,
  ADD COLUMN IF NOT EXISTS google_email TEXT;

-- KYC organisateur
CREATE TABLE IF NOT EXISTS public.organizer_kyc (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  ninea TEXT NOT NULL,
  id_document_url TEXT NOT NULL,
  id_document_type TEXT NOT NULL DEFAULT 'image'
    CHECK (id_document_type IN ('image', 'pdf')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_organizer_kyc_user ON public.organizer_kyc(user_id);
CREATE INDEX IF NOT EXISTS idx_organizer_kyc_status ON public.organizer_kyc(status);

-- Journal d'activité (traçabilité)
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_actor ON public.activity_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_event ON public.activity_logs(event_id);
CREATE INDEX IF NOT EXISTS idx_activity_created ON public.activity_logs(created_at DESC);

-- RLS
ALTER TABLE public.organizer_kyc ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own KYC"
  ON public.organizer_kyc FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users see own activity or event organizers"
  ON public.activity_logs FOR SELECT
  USING (
    actor_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id AND e.organizer_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated insert activity"
  ON public.activity_logs FOR INSERT
  WITH CHECK (actor_id = auth.uid());

-- Un organisateur ne peut publier que si KYC approved
CREATE OR REPLACE FUNCTION public.can_publish_event(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organizer_kyc k
    WHERE k.user_id = p_user_id AND k.status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger : bloquer publication sans KYC
CREATE OR REPLACE FUNCTION public.check_publish_kyc()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN
    IF NOT public.can_publish_event(NEW.organizer_id) THEN
      RAISE EXCEPTION 'KYC organisateur non approuvé : impossible de publier';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS events_publish_kyc ON public.events;
CREATE TRIGGER events_publish_kyc
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.check_publish_kyc();

-- Storage : bucket documents identité (à créer aussi dans Dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('id-documents', 'id-documents', false)
-- ON CONFLICT DO NOTHING;
