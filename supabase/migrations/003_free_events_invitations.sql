-- ============================================================
-- Événements gratuits, invitations, téléphone obligatoire
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS whatsapp TEXT,
  ADD COLUMN IF NOT EXISTS google_email TEXT;

ALTER TABLE public.organizer_kyc
  ADD COLUMN IF NOT EXISTS phone TEXT;

-- Événements : entrée libre + paiement frais de publication
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS is_free BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS publish_fee_amount INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS publish_fee_paid BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS publish_fee_reference TEXT,
  ADD COLUMN IF NOT EXISTS publish_fee_paid_at TIMESTAMPTZ;

-- Invitations (événements gratuits)
CREATE TABLE IF NOT EXISTS public.invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  guest_name TEXT,
  guest_phone TEXT,
  guest_email TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'validated', 'used', 'cancelled')),
  created_by UUID REFERENCES public.profiles(id),
  validated_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invitations_event ON public.invitations(event_id);
CREATE INDEX IF NOT EXISTS idx_invitations_code ON public.invitations(code);

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizer manages invitations"
  ON public.invitations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id AND e.organizer_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id AND e.organizer_id = auth.uid()
    )
  );

CREATE POLICY "Guests can read own invitation by code"
  ON public.invitations FOR SELECT
  USING (true);

-- Publication : KYC approved + (payant OK | gratuit avec frais payés)
CREATE OR REPLACE FUNCTION public.check_publish_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.organizer_kyc k
      WHERE k.user_id = NEW.organizer_id AND k.status = 'approved'
    ) THEN
      RAISE EXCEPTION 'KYC organisateur non approuvé';
    END IF;

    IF NEW.is_free = true AND NEW.publish_fee_paid = false THEN
      RAISE EXCEPTION 'Frais de publication (50000 FCFA) non payés pour événement gratuit';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS events_publish_kyc ON public.events;
DROP TRIGGER IF EXISTS events_publish_rules ON public.events;
CREATE TRIGGER events_publish_rules
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.check_publish_rules();
