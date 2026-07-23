import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      }
    );

    // Authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Load learning profile
    const { data: profile, error: profileError } = await supabase
      .from("learning_profiles")
      .select("*")
      .eq("user_id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: "Learning profile not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Load words due for review (lapsed or learning, ordered by last reviewed)
    const { data: dueWords } = await supabase
      .from("vocabulary")
      .select("id, word, translation, status, times_seen, times_correct")
      .eq("user_id", user.id)
      .in("status", ["lapsed", "learning", "recognizing"])
      .order("last_reviewed_at", { ascending: true, nullsFirst: true })
      .limit(10);

    // Create a new session entry
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .insert({
        user_id: user.id,
        started_at: new Date().toISOString(),
        status: "active",
      })
      .select("id, started_at")
      .single();

    if (sessionError) {
      return new Response(
        JSON.stringify({ error: "Failed to create session", detail: sessionError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        session_id: session.id,
        started_at: session.started_at,
        profile: {
          display_name: profile.display_name,
          current_level: profile.current_level,
          target_level: profile.target_level,
          primary_goal: profile.primary_goal,
          max_new_words_per_session: profile.max_new_words_per_session,
          preferred_session_minutes: profile.preferred_session_minutes,
        },
        due_words: dueWords ?? [],
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
