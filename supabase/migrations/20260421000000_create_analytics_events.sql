-- Analytics events table for the KisanVeer app.
-- Populated via batched inserts from lib/services/analytics_service.dart.
CREATE TABLE IF NOT EXISTS analytics_events (
  id          BIGSERIAL PRIMARY KEY,
  event_name  TEXT        NOT NULL,
  user_id     UUID        NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  parameters  JSONB       NOT NULL DEFAULT '{}'::jsonb,
  occurred_at TIMESTAMPTZ NOT NULL,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_event_name
  ON analytics_events (event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id
  ON analytics_events (user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_occurred_at
  ON analytics_events (occurred_at DESC);

-- Row-level security: a user may insert rows that reference their own id
-- (or no id for anonymous events), but may not read or modify anyone else's.
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS analytics_events_insert_own ON analytics_events;
CREATE POLICY analytics_events_insert_own
  ON analytics_events FOR INSERT TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

DROP POLICY IF EXISTS analytics_events_insert_anon ON analytics_events;
CREATE POLICY analytics_events_insert_anon
  ON analytics_events FOR INSERT TO anon
  WITH CHECK (user_id IS NULL);

DROP POLICY IF EXISTS analytics_events_select_own ON analytics_events;
CREATE POLICY analytics_events_select_own
  ON analytics_events FOR SELECT TO authenticated
  USING (user_id = auth.uid());
