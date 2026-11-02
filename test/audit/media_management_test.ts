import { handleManage } from "../../supabase/functions/kibo-manage-listing-photos/index.ts";
const config = {
  url: "https://fixture.invalid",
  anon: "public-fixture",
  service: "server-fixture",
};
function request() {
  return new Request("https://fixture.invalid/function", {
    method: "POST",
    headers: { Authorization: "Bearer fixture" },
    body: JSON.stringify({
      listingId: "fixture",
      operationId: "fixture",
      revision: 0,
      paths: ["caller-path"],
    }),
  });
}
function check(v: unknown, m: string) {
  if (!v) throw new Error(m);
}
Deno.test("gallery cleanup only removes paths from trusted RPC, never caller paths", async () => {
  let removed = false;
  const response = await handleManage(
    request(),
    config,
    async (input, options) => {
      const url = String(input);
      if (url.endsWith("/auth/v1/user")) {
        return Response.json({
          id: "fixture-user",
        });
      }
      if (url.endsWith("/kibo_apply_photo_edit")) {
        return Response.json({
          revision: 1,
          paths: ["caller-path"],
        });
      }
      if (url.endsWith("/kibo_photo_cleanup_queue")) {
        return Response.json([{
          path: "server-garbage",
        }]);
      }
      if (url.includes("/storage/")) {
        check(
          JSON.parse(String(options?.body)).prefixes[0] === "server-garbage",
          "Untrusted path",
        );
        removed = true;
        return Response.json([]);
      }
      if (url.endsWith("/kibo_photo_cleanup_ack")) {
        return new Response(null, {
          status: 204,
        });
      }
      throw new Error("Unexpected request");
    },
  );
  check(response.status === 200 && removed, "Cleanup failed");
  check((await response.json()).cleanup_pending === false, "False pending");
});
Deno.test("failed gallery commit never removes any Storage object", async () => {
  let calls = 0;
  const response = await handleManage(request(), config, async (input) => {
    calls++;
    const url = String(input);
    if (url.endsWith("/auth/v1/user")) {
      return Response.json({ id: "fixture-user" });
    }
    if (url.endsWith("/kibo_apply_photo_edit")) {
      return new Response(null, { status: 409 });
    }
    throw new Error("Unexpected destructive request");
  });
  check(
    response.status === 409 && calls === 2,
    "Commit failure crossed boundary",
  );
});
Deno.test("cleanup failure keeps committed gallery and reports pending purge", async () => {
  const response = await handleManage(request(), config, async (input) => {
    const url = String(input);
    if (url.endsWith("/auth/v1/user")) {
      return Response.json({ id: "fixture-user" });
    }
    if (url.endsWith("/kibo_apply_photo_edit")) {
      return Response.json({ revision: 1 });
    }
    if (url.endsWith("/kibo_photo_cleanup_queue")) {
      return Response.json([{ path: "server-garbage" }]);
    }
    return new Response(null, { status: 503 });
  });
  const result = await response.json();
  check(
    response.status === 200 && result.ok && result.cleanup_pending,
    "Committed state lost",
  );
});
