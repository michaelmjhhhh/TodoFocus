# TodoFocus

<p align="center">
  <img src="assets/readme-logo.png" alt="TodoFocus Icon" width="108" />
</p>

<p align="center">
  <strong>Stop collecting tasks. Start finishing them.</strong><br/>
  A local-first macOS task app built for real focus.
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/badge/Download-Latest%20Release-0A84FF?style=for-the-badge" /></a>
  <a href="#build-from-source"><img src="https://img.shields.io/badge/Build-From%20Source-2F855A?style=for-the-badge" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" />
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-F2994A" />
  <img src="https://img.shields.io/badge/Data-Local%20SQLite-4F8A3D" />
</p>

<p align="center">
  <img src="assets/overdue-screenshot.png" width="980" />
</p>

---

## ✨ What this feels like

You’re in the middle of something.

- Thoughts are messy  
- Tasks are everywhere  
- Tabs are out of control  

Then:

1. Hit `⌘⇧T` → dump everything instantly  
2. Attach links / files to your task  
3. Start a Deep Focus session  
4. Come back and clean your day in Kanban  

No friction. No distractions. Just flow.

---

## 🧠 Why TodoFocus

Most task apps are built to **store tasks**.

TodoFocus is built to **finish them**.

- ⚡ Instant capture (no context switching)
- 🎯 Built-in focus sessions
- 🚀 Launch everything you need in one click
- 🧹 End your day with clarity

> No login. No cloud. No nonsense.  
> Just you and your work.

---

## 🚀 Core Features

| Area | What you get |
|---|---|
| Quick Capture | Global shortcut `⌘⇧T` to capture from anywhere |
| Voice Capture | Speak your tasks (English `en-US`) |
| Deep Focus | Timer-based focus sessions with stats |
| Hard Focus | App blocking with enforced exit flow |
| Launchpad | Attach URL/file/app → run everything instantly |
| Daily Review | Kanban cleanup: Open vs Completed |
| Smart Views | `My Day`, `Important`, `Overdue`, and more |
| Search | `⌘K` to instantly find anything |
| Portability | JSON import/export (local-first) |

---

## 🔥 What makes it different

### 🧩 Context is built-in
Tasks aren’t just text.

Attach:
- links  
- files  
- apps  

→ and launch everything in one click.

---

### 🎯 Focus is not optional
Deep Focus + Hard Focus:

- timer  
- menu bar control  
- optional app blocking  

→ designed to actually keep you working

---

### 🧹 Daily Review that you’ll actually use
Not analytics.

Just:
- Overdue  
- Today  
- Tomorrow  
- Done  

→ clean, fast, and honest

---

## ⚡ Quick Start

1. Download latest release  
2. Move app to `Applications`  
3. Open and grant permissions  
4. Hit `⌘⇧T` → add your first task  
5. Start one Deep Focus session  

You’re in.

---

## 📦 Data & Privacy

- 100% local SQLite  
- No account required  
- No cloud dependency  

Data lives in:

```
~/Library/Application Support/todofocus/
```

---

## 🛠 Build From Source

```bash
brew install xcodegen
git clone --recurse-submodules https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac

xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac"
```

---

## 🎬 Demo

<p align="center">
  <img src="assets/demo.gif" width="980" />
</p>

---

## 💬 Feedback

Issues & ideas:  
https://github.com/michaelmjhhhh/TodoFocus/issues

---

## ⭐ If this helped you

If TodoFocus saved you even **10 minutes today**:

👉 give it a ⭐

It really helps the project grow.
