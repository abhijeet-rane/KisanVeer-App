-- Communities table
CREATE TABLE communities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    admin_id UUID NOT NULL REFERENCES user_profiles(id),
    is_private BOOLEAN DEFAULT false,
    member_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    poster_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Community members table
CREATE TABLE community_members (
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    role TEXT DEFAULT 'member', -- 'member', 'moderator', 'admin'
    PRIMARY KEY (community_id, user_id)
);

-- Join requests table
CREATE TABLE community_join_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    UNIQUE (community_id, user_id)
);

-- Community messages table
CREATE TABLE community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    content TEXT,
    image_urls TEXT[],
    reply_to UUID REFERENCES community_messages(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    thread_id UUID
);

-- Community threads table
CREATE TABLE community_threads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message reactions table
CREATE TABLE message_reactions (
    message_id UUID REFERENCES community_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

-- User notifications table
CREATE TABLE user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'mention', 'reply', 'new_post', 'join_request'
    content TEXT,
    reference_id UUID, -- Can reference message_id, thread_id, etc.
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User notification preferences
CREATE TABLE notification_preferences (
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    muted BOOLEAN DEFAULT false,
    PRIMARY KEY (user_id, community_id)
);

-- Add verification status to user_profiles
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'none', -- 'none', 'verified_farmer', 'expert'
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Create storage bucket for community images
INSERT INTO storage.buckets (id, name)
VALUES ('community_images', 'community_images')
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Communities are viewable by authenticated users"
ON communities FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can create communities"
ON communities FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = admin_id);

CREATE POLICY "Admins can update their communities"
ON communities FOR UPDATE
TO authenticated
USING (auth.uid() = admin_id);

CREATE POLICY "Members can view community messages"
ON community_messages FOR SELECT
TO authenticated
USING (
    auth.uid() IN (
        SELECT user_id FROM community_members
        WHERE community_id = community_messages.community_id
    )
);

CREATE POLICY "Members can send messages"
ON community_messages FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT user_id FROM community_members
        WHERE community_id = community_messages.community_id
    )
);

CREATE POLICY "Members can view threads"
ON community_threads FOR SELECT
TO authenticated
USING (
    auth.uid() IN (
        SELECT user_id FROM community_members
        WHERE community_id = community_threads.community_id
    )
);

CREATE POLICY "Members can create threads"
ON community_threads FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT user_id FROM community_members
        WHERE community_id = community_threads.community_id
    )
);

-- Functions
CREATE OR REPLACE FUNCTION increment_member_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE communities
    SET member_count = member_count + 1
    WHERE id = NEW.community_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_member_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE communities
    SET member_count = GREATEST(member_count - 1, 0)
    WHERE id = OLD.community_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_post_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE communities
    SET post_count = post_count + 1
    WHERE id = NEW.community_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER increment_member_count_trigger
AFTER INSERT ON community_members
FOR EACH ROW
EXECUTE FUNCTION increment_member_count();

CREATE TRIGGER decrement_member_count_trigger
AFTER DELETE ON community_members
FOR EACH ROW
EXECUTE FUNCTION decrement_member_count();

CREATE TRIGGER increment_post_count_trigger
AFTER INSERT ON community_messages
FOR EACH ROW
EXECUTE FUNCTION increment_post_count();
