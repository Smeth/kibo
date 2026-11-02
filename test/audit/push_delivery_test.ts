import { handlePush } from "../../supabase/functions/kibo-send-push/index.ts";
const request = () => new Request("https://fixture.invalid", { method: "POST", headers: { Authorization: "Bearer fixture-server" } });
const config = { url: "https://fixture.invalid", service: "fixture-server", enabled: "true" };
function check(value: unknown) { if (!value) throw new Error("Assertion failed"); }
Deno.test("push disabled or unauthenticated never claims work", async () => {
  const fetcher: typeof fetch = () => { throw new Error("No external calls allowed"); };
  check((await handlePush(new Request("https://fixture.invalid", { method: "POST" }), config, fetcher)).status === 401);
  check((await handlePush(request(), { ...config, enabled: "false" }, fetcher)).status === 503);
});
Deno.test("push partial failure is retried, dead tokens removed, lease checked", async () => {
  const calls: object[] = [];
  const fetcher: typeof fetch = async (url, init) => {
    if (String(url).endsWith("kibo_push_claim")) return Response.json([{ id: "notice-fixture", lease: "lease-fixture", tokens: ["good", "dead", "offline"] }]);
    check(String(url).endsWith("kibo_push_ack")); calls.push(JSON.parse(String(init?.body))); return new Response(null, { status: 204 });
  };
  const result = await handlePush(request(), config, fetcher, async token => token === "good" ? "sent" : token === "dead" ? "invalid" : "retry");
  check(result.status === 200);
  check(JSON.stringify(calls) === JSON.stringify([{ p_id: "notice-fixture", p_lease: "lease-fixture", p_ok: false, p_invalid: ["dead"] }]));
  check(!JSON.stringify(await result.json()).includes("offline"));
});
Deno.test("push errors never include account secrets or tokens", async () => {
  const result = await handlePush(request(), config, async () => { throw new Error("SECRET-FIXTURE"); }, async () => "sent");
  check(result.status === 502 && !JSON.stringify(await result.json()).includes("SECRET-FIXTURE"));
});
