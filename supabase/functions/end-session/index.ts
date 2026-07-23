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

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Expected body: { session_id }
    const body = await req.json();
    const { session_id } = body;

    if (!session_id) {
      return new Response(
        JSON.stringify({ error: "Missing required field: session_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify session belongs to this user
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .select("id, started_at, status")
      .eq("id", session_id)
      .eq("user_id", user.id)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Session not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (session.status === "completed") {
      return new Response(
        JSON.stringify({ error: "Session already completed" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Load all exercise logs for this session
    const { data: logs } = await supabase
      .from("exercise_logs")
      .select("vocabulary_id, rating")
      .eq("session_id", session_id)
      .eq("user_id", user.id);

    const totalExercises = logs?.length ?? 0;
    const correct = logs?.filter((l) => l.rating === "correct").length ?? 0;
    const near = logs?.filter((l) => l.rating === "near").length ?? 0;
    const wrong = logs?.filter((l) => l.rating === "wrong").length ?? 0;
    const uniqueWords = new Set(logs?.map((l) => l.vocabulary_id)).size;
    const accuracyPct = totalExercises > 0
      ? Math.round((correct / totalExercises) * 100)
      : 0;

    const endedAt = new Date().toISOString();
    const startedAt = new Date(session.started_at);
    const durationSeconds = Math.round(
      (new Date(endedAt).getTime() - startedAt.getTime()) / 1000
    );

    // Close the session
    const { error: updateError } = await supabase
      .from("sessions")
      .update({
        status: "completed",
        ended_at: endedAt,
        duration_seconds: durationSeconds,
        total_exercises: totalExercises,
        correct_count: correct,
        near_count: near,
        wrong_count: wrong,
        unique_words_practiced: uniqueWords,
        accuracy_pct: accuracyPct,
      })
      .eq("id", session_id)
      .eq("user_id", user.id);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: "Failed to close session", detail: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        session_id,
        summary: {
          duration_seconds: durationSeconds,
          total_exercises: totalExercises,
          unique_words_practiced: uniqueWords,
          correct,
          near,
          wrong,
          accuracy_pct: accuracyPct,
        },
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
