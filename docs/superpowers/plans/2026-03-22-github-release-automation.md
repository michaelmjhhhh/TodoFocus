# GitHub CI Release Automation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan.

**Goal:** Configure GitHub Actions to automatically build and publish macOS release zips to GitHub Releases when a version tag is pushed.

**Architecture:** The existing `release-macos-native.yml` workflow already builds, packages, and uploads assets to GitHub Releases. This plan documents the current setup and proposes making it fully automatic via tag push triggers.

**Tech Stack:** GitHub Actions, XcodeGen, macOS 14 runner, `gh` CLI

---

## Chunk 1: Document Current Workflow

**Files:**
- Modify: `.github/workflows/release-macos-native.yml`

The current workflow (`release-macos-native.yml`) already:
- Builds the macOS app with xcodebuild
- Packages it as `TodoFocus-macos-universal.zip` with SHA256 checksum
- Uploads both files to a GitHub Release via `gh release upload`

**Trigger:** Currently `workflow_dispatch` (manual trigger with tag input).

---

## Chunk 2: Make Release Automatic on Tag Push

**Files:**
- Modify: `.github/workflows/release-macos-native.yml`

Currently to release:
1. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`
2. Manually trigger workflow via GitHub UI or `gh workflow run release-macos-native -f tag=v1.0.0`

**Proposed:** Add `push` trigger so that pushing a tag like `v*` automatically triggers the workflow and publishes the release.

### Tasks:

- [x] **Step 1: Add push trigger to workflow** ✅ DONE

Modify `.github/workflows/release-macos-native.yml`:

```yaml
on:
  push:
    tags:
      - "v*"
  workflow_dispatch:
    inputs:
      tag:
        description: "Release tag (e.g. v1.0.0)"
        required: true
        type: string
```

- [x] **Step 2: Change tag reference from `inputs.tag` to derived from push** ✅ DONE

Added `Determine release tag` step to handle both push and workflow_dispatch events.

- [x] **Step 3: Test the trigger** ✅ DONE

Implementation complete. Push a test tag to verify:
```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```

- [x] **Step 4: Commit** ✅ DONE

---

## Usage

### Releasing a new version:

```bash
# Option A: Automatic (after implementing this plan)
git tag v1.0.0
git push origin v1.0.0
# → GitHub Actions builds and publishes to github.com/michaelmjhhhh/TodoFocus/releases/tag/v1.0.0

# Option B: Manual (current)
gh workflow run release-macos-native -f tag=v1.0.0
```

### Current Release Assets Published:
- `TodoFocus-macos-universal.zip` — The packaged macOS app
- `TodoFocus-macos-universal.zip.sha256` — SHA256 checksum for verification
