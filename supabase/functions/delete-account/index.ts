/**
 * delete-account edge function
 *
 * Permanently deletes the authenticated user's data and their auth account.
 * Deletes owned rows explicitly (rather than relying on cascading foreign
 * keys) since `profiles` and `birth_details` are not tracked in this repo's
 * migrations and their FK setup isn't verifiable here — explicit deletes
 * work regardless of whether cascade is configured. `birth_charts` and
 * `chat_quotas` do have `on delete cascade` to `auth.users` (see
 * 20260428000000_chat_ai.sql), but deleting them explicitly first is
 * harmless and keeps this function correct even if that migration changes.
 *
 * Order matters: data tables are cleared before the auth user, so a
 * blocking (non-cascading) FK on any table can't leave the auth deletion
 * half-finished.
 *
 * POST, no body required — the user is identified from the auth header.
 */

import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { adminClient } from "../_shared/db.ts";

const OWNED_TABLES = ["profiles", "birth_details", "birth_charts", "chat_quotas"];

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  try {
    const { userId } = await requireAuth(req);
    const db = adminClient();

    for (const table of OWNED_TABLES) {
      const { error } = await db.from(table).delete().eq("user_id", userId);
      if (error) {
        // Log and continue — the auth user deletion below is what actually
        // revokes access, so a stray row in one table shouldn't block it.
        console.error(`delete-account: failed to clear ${table}:`, error);
      }
    }

    const { error: authError } = await db.auth.admin.deleteUser(userId);
    if (authError) {
      console.error("delete-account: failed to delete auth user:", authError);
      return new Response(
        JSON.stringify({ error: "Failed to delete account", detail: authError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    if (err instanceof Response) return err; // Auth throws a Response directly

    console.error("delete-account error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
