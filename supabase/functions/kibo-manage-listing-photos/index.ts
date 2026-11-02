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
export async function handleManage(
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
    const headers = {
      apikey: anon,
      Authorization: authorization,
      "Content-Type": "application/json",
    };
    const auth = await fetcher(`${url}/auth/v1/user`, { headers });
    if (!auth.ok) return reply(401, { error: "authentication" });
    if (Number(req.headers.get("content-length")) > 4096) {
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
      if (size > 4096) {
        await reader.cancel();
        return reply(413, { error: "size" });
      }
      raw += decoder.decode(value, { stream: true });
    }
    raw += decoder.decode();
    const body = JSON.parse(raw);
    let state = null;
    if (body.action !== "cleanup") {
      const applied = await fetcher(
        `${url}/rest/v1/rpc/kibo_apply_photo_edit`,
        {
          method: "POST",
          headers,
          body: JSON.stringify({
            p_listing: body.listingId,
            p_operation: body.operationId,
            p_revision: body.revision,
            p_paths: body.paths,
          }),
        },
      );
      if (!applied.ok) {
        return reply(applied.status === 409 ? 409 : 400, {
          error: "gallery_conflict_or_invalid",
        });
      }
      state = await applied.json();
    }
    // Only server-generated garbage paths may be removed with service credentials.
    let pending = false;
    const queue = await fetcher(`${url}/rest/v1/rpc/kibo_photo_cleanup_queue`, {
      method: "POST",
      headers,
      body: "{}",
    });
    if (!queue.ok) pending = true;
    else {for (const item of await queue.json()) {
        try {
          const serviceHeaders = {
            apikey: service,
            Authorization: `Bearer ${service}`,
            "Content-Type": "application/json",
          };
          const removed = await fetcher(
            `${url}/storage/v1/object/kibo-listing-photos`,
            {
              method: "DELETE",
              headers: serviceHeaders,
              body: JSON.stringify({ prefixes: [item.path] }),
            },
          );
          if (!removed.ok) {
            pending = true;
            continue;
          }
          const ack = await fetcher(
            `${url}/rest/v1/rpc/kibo_photo_cleanup_ack`,
            {
              method: "POST",
              headers: serviceHeaders,
              body: JSON.stringify({ p_path: item.path }),
            },
          );
          if (!ack.ok) pending = true;
        } catch {
          pending = true;
        }
      }}
    return reply(200, { ok: true, state, cleanup_pending: pending });
  } catch {
    return reply(503, { error: "unavailable" });
  }
}
if (import.meta.main) {
  Deno.serve((req) =>
    handleManage(req, {
      url: Deno.env.get("SUPABASE_URL"),
      anon: Deno.env.get("SUPABASE_ANON_KEY"),
      service: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
    })
  );
}
