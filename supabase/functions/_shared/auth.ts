import { createClient, User } from "@supabase/supabase-js";

export interface AuthResult {
  userId: string;
  user: User;
}

/**
 * Extracts and verifies the Supabase JWT from the Authorization header.
 * Returns the authenticated user_id and full user object, or throws if invalid.
 */
export async function requireAuth(req: Request): Promise<AuthResult> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    throw new Response(
      JSON.stringify({ error: "Missing or invalid Authorization header" }),
      { status: 401, headers: { "Content-Type": "application/json" } }
    );
  }

  const jwt = authHeader.replace("Bearer ", "");

  // Use anon client to verify the JWT — getUser validates it against Supabase Auth
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!
  );

  const { data, error } = await supabase.auth.getUser(jwt);
  if (error || !data.user) {
    throw new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { "Content-Type": "application/json" } }
    );
  }

  return { userId: data.user.id, user: data.user };
}
