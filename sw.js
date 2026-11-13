// Vision Forge Workflow service worker: shows notifications
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

self.addEventListener("push", (event) => {
  let data = {};
  try { data = event.data ? event.data.json() : {}; } catch (e) { data = { title: "Vision Forge", body: event.data && event.data.text() }; }
  const title = data.title || "Vision Forge";
  event.waitUntil(
    self.registration.showNotification(title, {
      body: data.body || "",
      icon: "icon-180.png",
      badge: "icon-180.png",
      tag: data.tag,
      data: { url: data.url || self.registration.scope }
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || self.registration.scope;
  event.waitUntil((async () => {
    const wins = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    for (const w of wins) { if ("focus" in w) { w.postMessage("refresh"); return w.focus(); } }
    if (self.clients.openWindow) return self.clients.openWindow(url);
  })());
});
