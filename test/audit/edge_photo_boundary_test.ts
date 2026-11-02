// Audit local : Auth/REST/Storage simules. Aucun appel reseau n'est permis.
import jpeg from "npm:jpeg-js@0.4.4";
import { handleUpload } from "../../supabase/functions/kibo-upload-listing-photo/index.ts";

Deno.test("image bruitée 1600x1600 : limite utile réelle du décodeur serveur", async () => {
  const raw = new Uint8Array(1600 * 1600 * 4);
  let seed = 123456789;
  for (let i = 0; i < raw.length; i += 4) {
    for (let channel = 0; channel < 3; channel++) {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      raw[i + channel] = seed >>> 24;
    }
    raw[i + 3] = 255;
  }
  const encoded = Uint8Array.from(
    jpeg.encode({ width: 1600, height: 1600, data: raw }, 82).data,
  );
  if (encoded.length > 4194304) throw new Error("Fixture hors limite client");
  const digest = Array.from(
    new Uint8Array(await crypto.subtle.digest("SHA-256", encoded)),
  )
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  let binary = "";
  for (let i = 0; i < encoded.length; i += 16384) {
    binary += String.fromCharCode(...encoded.subarray(i, i + 16384));
  }
  const owner = "11111111-1111-4111-8111-111111111111";
  const listing = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
  const path = `${owner}/${listing}/0-${digest}.jpg`;
  let writes = 0;
  const fetcher: typeof fetch = async (url, options) => {
    const endpoint = String(url);
    if (endpoint.endsWith("/auth/v1/user")) return Response.json({ id: owner });
    if (endpoint.endsWith("/kibo_photo_transfer_begin")) {
      return Response.json("fixture-lease");
    }
    if (endpoint.endsWith("/kibo_photo_transfer_finish")) {
      return new Response(null, { status: 204 });
    }
    if (endpoint.includes("/rest/v1/listings?")) {
      return Response.json([{ seller_id: owner, status: "published" }]);
    }
    if (endpoint.includes("/rest/v1/kibo_listing_photos?")) {
      return Response.json([{ owner_id: owner, path }]);
    }
    if (!endpoint.includes("/storage/v1/object/")) {
      throw new Error("Unexpected fixture request");
    }
    if (options?.method !== "POST") throw new Error("Unexpected fixture write");
    writes++;
    return Response.json({ Key: path });
  };
  const request = new Request("https://fixture.invalid/function", {
    method: "POST",
    headers: { Authorization: "Bearer fixture-user" },
    body: JSON.stringify({
      listingId: listing,
      position: 0,
      digest,
      base64: btoa(binary),
    }),
  });
  const start = performance.now();
  const response = await handleUpload(request, {
    url: "https://fixture.invalid",
    anon: "public-fixture",
    service: "server-fixture",
  }, fetcher);
  const result = await response.json();
  console.log(
    JSON.stringify({
      inputBytes: encoded.length,
      status: response.status,
      writes,
      elapsedMs: Math.round(performance.now() - start),
    }),
  );
  if (
    response.status !== 200 || !result.ok || result.path !== path ||
    writes !== 1
  ) {
    throw new Error(
      "Image autorisée par le client refusée par le validateur serveur",
    );
  }
});
