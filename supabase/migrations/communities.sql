-- Communities table
CREATE TABLE communities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    poster_image_url TEXT,
    admin_id UUID NOT NULL REFERENCES user_profiles(id),
    is_private BOOLEAN DEFAULT false,
    member_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Community members table
CREATE TABLE community_members (
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    PRIMARY KEY (community_id, user_id)
);

-- Community topics/categories
CREATE TABLE community_topics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Community messages
CREATE TABLE community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    topic_id UUID REFERENCES community_topics(id) ON DELETE SET NULL,
    content TEXT,
    image_url TEXT,
    parent_id UUID REFERENCES community_messages(id) ON DELETE CASCADE,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message reactions (upvotes/downvotes)
CREATE TABLE message_reactions (
    message_id UUID REFERENCES community_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    reaction_type TEXT CHECK (reaction_type IN ('upvote', 'downvote')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

-- User notifications
CREATE TABLE user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    message_id UUID REFERENCES community_messages(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('new_post', 'mention', 'reply', 'join_request')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add columns to user_profiles
ALTER TABLE user_profiles
ADD COLUMN is_verified BOOLEAN DEFAULT false,
ADD COLUMN is_expert BOOLEAN DEFAULT false,
ADD COLUMN notification_preferences JSONB DEFAULT '{"muted_communities": [], "muted_topics": []}';

-- Create necessary indexes
CREATE INDEX idx_community_members_user ON community_members(user_id);
CREATE INDEX idx_community_messages_community ON community_messages(community_id);
CREATE INDEX idx_community_messages_topic ON community_messages(topic_id);
CREATE INDEX idx_user_notifications_user ON user_notifications(user_id);

-- RLS Policies
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;

-- Communities policies
CREATE POLICY "Communities are viewable by everyone" ON communities
    FOR SELECT USING (true);

CREATE POLICY "Users can create communities" ON communities
    FOR INSERT WITH CHECK (auth.uid() IN (SELECT id FROM user_profiles));

CREATE POLICY "Admins can update their communities" ON communities
    FOR UPDATE USING (auth.uid() = admin_id);

-- Community members policies
CREATE POLICY "Members are viewable by everyone" ON community_members
    FOR SELECT USING (true);

CREATE POLICY "Users can request to join" ON community_members
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        status = 'pending'
    );

CREATE POLICY "Admins can manage members" ON community_members
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM communities
            WHERE id = community_id AND admin_id = auth.uid()
        )
    );

-- Messages policies
CREATE POLICY "Messages are viewable by members" ON community_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM community_members
            WHERE community_id = community_messages.community_id
            AND user_id = auth.uid()
            AND status = 'approved'
        )
    );

CREATE POLICY "Members can post messages" ON community_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM community_members
            WHERE community_id = community_messages.community_id
            AND user_id = auth.uid()
            AND status = 'approved'
        )
    );