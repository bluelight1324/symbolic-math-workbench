# Task 112 — "Do Not Make Changes Unless Asked" Rule

## Goal

> "Do not make changes unless asked to. Add to CLAUDE.md."

Codify a working rule so future sessions don't make unsolicited changes.

## What was added

A new **"Scope of Changes"** section at the top of
[CLAUDE.md](CLAUDE.md) (the project guidelines that are loaded into every
session):

> **Do NOT make changes unless explicitly asked to.** Only modify code, files,
> or configuration that the current task explicitly requests. When a task asks a
> question ("why is X…", "will X…", "is X…"), answer it and write the doc — do
> **not** change code. When a task asks to investigate or explain, investigate
> and explain — do not "fix" things that weren't asked about. If you believe an
> additional change would help, propose it and wait for the user to ask, rather
> than making it pre-emptively.

## Why

Recent tasks made the distinction concrete:

- **Task 109** ("*Why* is the notebook not editable?") — correctly answered with
  a doc and **no** code change.
- **Tasks 110 / 111** ("*How can you improve* …") — explicitly asked for
  improvements, so changes were appropriate.

The rule makes that boundary explicit: questions and investigations get answers;
only change-requests get changes. Anything extra is proposed, not applied.

## Placement

It's the **first** section of `CLAUDE.md` (above Git & GitHub), since it governs
whether to act at all — it's checked before any other workflow rule.

## Files changed
- `CLAUDE.md` — added the "Scope of Changes" section.
