const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization,apikey,content-type,x-client-info",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
};
function reply(status: number, data: object) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export async function handleDeletion(
  req: Request,
  config: { url?: string; anon?: string; service?: string },
  fetcher: typeof fetch = fetch,
): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, { error: "method" });
  const { url, anon, service } = config;
  if (!url || !anon || !service) return reply(503, { error: "configuration" });
  try {
    const authorization = req.headers.get("Authorization") ?? "";
    if (!authorization.startsWith("Bearer ")) {
      return reply(401, { error: "authentication" });
    }
    const auth = await fetcher(`${url}/auth/v1/user`, {
      headers: { apikey: anon, Authorization: authorization },
    });
    if (!auth.ok) return reply(401, { error: "authentication" });
    const actor = await auth.json();
    if (actor.app_metadata?.role !== "admin") {
      return reply(403, { error: "admin_required" });
    }
    const signed = Date.parse(actor.last_sign_in_at);
    if (
      !Number.isFinite(signed) || Date.now() - signed > 10 * 60 * 1000 ||
      signed > Date.now() + 60000
    ) return reply(403, { error: "fresh_login_required" });
    if (Number(req.headers.get("content-length")) > 1024) {
      return reply(413, { error: "size" });
    }
    const reader = req.body?.getReader();
    if (!reader) return reply(400, { error: "body" });
    let raw = "", size = 0;
    const decoder = new TextDecoder();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 1024) {
        await reader.cancel();
        return reply(413, { error: "size" });
      }
      raw += decoder.decode(value, { stream: true });
    }
    raw += decoder.decode();
    const body = JSON.parse(raw);
    if (
      !uuid.test(body.subject ?? "") || !Number.isSafeInteger(body.version) ||
      body.version < 1 || body.confirmation !== "SUPPRIMER" ||
      body.subject === actor.id
    ) return reply(400, { error: "confirmation" });
    const headers = {
      apikey: service,
      Authorization: `Bearer ${service}`,
      "Content-Type": "application/json",
    };
    const target = await fetcher(`${url}/auth/v1/admin/users/${body.subject}`, {
      headers,
    });
    if (target.ok) {
      const user = await target.json();
      if ((user.user ?? user).app_metadata?.role === "admin") {
        return reply(403, { error: "admin_target_forbidden" });
      }
    } else if (target.status !== 404) {
      return reply(503, { error: "target_verification" });
    }
    async function rpc(name: string, args: object) {
      const result = await fetcher(`${url}/rest/v1/rpc/${name}`, {
        method: "POST",
        headers,
        body: JSON.stringify(args),
      });
      if (!result.ok) throw new Error("rpc");
      const text = await result.text();
      return text ? JSON.parse(text) : null;
    }
    const job = await rpc("kibo_deletion_begin", {
      p_subject: body.subject,
      p_actor: actor.id,
      p_version: body.version,
    });
    if (job.phase === "completed") {
      return reply(200, { ok: true, phase: "completed" });
    }
    await rpc("kibo_deletion_purge", { p_job: job.id });
    // Bounded work per invocation; the administrator can resume the same operation.
    for (let batch = 0; batch < 4; batch++) {
      const objects = await rpc("kibo_deletion_objects", { p_job: job.id });
      if (objects.length === 0) break;
      const groups = new Map<string, string[]>();
      for (const item of objects) {
        if (!groups.has(item.bucket)) groups.set(item.bucket, []);
        groups.get(item.bucket)!.push(item.path);
      }
      for (const [bucket, paths] of groups) {
        const removed = await fetcher(
          `${url}/storage/v1/object/${encodeURIComponent(bucket)}`,
          {
            method: "DELETE",
            headers,
            body: JSON.stringify({ prefixes: paths }),
          },
        );
        if (!removed.ok) throw new Error("storage");
        for (const path of paths) {
          await rpc("kibo_deletion_object_ack", {
            p_job: job.id,
            p_bucket: bucket,
            p_path: path,
          });
        }
      }
    }
    if (await rpc("kibo_deletion_ready", { p_job: job.id }) !== true) {
      return reply(200, { ok: true, phase: "processing" });
    }
    const deleted = await fetcher(
      `${url}/auth/v1/admin/users/${body.subject}`,
      {
        method: "DELETE",
        headers,
        body: JSON.stringify({ should_soft_delete: false }),
      },
    );
    if (!deleted.ok && deleted.status !== 404) throw new Error("auth");
    const verified = await fetcher(
      `${url}/auth/v1/admin/users/${body.subject}`,
      { headers },
    );
    if (verified.status !== 404) throw new Error("auth_verification");
    await rpc("kibo_deletion_complete", { p_job: job.id });
    return reply(200, { ok: true, phase: "completed" });
  } catch {
    return reply(409, { error: "deletion_unconfirmed_resume_or_review" });
  }
}
if (import.meta.main) {
  Deno.serve((req) =>
    handleDeletion(req, {
      url: Deno.env.get("SUPABASE_URL"),
      anon: Deno.env.get("SUPABASE_ANON_KEY"),
      service: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
    })
  );
}
