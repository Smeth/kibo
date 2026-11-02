import jpeg from "npm:jpeg-js@0.4.4";
import { handleUpload } from "./index.ts";

function assert(
  condition: unknown,
  message = "assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}
const owner = "11111111-1111-4111-8111-111111111111";
const listing = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const config = {
  url: "https://fixture.invalid",
  anon: "public-fixture",
  service: "server-fixture",
};
const bytes =
  jpeg.encode({ width: 2, height: 2, data: new Uint8Array(16).fill(255) }, 82)
    .data;
async function body(data: Uint8Array = bytes) {
  let binary = "";
  for (let i = 0; i < data.length; i += 16384) {
    binary += String.fromCharCode(...data.subarray(i, i + 16384));
  }
  const digest = Array.from(
    new Uint8Array(
      await crypto.subtle.digest("SHA-256", Uint8Array.from(data)),
    ),
  )
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  return {
    listingId: listing,
    position: 0,
    digest,
    base64: btoa(binary),
  };
}
function request(payload: object, auth = true) {
  return new Request("https://fixture.invalid/function", {
    method: "POST",
    body: JSON.stringify(payload),
    headers: auth ? { Authorization: "Bearer fixture-user" } : {},
  });
}
Deno.test("upload valide, isolation vendeur et reprise idempotente", async () => {
  const input = await body();
  const path = `${owner}/${listing}/0-${input.digest}.jpg`;
  let uploads = 0;
  let seller = owner;
  const fetcher: typeof fetch = async (url, options) => {
    const endpoint = String(url);
    if (endpoint.endsWith("/auth/v1/user")) return Response.json({ id: owner });
    if (endpoint.endsWith("/kibo_photo_transfer_begin")) {
      assert(new Headers(options?.headers).get("Authorization") === "Bearer fixture-user");
      assert(JSON.parse(String(options?.body)).p_path === path);
      return Response.json("fixture-lease");
    }
    if (endpoint.endsWith("/kibo_photo_transfer_finish")) {
      assert(new Headers(options?.headers).get("Authorization") === "Bearer server-fixture");
      assert(JSON.parse(String(options?.body)).p_ticket === "fixture-lease");
      return new Response(null, { status: 204 });
    }
    if (endpoint.includes("/rest/v1/listings?")) {
      return Response.json([{ seller_id: seller, status: "published" }]);
    }
    if (endpoint.includes("/rest/v1/kibo_listing_photos?")) {
      return Response.json([{ owner_id: owner, path }]);
    }
    assert(endpoint.includes(`/storage/v1/object/kibo-listing-photos/${path}`));
    const headers = new Headers(options?.headers);
    assert(headers.get("Authorization") === "Bearer server-fixture");
    assert(headers.get("x-upsert") === "false");
    uploads++;
    return uploads === 1
      ? Response.json({ Key: path })
      : Response.json({ statusCode: "409", error: "Duplicate" }, {
        status: 409,
      });
  };
  for (let i = 0; i < 2; i++) {
    const response = await handleUpload(request(input), config, fetcher);
    assert(response.status === 200);
    const json = await response.json();
    assert(json.ok && json.path === path);
  }
  seller = "22222222-2222-4222-8222-222222222222";
  assert((await handleUpload(request(input), config, fetcher)).status === 403);
  assert(uploads === 2);
});

Deno.test("refus Storage 403/404/500 traduit en 502, puis reprise même chemin", async () => {
  const input = await body();
  const path = `${owner}/${listing}/0-${input.digest}.jpg`;
  for (const status of [403, 404, 500]) {
    let writes = 0;
    const fetcher: typeof fetch = async (url, options) => {
      const endpoint = String(url);
      if (endpoint.endsWith("/auth/v1/user")) {
        return Response.json({ id: owner });
      }
      if (endpoint.endsWith("/kibo_photo_transfer_begin")) {
        assert(JSON.parse(String(options?.body)).p_path === path);
        return Response.json("fixture-lease");
      }
      if (endpoint.endsWith("/kibo_photo_transfer_finish")) {
        assert(JSON.parse(String(options?.body)).p_ticket === "fixture-lease");
        return new Response(null, { status: 204 });
      }
      if (endpoint.includes("/rest/v1/listings?")) {
        return Response.json([{ seller_id: owner, status: "published" }]);
      }
      if (endpoint.includes("/rest/v1/kibo_listing_photos?")) {
        return Response.json([{ owner_id: owner, path }]);
      }
      assert(
        endpoint.endsWith(`/storage/v1/object/kibo-listing-photos/${path}`),
      );
      assert(options?.method === "POST");
      assert(new Headers(options.headers).get("x-upsert") === "false");
      writes++;
      return writes === 1
        ? Response.json({ error: "fixture upstream confidential" }, { status })
        : Response.json({ Key: path });
    };
    const failed = await handleUpload(request(input), config, fetcher);
    assert(failed.status === 502);
    assert(JSON.stringify(await failed.json()) === '{"error":"storage"}');
    const retried = await handleUpload(request(input), config, fetcher);
    assert(retried.status === 200);
    assert((await retried.json()).path === path);
    assert(writes === 2);
  }
});

Deno.test("limites serveur de taille, dimensions et emplacement", async () => {
  let writes = 0;
  const fetcher: typeof fetch = async (url, options) => {
    if (options?.method === "POST") writes++;
    assert(String(url).endsWith("/auth/v1/user"));
    return Response.json({ id: owner });
  };
  assert(
    (await handleUpload(
      request(await body(new Uint8Array(4 * 1024 * 1024 + 1))),
      config,
      fetcher,
    )).status === 413,
  );
  assert(
    (await handleUpload(
      request({ base64: "x".repeat(6 * 1024 * 1024) }),
      config,
      fetcher,
    )).status === 413,
  );
  const wide =
    jpeg.encode({ width: 1601, height: 1, data: new Uint8Array(1601 * 4) }, 82)
      .data;
  assert(
    (await handleUpload(request(await body(wide)), config, fetcher)).status ===
      400,
  );
  assert(
    (await handleUpload(
      request({ ...await body(), position: 3 }),
      config,
      fetcher,
    )).status === 400,
  );
  assert(writes === 0);
});
Deno.test("octets invalides, hash usurpe, session absente : pas d'ecriture", async () => {
  let writes = 0;
  const fetcher: typeof fetch = async (url, options) => {
    if (options?.method === "POST") writes++;
    assert(String(url).endsWith("/auth/v1/user"));
    return Response.json({ id: owner });
  };
  const invalid = await body(new Uint8Array([1, 2, 3]));
  assert(
    (await handleUpload(request(invalid), config, fetcher)).status === 400,
  );
  const mismatch = { ...await body(), digest: "0".repeat(64) };
  assert(
    (await handleUpload(request(mismatch), config, fetcher)).status === 400,
  );
  assert(
    (await handleUpload(request(await body(), false), config, fetcher))
      .status === 401,
  );
  assert(writes === 0);
});
