# Task 113 — Start the App

## Goal

> "Start app."

## What was done

Launched the mathdot app from the project directory:

```powershell
& "i:\mathdot\tools\godot\Godot_v4.6.3-stable_win64.exe" --path "i:\mathdot\app"
```

The app started and is running:

- **Window title:** `mathdot (DEBUG)` (PID 39608)
- **Responding:** yes (after the REDUCE engine finished booting)

It opens with the current state of the app from the recent tasks: the
MATLAB-look UI (Courier New font, bold top buttons), the `notebooks_sample`
workspace, and — from tasks 110/111 — the **`✎ Show Source`** toggle on the
notebook view (also reachable via **Ctrl+E** or by double-clicking a cell).

No code or files were changed — this task only launches the app (per the
"do not make changes unless asked" rule added in task 112).

## Files changed
- None.
