# Vision Forge Workflow

Track projects, their status and who's working on them.

- **iPhone app**: open the link, then tap Share → **Add to Home Screen**
- **Rainmeter widget**: shows the top 3 projects on your Windows desktop
- **Data**: saved in Supabase, so the app and widget always match

**App link:** https://sahibgrewal9815.github.io/Vision-Forge-Workflow/

---

## Using the app

| What | How |
|---|---|
| Add a project | Tap **New project** |
| Edit / see details | Tap any project |
| Change status | 🔴 To do · 🟡 In process · 🟢 Done |
| Change order | Up / down arrows. The **top 3 show on the desktop widget** |
| Change background photo | Tap the camera button on the photo (saved on that phone only) |
| Set a time | Edit a project → **Time to finish** (hours + minutes) |
| Notifications | Tap **Turn on notifications** (home-screen app only). You get a notification when a project is added or notes change |

No login: anyone with the link can view and edit, so share it only with your team.

---

## Installing the desktop widget (Windows)

1. Install Rainmeter from https://www.rainmeter.net
2. Download **`VisionForgeWorkflow.rmskin`** from this repo and double-click it → **Install**
3. The widget appears on your desktop. Drag it wherever you like.

Right-click the widget for:
- **Change photo**: choose any picture from your PC
- **Refresh now**
- **Open Vision Forge app**
- **Size**: 100% to 60%

**Timers:** projects with a time set show **▶ Start**. Press it and a line fills up: green, then yellow, then red. When time is up, the line turns red, shows how far over it is, and Windows shows a pop-up once. Changing the time in the app or marking the project Done clears the timer.

The widget checks for changes every 30 seconds.

### Optional: blurred glass behind the widget
1. Download and install the FrostedGlass plugin: https://github.com/KazukiGames82/FrostedGlass/releases
2. Right-click the widget → **Turn blur on/off**

---

## Files

| Path | What it is |
|---|---|
| `index.html`, `config.js`, `manifest.json` | The iPhone app (served by GitHub Pages) |
| `rainmeter/Workflow/` | The widget source |
| `VisionForgeWorkflow.rmskin` | The widget installer |
| `supabase/setup.sql` | Creates the `projects` table |
