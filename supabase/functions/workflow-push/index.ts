// Vision Forge Workflow: sends iPhone notifications when a project is added
// or its notes change. Called by the projects_notify database trigger.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const APP_URL = "https://sahibgrewal9815.github.io/Vision-Forge-Workflow/";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

let config: { hook: string; vapid_private: string; vapid_public: string } | null = null;
async function getConfig() {
  if (config) return config;
  const { data, error } = await db.rpc("workflow_push_config");
  if (error || !data?.hook || !data?.vapid_private) throw new Error("push config missing");
  config = data;
  webpush.setVapidDetails("mailto:notifications@visionforge.app", data.vapid_public, data.vapid_private);
  return config!;
}

function clip(s: string, n = 180) {
  s = s.replace(/\s+/g, " ").trim();
  return s.length > n ? s.slice(0, n - 1).trimEnd() + "…" : s;
}

// What was added to the notes: the new tail if text was appended, otherwise the whole note
function notesChange(oldNotes: string, newNotes: string) {
  const o = (oldNotes || "").trim();
  const n = (newNotes || "").trim();
  if (o && n.startsWith(o)) {
    const added = n.slice(o.length).trim();
    if (added) return added;
  }
  return n;
}

function buildMessage(type: string, rec: any, old: any) {
  const name = rec?.name || "Project";
  if (type === "INSERT") {
    const parts = [rec?.type, rec?.person].filter(Boolean);
    return { title: `New project: ${name}`, body: parts.join(" · ") || "Added to Workflow", tag: `new-${rec.id}` };
  }
  if (type === "UPDATE") {
    const text = notesChange(old?.notes, rec?.notes);
    if (!text) return null;
    return { title: `${name} notes updated`, body: clip(text), tag: `notes-${rec.id}` };
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  let cfg;
  try { cfg = await getConfig(); } catch (e) { return new Response(String(e), { status: 500 }); }
  if (req.headers.get("x-hook-secret") !== cfg.hook) return new Response("forbidden", { status: 403 });

  const { type, record, old_record } = await req.json();
  const msg = buildMessage(type, record, old_record);
  if (!msg) return Response.json({ sent: 0, skipped: "nothing to send" });

  const { data: subs, error } = await db.from("push_subscriptions").select("endpoint,p256dh,auth,device_id");
  if (error) return new Response(error.message, { status: 500 });

  const targets = (subs || []).filter((s) => !record?.last_editor || s.device_id !== record.last_editor);
  const payload = JSON.stringify({ ...msg, url: APP_URL });

  let sent = 0;
  const gone: string[] = [];
  await Promise.all(targets.map(async (s) => {
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        payload,
        { TTL: 60 * 60 * 24, urgency: "high" },
      );
      sent++;
    } catch (e: any) {
      if (e?.statusCode === 404 || e?.statusCode === 410) gone.push(s.endpoint);
      else console.error("push failed", e?.statusCode, e?.body || e?.message);
    }
  }));
  if (gone.length) await db.from("push_subscriptions").delete().in("endpoint", gone);

  return Response.json({ sent, removed: gone.length, total: targets.length });
});
