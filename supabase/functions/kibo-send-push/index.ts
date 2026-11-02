type Config = { url?: string; service?: string; account?: string; enabled?: string };
type Sender = (token: string, notice: string) => Promise<"sent" | "invalid" | "retry">;
function reply(status: number, body: object) {
  return Response.json(body, { status });
}
const base64url = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes))
  .replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
async function firebaseSender(accountJson: string, fetcher: typeof fetch): Promise<Sender> {
  const account = JSON.parse(accountJson);
  if (!/^[a-z][a-z0-9-]{4,62}$/.test(account.project_id ?? "") ||
    typeof account.client_email !== "string" || typeof account.private_key !== "string") throw new Error("configuration");
  const now = Math.floor(Date.now() / 1000);
  const encode = (value: object) => base64url(new TextEncoder().encode(JSON.stringify(value)));
  const input = encode({ alg: "RS256", typ: "JWT" }) + "." + encode({
    iss: account.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600,
  });
  const raw = account.private_key.replace(/-----[^-]+-----|\s/g, "");
  const key = await crypto.subtle.importKey("pkcs8", Uint8Array.from(atob(raw), c => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(input));
  const auth = await fetcher("https://oauth2.googleapis.com/token", { method: "POST",
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: input + "." + base64url(new Uint8Array(signature)) }),
    signal: AbortSignal.timeout(10000),
  });
  if (!auth.ok) throw new Error("authentication");
  const access = (await auth.json()).access_token;
  if (typeof access !== "string" || !access) throw new Error("authentication");
  return async (token, notice) => {
    const response = await fetcher(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
      method: "POST", headers: { Authorization: `Bearer ${access}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message: { token,
        notification: { title: "KIBO", body: "Vous avez une nouvelle activité. Ouvrez KIBO pour la consulter." },
        data: { notice_id: notice }, android: { ttl: "86400s", notification: { tag: notice } },
      } }), signal: AbortSignal.timeout(10000),
    });
    if (response.ok) return "sent";
    const error = await response.json().catch(() => ({}));
    if (error.error?.details?.some((detail: { errorCode?: string }) => detail.errorCode === "UNREGISTERED")) return "invalid";
    return "retry";
  };
}
export async function handlePush(req: Request, config: Config, fetcher: typeof fetch = fetch, sender?: Sender): Promise<Response> {
  if (req.method !== "POST") return reply(405, { error: "method" });
  if (!config.service || req.headers.get("Authorization") !== `Bearer ${config.service}`) return reply(401, { error: "authentication" });
  if (config.enabled !== "true" || !config.url || (!config.account && !sender)) return reply(503, { error: "not_enabled" });
  try {
    // Obtain FCM credentials before claiming work; no secrets or message text in logs.
    const send = sender ?? await firebaseSender(config.account!, fetcher);
    const rpc = async (name: string, body: object) => {
      const response = await fetcher(`${config.url}/rest/v1/rpc/${name}`, { method: "POST",
        headers: { apikey: config.service!, Authorization: `Bearer ${config.service}`, "Content-Type": "application/json" },
        body: JSON.stringify(body), signal: AbortSignal.timeout(10000),
      });
      if (!response.ok) throw new Error("rpc");
      const text = await response.text(); return text ? JSON.parse(text) : null;
    };
    const jobs = await rpc("kibo_push_claim", {});
    if (!Array.isArray(jobs) || jobs.length > 10) throw new Error("queue");
    let completed = 0;
    for (const job of jobs) {
      if (!Array.isArray(job.tokens) || job.tokens.length > 5) throw new Error("devices");
      let ok = true;
      const invalid = [];
      for (const token of job.tokens) {
        const result = await send(token, job.id);
        if (result === "invalid") invalid.push(token);
        if (result === "retry") ok = false;
      }
      await rpc("kibo_push_ack", { p_id: job.id, p_lease: job.lease, p_ok: ok, p_invalid: invalid });
      if (ok) completed++;
    }
    return reply(200, { processed: jobs.length, completed });
  } catch (_) { return reply(502, { error: "delivery_unconfirmed" }); }
}
if (import.meta.main) Deno.serve(req => handlePush(req, {
  url: Deno.env.get("SUPABASE_URL"), service: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
  account: Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON"), enabled: Deno.env.get("KIBO_PUSH_ENABLED"),
}));
