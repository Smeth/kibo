// Proposition locale : aucun déploiement effectué. Bucket privé, pas d'upload
// direct authenticated. Le secret serveur n'est jamais transmis au client.
import jpeg from "npm:jpeg-js@0.4.4";

const bucket = "kibo-listing-photos";
const maxBytes = 4 * 1024 * 1024;
const jsonLimit = 6 * 1024 * 1024;
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
};
function reply(status: number, data: object) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

export async function handleUpload(
  req: Request,
  config: { url?: string; anon?: string; service?: string },
  fetcher: typeof fetch = fetch,
): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, { error: "method" });
  const { url, anon, service } = config;
  if (!url || !anon || !service) return reply(503, { error: "configuration" });
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return reply(401, { error: "authentication" });
  }
  try {
    // Validation du jeton côté Auth, sans confiance dans des claims client.
    const headers = { apikey: anon, Authorization: authorization };
    const auth = await fetcher(`${url}/auth/v1/user`, { headers });
    if (!auth.ok) return reply(401, { error: "authentication" });
    const user = await auth.json();
    if (typeof user.id !== "string" || !uuid.test(user.id)) {
      return reply(401, { error: "authentication" });
    }
    const reader = req.body?.getReader();
    if (!reader) return reply(400, { error: "body" });
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > jsonLimit) {
        await reader.cancel();
        return reply(413, { error: "size" });
      }
      chunks.push(value);
    }
    const input = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      input.set(chunk, offset);
      offset += chunk.length;
    }
    const body = JSON.parse(new TextDecoder().decode(input));
    if (
      !uuid.test(body.listingId ?? "") || !Number.isInteger(body.position) ||
      body.position < 0 || body.position > 2 ||
      !/^[0-9a-f]{64}$/.test(body.digest ?? "") ||
      typeof body.base64 !== "string"
    ) return reply(400, { error: "fields" });
    const binary = atob(body.base64);
    if (!binary.length || binary.length > maxBytes) {
      return reply(413, { error: "size" });
    }
    const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
    const hash = Array.from(
      new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
    )
      .map((b) => b.toString(16).padStart(2, "0")).join("");
    if (hash !== body.digest) return reply(400, { error: "digest" });
    // Décodage complet borné : une extension ou un MIME déclaré ne suffit pas.
    const decoded = jpeg.decode(bytes, {
      useTArray: true,
      maxResolutionInMP: 3,
      maxMemoryUsageInMB: 64,
    });
    if (
      !decoded.width || !decoded.height || decoded.width > 1600 ||
      decoded.height > 1600
    ) return reply(400, { error: "dimensions" });
    // Pixels uniquement : ne jamais exposer les GPS/EXIF d'un client malveillant.
    const clean = jpeg.encode({
      width: decoded.width,
      height: decoded.height,
      data: decoded.data,
    }, 82).data;
    if (clean.length > maxBytes) return reply(413, { error: "size" });
    let path = `${user.id}/${body.listingId}/${body.position}-${hash}.jpg`;
    if (body.operationId != null) {
      if (!uuid.test(body.operationId)) {
        return reply(400, { error: "operation" });
      }
      const ticket = await fetcher(
        `${url}/rest/v1/rpc/kibo_photo_upload_ticket`,
        {
          method: "POST",
          headers: { ...headers, "Content-Type": "application/json" },
          body: JSON.stringify({
            p_operation: body.operationId,
            p_digest: hash,
          }),
        },
      );
      if (!ticket.ok) return reply(403, { error: "ticket" });
      const approved = await ticket.json();
      if (
        approved.listing_id !== body.listingId ||
        typeof approved.path !== "string"
      ) return reply(403, { error: "ticket" });
      path = approved.path;
    } else {
      const listing = await fetcher(
        `${url}/rest/v1/listings?id=eq.${body.listingId}&select=seller_id,status`,
        { headers },
      );
      if (!listing.ok) return reply(403, { error: "listing" });
      const rows = await listing.json();
      if (
        rows.length !== 1 || rows[0].seller_id !== user.id ||
        !["draft", "pending", "published"].includes(rows[0].status)
      ) return reply(403, { error: "owner" });
      const reservation = await fetcher(
        `${url}/rest/v1/kibo_listing_photos?listing_id=eq.${body.listingId}&position=eq.${body.position}&select=owner_id,path`,
        { headers },
      );
      if (!reservation.ok) return reply(403, { error: "reservation" });
      const photos = await reservation.json();
      if (
        photos.length !== 1 || photos[0].owner_id !== user.id ||
        photos[0].path !== path
      ) return reply(403, { error: "reservation" });
    }
    const leaseResponse = await fetcher(
      `${url}/rest/v1/rpc/kibo_photo_transfer_begin`,
      {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({ p_path: path }),
      },
    );
    if (!leaseResponse.ok) return reply(409, { error: "transfer" });
    const lease = await leaseResponse.json();
    const uploaded = await fetcher(
      `${url}/storage/v1/object/${bucket}/${path}`,
      {
        method: "POST",
        body: Uint8Array.from(clean),
        headers: {
          apikey: service,
          Authorization: `Bearer ${service}`,
          "Content-Type": "image/jpeg",
          "x-upsert": "false",
        },
      },
    );
    // A network interruption leaves a lease: deletion must wait for reconciliation.
    if (uploaded.status < 500) {
      const finished = await fetcher(
        `${url}/rest/v1/rpc/kibo_photo_transfer_finish`,
        {
          method: "POST",
          headers: {
            apikey: service,
            Authorization: `Bearer ${service}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ p_ticket: lease, p_uncertain: false }),
        },
      );
      if (!finished.ok) return reply(502, { error: "transfer_confirmation" });
    }
    if (!uploaded.ok) {
      const error = await uploaded.json().catch(() => ({}));
      if (
        uploaded.status !== 409 && String(error.statusCode) !== "409" &&
        error.error !== "Duplicate"
      ) return reply(502, { error: "storage" });
      // Même chemin = même hash ; seuls les fichiers validés par ce code peuvent
      // être écrits dans ce bucket. Aucune politique client INSERT/UPDATE.
    }
    return reply(200, { ok: true, path });
  } catch (_) {
    // Ne jamais journaliser de jeton, de données image ou d'erreur fournisseur.
    return reply(400, { error: "invalid_or_unavailable" });
  }
}

if (import.meta.main) {
  Deno.serve((req) =>
    handleUpload(req, {
      url: Deno.env.get("SUPABASE_URL"),
      anon: Deno.env.get("SUPABASE_ANON_KEY"),
      service: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
    })
  );
}
