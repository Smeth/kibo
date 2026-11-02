import { handleDeletion } from "../../supabase/functions/kibo-delete-account/index.ts";
const actor = "33333333-3333-4333-8333-333333333333",
  subject = "11111111-1111-4111-8111-111111111111";
const config = {
  url: "https://fixture.invalid",
  anon: "public-fixture",
  service: "server-fixture",
};
function request() {
  return new Request("https://fixture.invalid/function", {
    method: "POST",
    headers: { Authorization: "Bearer fixture" },
    body: JSON.stringify({ subject, version: 1, confirmation: "SUPPRIMER" }),
  });
}
function check(value: unknown, message: string) {
  if (!value) throw new Error(message);
}
Deno.test('admin without server-approved strengthened session cannot delete', async () => {
  let calls = 0;
  const response = await handleDeletion(request(), config, async (input) => {
    calls++;
    if (String(input).endsWith('/auth/v1/user')) return Response.json({
      id: actor, app_metadata: { role: 'admin' }, last_sign_in_at: new Date().toISOString(),
    });
    if (String(input).endsWith('/kibo_can_moderate')) return Response.json(false);
    throw new Error('No privileged target access allowed');
  });
  check(response.status === 403 && calls === 2, 'MFA/server authorization bypass');
});
Deno.test("non-admin and stale admin cannot start deletion", async () => {
  for (
    const user of [{
      id: actor,
      app_metadata: { role: "user" },
      last_sign_in_at: new Date().toISOString(),
    }, {
      id: actor,
      app_metadata: { role: "admin" },
      last_sign_in_at: "2020-01-01",
    }]
  ) {
    let calls = 0;
    const response = await handleDeletion(request(), config, async () => {
      calls++;
      return Response.json(user);
    });
    check(response.status === 403 && calls === 1, "Unauthorized deletion");
  }
});
Deno.test("storage failure prevents Auth deletion and completion", async () => {
  const calls: string[] = [];
  const response = await handleDeletion(request(), config, async (input) => {
    const url = String(input);
    calls.push(url);
    if (url.endsWith("/auth/v1/user")) {
      return Response.json({
        id: actor,
        app_metadata: { role: "admin" },
        last_sign_in_at: new Date().toISOString(),
      });
    }
    if (url.includes("/auth/v1/admin/users/")) {
      return Response.json({ id: subject, app_metadata: {} });
    }
    if (url.endsWith("/kibo_can_moderate")) return Response.json(true);
    if (url.endsWith("/kibo_deletion_begin")) {
      return Response.json({ id: "fixture-job", phase: "frozen" });
    }
    if (url.endsWith("/kibo_deletion_purge")) {
      return new Response(null, { status: 204 });
    }
    if (url.endsWith("/kibo_deletion_objects")) {
      return Response.json([{
        bucket: "private-photos",
        path: "server-selected-path",
      }]);
    }
    if (url.includes("/storage/")) return new Response(null, { status: 503 });
    throw new Error("Unexpected call");
  });
  check(response.status === 409, "Failure not reported");
  check(
    !calls.some((c) =>
      c.endsWith("/kibo_deletion_ready") ||
      c.endsWith("/kibo_deletion_complete")
    ),
    "Advanced after failed storage",
  );
});
Deno.test("completion requires Auth absence; replay resumes after purge", async () => {
  const calls: string[] = [];
  let authGone = false;
  const response = await handleDeletion(
    request(),
    config,
    async (input, options) => {
      const url = String(input);
      if (url.endsWith("/kibo_can_moderate")) return Response.json(true);
      calls.push(url);
      if (url.endsWith("/auth/v1/user")) {
        return Response.json({
          id: actor,
          app_metadata: { role: "admin" },
          last_sign_in_at: new Date().toISOString(),
        });
      }
      if (url.includes("/auth/v1/admin/users/")) {
        if (options?.method === "DELETE") {
          authGone = true;
          return Response.json({});
        }
        return authGone
          ? new Response(null, { status: 404 })
          : Response.json({ id: subject, app_metadata: {} });
      }
      if (url.endsWith("/kibo_deletion_begin")) {
        return Response.json({
          id: "fixture-job",
          phase: "purged",
        });
      }
      if (url.endsWith("/kibo_deletion_objects")) return Response.json([]);
      if (url.endsWith("/kibo_deletion_ready")) return Response.json(true);
      if (url.endsWith("/kibo_deletion_complete")) {
        check(
          authGone,
          "False completion",
        );
      }
      return new Response(null, { status: 204 });
    },
  );
  check(
    response.status === 200 && (await response.json()).phase === "completed",
    "Completion failed",
  );
  check(
    calls.some((c) => c.endsWith("/kibo_deletion_complete")),
    "No completion checkpoint",
  );
});
