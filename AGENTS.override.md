# codex-notes Repository Contract

The global [AGENTS.md](AGENTS.md) supplies common behavior. If it is already in context, do not read it again; otherwise read it once. This project override prevents injecting that same global source twice.

- When changing `AGENTS.md`, update [docs/AGENTS.ko.md](docs/AGENTS.ko.md) in the same change. Preserve priority, conditions, exceptions, and required actions; review both diffs and report semantic synchronization. Section lengths may differ.
- For changes to `.harness/`, its router, or Diagnostics, read [Harness maintenance](.harness/maintenance.md) before editing.
- For skill or installation changes, read [installation and checks](README.md#skill-자동-발견). Follow the installed skill's resolver when it references the central Harness.
- After instruction, skill, or Harness changes, run `./scripts/doctor.sh`. For Diagnostics, installation, or Harness contract changes, also run `./scripts/test-doctor-harness.sh`; for pairing or hook changes, run `sh scripts/test-doc-sync.sh`. A failed required check blocks completion as verified; report failures and unverified environments.
- For an independent review of context changes, use [the review prompt](docs/context-review-prompt.md). Read-only reviews must not create repository artifacts unless requested.
