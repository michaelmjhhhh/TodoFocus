# Hard Focus System Design

> **Status:** Approved for implementation
> **Date:** 2026-03-27
> **System:** TodoFocus macOS app

---

## Overview

Hard Focus is a session-based app blocking system for macOS. It terminates distracting apps during focus sessions and prevents reopening until the session ends. The system is designed to be hard-to-bypass, crash-resilient, and operable under normal macOS user permissions (no MDM).

---

## Architecture

### Components

```
┌──────────────────────────────────────────────────────────────┐
│ Main App (SwiftUI)                                           │
│  - Verifies Accessibility permission before session start    │
│  - Owns all DB writes to hardfocus_session (single-writer)  │
│  - Shows lock screen during active session                   │
│  - Monitors agent heartbeat for UI diagnostics               │
└──────────────────────────────────────────────────────────────┘
                              │ DB write (single-writer)
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ SQLite (App Group: group.com.todofocus)                     │
│  Tables: hardfocus_session, agent_heartbeat                │
└──────────────────────────────────────────────────────────────┘
                              ▲ DB read (read-only for agent)
                              │
┌──────────────────────────────────────────────────────────────┐
│ HardFocusAgent (Command-line LaunchAgent, Always-Alive)      │
│  States: IDLE → ACTIVE → IDLE                               │
│  IDLE:   poll DB every 60s, look for status='active'      │
│  ACTIVE: poll DB every 5s, enforce blocking + observers    │
│  Writes heartbeat every 30s (current_session_id confirm)  │
│  NEVER writes to hardfocus_session (read-only except beat)   │
└──────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **SQLite is the single source of truth** — all state derives from the DB; no in-memory session state that isn't persisted
2. **Single-writer model** — only the main app mutates `hardfocus_session`; agent is read-only except heartbeat
3. **Always-alive agent** — avoids startup race conditions; crash recovery is automatic via KeepAlive
4. **Notifications are hints, not triggers** — distributed notifications optimistically wake the agent faster; polling is the authoritative fallback

---

## Database Schema

```sql
CREATE TABLE hardfocus_session (
    session_id          TEXT PRIMARY KEY,
    mode                TEXT NOT NULL,            -- 'hard' | 'soft'
    status              TEXT NOT NULL DEFAULT 'active',  -- 'active' | 'completed' | 'interrupted'
    start_time          DATETIME NOT NULL,
    planned_end_time    DATETIME NOT NULL,
    actual_end_time     DATETIME,
    unlock_phrase_hash  TEXT NOT NULL,            -- Argon2 hash, never plaintext
    blocked_apps        TEXT NOT NULL,             -- JSON array of bundle IDs
    focus_task_id       TEXT,
    grace_seconds       INTEGER NOT NULL DEFAULT 300,
    created_at          DATETIME NOT NULL
);

CREATE TABLE agent_heartbeat (
    agent_id            TEXT PRIMARY KEY DEFAULT 'primary',
    last_heartbeat      DATETIME NOT NULL,
    current_session_id  TEXT   -- NULL when agent is IDLE
);

CREATE INDEX idx_session_active ON hardfocus_session(status) WHERE status = 'active';
```

### Fields

| Field | Purpose |
|-------|---------|
| `session_id` | UUID primary key |
| `mode` | `'hard'` (app blocking) or `'soft'` (overlay only) |
| `status` | `'active'` \| `'completed'` \| `'interrupted'` |
| `start_time` | When session began |
| `planned_end_time` | Scheduled end (timer expiry) |
| `actual_end_time` | Set when session ends |
| `unlock_phrase_hash` | Argon2 hash of user's passphrase; plaintext never stored |
| `blocked_apps` | JSON array of bundle identifiers (e.g. `["com.apple.Safari"]`) |
| `focus_task_id` | Optional link to TodoFocus task being focused |
| `grace_seconds` | Grace window after planned_end_time before agent treats session as overdue (default 300s) |
| `current_session_id` in heartbeat | Confirms which session the agent is actively enforcing (UI diagnostics only) |

---

## Session Lifecycle

### State Transitions (Main App Only)

```
[none] ──(start session)──► [active] ──(timer/unlock)──► [completed]
                                     └──(emergency escape)──► [interrupted]
```

- **`active`**: Agent is enforcing. Main app shows lock screen.
- **`completed`**: Normal end (timer expired or user entered correct passphrase).
- **`interrupted`**: Emergency escape triggered (user re-authenticated to quit).

### Start Protocol

```
1. Main app verifies AXIsProcessTrusted() — refuse if false
2. Main app checks agent heartbeat is alive (last_heartbeat within 120s)
   → If dead: show error "Hard Focus agent unavailable"
3. Main app writes new row: status='active', planned_end_time, blocked_apps, etc.
4. Agent poll (within 5s) sees status='active' → begins enforcement
5. Main app shows lock screen UI
```

### End Protocol

```
Timer expires OR user enters passphrase:
1. Main app updates status='completed', sets actual_end_time
2. Agent poll (within 5s) sees status != 'active' → cleanup → return to IDLE
3. Main app hides lock screen
```

Emergency escape:
```
1. User triggers emergency (re-authenticate)
2. Main app updates status='interrupted', sets actual_end_time
3. Agent cleans up and returns to IDLE
```

### Overdue Condition

`overdue` is **ephemeral**, not a persistent status. Computed at poll time:

```swift
let isOverdue = Date() > session.plannedEndTime
let graceEndTime = session.plannedEndTime.addingTimeInterval(TimeInterval(session.graceSeconds))

if isOverdue && Date() > graceEndTime {
    // Beyond grace window — agent could stop strict enforcement
    // Main app's timer firing is the authoritative end event regardless
}
```

The agent continues basic monitoring during the grace window. The main app's timer firing is the authoritative end signal.

---

## Enforcement Model

### Agent State Machine

```
                    ┌─────────────────────────────────┐
                    │            IDLE                │
                    │  poll DB every 60s              │
                    │  status='active' found?         │
                    └──────────────┬──────────────────┘
                                   │ yes
                    ┌──────────────▼──────────────────┐
                    │           ACTIVE                 │
                    │  - Initial sweep (kill blocked) │
                    │  - Register NSWorkspace obs.    │
                    │  - poll DB every 5s              │
                    │  - write heartbeat every 30s    │
                    └──────────────┬──────────────────┘
                                   │ status != 'active'
                    ┌──────────────▼──────────────────┐
                    │          CLEANUP                 │
                    │  - Unregister observers         │
                    │  - Return to IDLE               │
                    └─────────────────────────────────┘
```

### Three-Layer Detection

| Layer | Mechanism | Covers |
|-------|-----------|--------|
| Initial sweep | Enumerate `NSWorkspace.shared.runningApplications` on activation | Blocked apps already running before session started |
| Launch detection | `NSWorkspace.didLaunchApplicationNotification` | Blocked apps launched while session is active |
| Activation fallback | `NSWorkspace.didActivateApplicationNotification` | Blocked apps launched just before observer registered (activation triggers check) |

### Kill Strategy

```
1. Call app.terminate()           -- graceful, works across user boundaries
2. Wait up to 3s for termination
3. If still running: call app.forceTerminate()  -- NSRunningApplication API
4. SIGKILL only as last resort for OWN processes (same uid check)
```

`forceTerminate()` is the correct sandboxed API. SIGKILL (`kill -9`) from a different UID silently fails under sandbox restrictions.

### Blocked App Matching

Match by bundle identifier. The `blocked_apps` JSON stores canonical bundle IDs:
- `com.apple.Safari`
- `com.google.Chrome`
- `com.hnc.Discord`

Compare against `NSRunningApplication.bundleIdentifier`.

---

## Agent Lifecycle: Always-Alive

The agent runs continuously as a LaunchAgent. When no session is active it idles.

### Why Always-Alive Over Start/Stop

| | Start/Stop Per Session | Always-Alive |
|---|---|---|
| Startup race | Yes — must ensure agent alive before signaling | None |
| Crash mid-session | Enforcement stops until main app detects + restarts | Self-healing via KeepAlive |
| Signal mechanism | Notification + DB (race-prone) | DB polling only |
| Complexity | SMAppService lifecycle + crash monitoring | Idle/active state machine |

Always-alive is simpler and more reliable. Idle resource cost is negligible (~1% CPU polling every 60s).

### LaunchAgent Configuration

```xml
~/Library/LaunchAgents/com.todofocus.hardfocus.agent.plist
KeepAlive: true
RunAtLoad: true
```

The agent is installed once via `SMAppService.agent(plistName:)` and runs permanently.

### Notifications as Optimization

Distributed notifications (`com.todofocus.hardfocus.session.changed`) are sent by the main app as a hint: "check DB now." The agent immediately polls on receipt. This reduces latency from 60s down to near-instant.

**This is never required** — the agent polls every 5s (active) or 60s (idle). If a notification is lost, the next poll catches up.

---

## IPC and State Sync

### Single-Writer Enforcement

```
Main App                          Agent
─────────                          ─────
write session row ───────────────► reads
     │                                    │
     │                              initial sweep
     │                              register observers
     ▼                                    │
heartbeat confirmation (UI only)  ◄──── writes heartbeat
     │
     ▼
lock screen (or not)
```

**The agent never writes session status.** This eliminates inter-process write races. The agent reads `status`, enforces accordingly, and writes only heartbeat.

### Heartbeat: Diagnostics Only

Heartbeat monitoring by the main app is for UX indicators only:
- "Agent is alive" status in UI
- `current_session_id` matching confirms agent is enforcing the right session

**Enforcement does not depend on heartbeat.** If heartbeat stops:
1. KeepAlive restarts the agent
2. Agent reads DB, sees `status='active'`, resumes enforcement
3. Main app may show a brief "reconnecting..." indicator

---

## Unlock Mechanism

### Normal Unlock

```
User types passphrase
  → Argon2 hash computed client-side
  → compared to unlock_phrase_hash in DB
  → if match: main app sets status='completed'
```

### Emergency Escape

Forces re-authentication before allowing session end. Marks session as `interrupted` (not `completed`) to distinguish from normal unlock.

**Implementation note:** macOS does not expose Apple ID re-authentication to third-party apps without MDM or Screen Time. The emergency escape requires the user to authenticate in System Preferences / Apple ID settings, which is a strong deterrent but not programmatically enforceable from the app. Document this honestly: the emergency escape requires manual re-authentication outside the app.

---

## Permissions

### Accessibility Permission

`AXIsProcessTrusted()` must return `true` before a Hard Focus session starts. The app should:
1. Check on launch; prompt if not granted
2. Refuse to start Hard Focus sessions if false
3. Guide user to System Preferences → Privacy → Accessibility

### Screen Recording (if needed for certain enforcement paths)

Some app visibility APIs require Screen Recording permission. Check `CGPreflightScreenCaptureAccess()`.

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Agent killed by user (`kill -9`) | KeepAlive restarts agent; reads DB; resumes if `status='active'` and within grace |
| System reboot | Agent starts at login via `RunAtLoad`; finds any `status='active'` session; resumes |
| Permissions revoked mid-session | Enforcement degrades; agent logs blocked app attempts; session continues to timer |
| Blocked app updates bundle ID | User must update `blocked_apps` list; no automatic migration |
| Agent crash during enforcement | KeepAlive restarts; reads DB; if `planned_end_time` not exceeded + within grace: resume |
| Grace period exceeded | Agent may stop strict enforcement; main app timer is authoritative regardless |
| App terminated by system (macOS suspend) | Agent restarts via KeepAlive; resumes from DB state |

---

## Security Properties

- **No plaintext secrets** — `unlock_phrase_hash` only; passphrase never leaves main app memory
- **User-level only** — no root, no MDM, no system extension required
- **Sandbox-compatible** — uses `terminate()` and `forceTerminate()` APIs; SIGKILL only for same-UID processes
- **Cannot block macOS system apps** — protected processes reject `terminate()`; this is intentional
- **Single-writer DB** — no inter-process write races; agent is read-only except heartbeat

---

## Files to Create

```
macos/TodoFocusMac/Sources/
  App/
    HardFocusAgentManager.swift   -- SMAppService lifecycle, heartbeat monitoring
    HardFocusSessionManager.swift -- session lifecycle (start/end/unlock)
  Agent/
    main.swift                    -- agent entry point
    AgentSessionController.swift -- idle/active state machine
    AppEnforcer.swift             -- 3-layer blocking enforcement
    AgentDatabase.swift           -- read-only DB access
    HeartbeatWriter.swift         -- heartbeat every 30s

macos/TodoFocusMac/Sources/Data/
  Database/
    HardFocusMigrations.swift    -- new migration for hardfocus_session + agent_heartbeat tables
```

---

## Out of Scope

- Soft focus (overlay-only mode) — existing `DeepFocusService` handles this
- Blocking by process name (not bundle ID) — bundle ID is the canonical identifier
- MDM / system-level enforcement — user-level only
- App updates during session — user must re-block after app update if bundle ID changes
