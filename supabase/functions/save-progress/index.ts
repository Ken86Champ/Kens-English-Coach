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

    // Expected body: { session_id, word_id, rating: "correct"|"near"|"wrong", notes? }
    const body = await req.json();
    const { session_id, word_id, rating, notes } = body;

    if (!session_id || !word_id || !rating) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: session_id, word_id, rating" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const validRatings = ["correct", "near", "wrong"];
    if (!validRatings.includes(rating)) {
      return new Response(
        JSON.stringify({ error: "Invalid rating. Must be: correct, near, or wrong" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Load current word state
    const { data: word, error: wordError } = await supabase
      .from("vocabulary")
      .select("id, status, times_seen, times_correct, streak")
      .eq("id", word_id)
      .eq("user_id", user.id)
      .single();

    if (wordError || !word) {
      return new Response(
        JSON.stringify({ error: "Word not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Calculate new status based on rating and current streak
    const newTimesSeen = (word.times_seen ?? 0) + 1;
    const newTimesCorrect =
      rating === "correct" ? (word.times_correct ?? 0) + 1 : (word.times_correct ?? 0);
    const newStreak =
      rating === "correct" ? (word.streak ?? 0) + 1 : 0;

    const newStatus = computeNewStatus(word.status, rating, newStreak);

    // Update vocabulary entry
    const { error: updateError } = await supabase
      .from("vocabulary")
      .update({
        status: newStatus,
        times_seen: newTimesSeen,
        times_correct: newTimesCorrect,
        streak: newStreak,
        last_reviewed_at: new Date().toISOString(),
      })
      .eq("id", word_id)
      .eq("user_id", user.id);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: "Failed to update word", detail: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Log the exercise result
    const { error: logError } = await supabase
      .from("exercise_logs")
      .insert({
        user_id: user.id,
        session_id,
        vocabulary_id: word_id,
        rating,
        notes: notes ?? null,
        logged_at: new Date().toISOString(),
      });

    if (logError) {
      return new Response(
        JSON.stringify({ error: "Failed to log exercise", detail: logError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        word_id,
        previous_status: word.status,
        new_status: newStatus,
        streak: newStreak,
        times_correct: newTimesCorrect,
        times_seen: newTimesSeen,
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

function computeNewStatus(
  current: string,
  rating: string,
  streak: number
): string {
  if (rating === "wrong") {
    // Downgrade on wrong answer
    const downgrade: Record<string, string> = {
      stable: "active",
      conversational: "active",
      active: "learning",
      learning: "recognizing",
      recognizing: "lapsed",
      lapsed: "lapsed",
      new: "new",
    };
    return downgrade[current] ?? current;
  }

  if (rating === "near") {
    // Stay at current level on near-miss
    return current;
  }

  // Upgrade on correct answer based on streak
  if (streak >= 5 && current === "active") return "conversational";
  if (streak >= 8 && current === "conversational") return "stable";
  if (streak >= 3 && current === "learning") return "active";
  if (streak >= 2 && current === "recognizing") return "learning";
  if (streak >= 1 && current === "lapsed") return "recognizing";
  if (streak >= 1 && current === "new") return "recognizing";

  return current;
}
