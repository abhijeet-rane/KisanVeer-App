import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

serve(async (req) => {
    const supabase = createClient(
        Deno.env.get('https://wmqpftdxdduhbdsjybzu.supabase.co') ?? '',
        Deno.env.get('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndtcXBmdGR4ZGR1aGJkc2p5Ynp1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MjA0NTEzNSwiZXhwIjoyMDU3NjIxMTM1fQ.tz5vPpc0EyR057ZpatIjDmM85Wt9k58_EZX_0w1bp5I') ?? ''
    );

    const { event, session } = await req.json();

    if (event !== 'INSERT') {
        return new Response('Only INSERT events are handled', { status: 400 });
    }

    const { id, email, raw_user_meta_data } = session?.user || {};

    const { phone, display_name, user_type } = raw_user_meta_data || {};

    const { error } = await supabase.from('user_profiles').insert({
        id,
        email,
        phone,
        display_name,
        user_type
    });

    if (error) {
        return new Response(`Error: ${error.message}`, { status: 500 });
    }

    return new Response('User profile created', { status: 200 });
});
