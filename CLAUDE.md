# Symbolic Math Workbench — Claude Code Guidelines

## Git & GitHub

**Do NOT push to GitHub unless explicitly requested by the user.** Commit work locally, but always ask for confirmation or wait for an explicit "update github" instruction before pushing.

When the user says "do task X", complete the implementation + doc, then stop. Do not automatically run `git push`.

## Task Workflow

Each task produces:
1. Implementation (code changes)
2. One `.md` documentation file explaining the task
3. A single git commit with a clear message
4. **No GitHub push** unless user explicitly requests it

After completing a task, report what was done and wait for next instructions.

## Project Structure

- `app/` — Godot 4.6.3 project root
  - `scripts/` — GDScript files (notebook_view.gd, main.gd, color_config.gd, looks_config.gd, etc.)
  - `notebooks_sample/` — Sample .md notebook files for testing
  - `scenes/` — Godot scene files
- `tools/` — REDUCE CAS + Godot binaries (not committed)
- `app_screenshot_*.png` — Task screenshots
- `task##_*.md` — Task documentation files

## Technical Notes

- **REDUCE subprocess**: Uses OS.execute_with_pipe with sentinel-correlated reader thread
- **Notebooks**: Markdown-based with `cas`, `cas-plot`, `cas-derive`, `cas-test` code blocks
- **Persistence**: ConfigFile-based (user://font.cfg, color.cfg, style.cfg, packages.cfg)
- **UI**: Godot Control nodes, IconMenuBar, PopupMenu, RichTextLabel
- **Tasks 68–69**: Beautification (8 of 53 items from task 64 catalogue) + toolbar restructuring

## Recent Releases

- **v1.0.0**: Initial release (tasks 1–67)
- **v1.1.0**: Beautification + toolbar (tasks 68–69)
- Current: Task 72 (integrate e^(x²)·log(1+x³) — no GitHub push yet)
