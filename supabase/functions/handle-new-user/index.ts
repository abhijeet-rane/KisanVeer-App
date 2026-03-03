import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

serve(async (req) => {
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
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
