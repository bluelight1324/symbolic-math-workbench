# Task 22 — Where Is the Toolbar with All the Godot Functionality?

Short answer: **there isn't one, and there never was one — in the *deployed
app*.** The Symbolic Math Workbench has its own toolbars (the menu bar and
the action-button rows); none of them have ever been a "Godot toolbar."
"Godot" is the engine the app is built on, not a feature surfaced in the
UI. So if a Godot-branded toolbar feels like it's missing, two things may
be going on. This doc covers both.

This is a companion to [task 21](task21_where_is_godot.md), which mapped
where Godot lives inside the codebase (everywhere, just unbranded).

---

## 1. The likely confusion: editor vs. app

Godot comes in two distinct executables, with different UIs. Mixing them up
is a very common source of "where did the toolbar go?":

| Mode                     | What it is                                                | UI you see                                                                 |
|--------------------------|-----------------------------------------------------------|----------------------------------------------------------------------------|
| **Godot Editor**         | An IDE for editing Godot projects                          | A full IDE: Scene panel, FileSystem panel, Inspector, Output, plus a **toolbar at the very top** with Scene / Project / Debug / Editor / Help menus and the green "Play" button. |
| **Deployed app** (what we ship to users) | The compiled / runtime view of one specific project | Only the project's own UI — in our case the menu bar + buttons we built ourselves. The editor's toolbar **doesn't exist here**; it's part of the IDE, not the runtime. |

If you launch the Godot binary like this:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe'
```

— with **no arguments** — you get the Godot **Editor** (the IDE). It has
its top toolbar with the menus listed above.

If you launch with `--path` pointing at our project:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --path 'i:\readtgodot\app'
```

— Godot acts as a **runtime**, loads `project.godot`, opens
`scenes/main.tscn`, and shows our app — and *only* our app's UI. The
editor's Scene / Project / Debug / Editor / Help toolbar is **not** present
because we're not in the editor.

> If you ever want the editor's UI back: launch the Godot binary with no
> arguments, or pass `-e` / `--editor`. That toolbar is the Godot
> *application's* toolbar, never the *user-facing* toolbar of an app made
> with Godot.

---

## 2. The toolbars that *are* in the deployed app

The app ships with three distinct toolbar-style surfaces. None of them are
labelled "Godot" because Godot is the engine, not a feature.

### 2.1 The menu bar (top of the window, both views)

[main.gd `_build_menubar()`](app/scripts/main.gd) builds it. It contains:

```
View | Algebra | Calculus | Equations | ODEs | Matrices | Series | Trig | Numbers | Plots | Help
```

- **View** — window-size controls (Maximize, Toggle Fullscreen, Compact /
  Default / Large / Full HD), plus **Open Notebook view…** (F2). Built
  in task 11.2.
- **Algebra … Plots** — the 72-problem catalogue from task 11.
- **Help** — Open Tour (F1), which launches the multi-step wizard from
  task 12.

This is your main "toolbar" in the calculator view.

### 2.2 The operation-button row (calculator view)

Just under the header in the calculator view:

```
[ input field ]  [Simplify] [Factor] [d/dx] [∫ dx] [Solve] [Solve ODE] [Plot]
```

These are the *active* buttons that operate on whatever's in the input
field. Built in [main.gd `_build_ui()`](app/scripts/main.gd). They were
enlarged in task 9, and the **Solve ODE** entry was added in task 8.

There's also a header row with the title + a "Reset session" button (task
9) and an action keypad along the bottom (`7 8 9 ^ ( ) pi sqrt( df(`).

### 2.3 The action bar (notebook view)

When you press **F2** or pick **View → Open Notebook view…**, you get the
notebook view ([task 19](task19_p0_p2_implementation.md)). Its top toolbar
([notebook_view.gd `_build_ui()`](app/scripts/notebook_view.gd)) is:

```
Workspace: <path>                [Open workspace…] [New note] [Save (Ctrl+S)] [Run notebook (F5)] [Export HTML]
```

Plus the same menu bar above it (still present — the notebook view is an
overlay, not a replacement) and the editor / sidebar layout below.

---

## 3. Why no "Godot toolbar" in the deployed app

A few reasons it would actively make things worse:

1. **It's the engine, not a feature.** "Godot toolbar" would be like asking
   for a "Linux toolbar" in a Linux app — the OS isn't a feature of the
   app, it's the substrate. Same here. See
   [task 21](task21_where_is_godot.md) for where Godot actually shows up
   (every UI element, the threading, the IPC, the file system, etc.).
2. **Task 9** explicitly removed all user-visible Godot mentions. Re-adding
   a "Godot toolbar" would undo that rebrand.
3. **The Godot Editor's toolbar (Scene / Project / Debug / Editor / Help)
   has no useful function inside a shipped app.** Those menus exist to
   edit, debug, and build the project — concerns belonging to the
   developer, not the end user.

If a developer wants those tools, they launch the Godot Editor directly:

```powershell
# Open the project in the Godot editor (with its full toolbar):
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --editor --path 'i:\readtgodot\app'
```

That opens the IDE *on this project*. The Scene tree, FileSystem dock,
Output panel, and the IDE's own top toolbar are all present there — and
none of it leaks into the user-facing app.

---

## 4. Quick "did I lose something?" checklist

If something in the deployed app feels missing, this is where to find it:

| What you might be looking for                  | Where it is now                                                                                |
|------------------------------------------------|------------------------------------------------------------------------------------------------|
| Algebra / calculus / ODE preset problems        | Menu bar → respective category (task 11)                                                       |
| Switch views (calculator ↔ notebook)            | Menu bar → View → Open Notebook view…  (or **F2**) (task 19)                                   |
| Resize window / fullscreen                      | Menu bar → View → Maximize / Toggle Fullscreen / Compact / Default / Large / Full HD (task 11.2) |
| Differentiate / integrate / factor / solve / ODE | Operation-button row in the calculator view (tasks 1, 6–8)                                     |
| Plot a function                                 | **Plot** button on the operation row (task 7)                                                  |
| Tour of all features                            | Menu bar → Help → Open Tour  (or **F1**) (task 12)                                             |
| Reset variable bindings / engine state          | "Reset session" button in the header (tasks 4 / 6)                                             |
| Open / save / run / export notebooks            | Notebook view's action bar (Open workspace, New note, Save (Ctrl+S), Run (F5), Export HTML) (task 19) |
| Numeric / symbolic keypad                       | Keypad row at the bottom of the calculator view (tasks 6 / 9)                                  |
| Scene panel, Inspector, FileSystem, debugger    | Only in the **Godot Editor** — launch it with `--editor --path app` (developer-only)            |

If you mean a specific feature that *used to be in the toolbar* and isn't
anymore: nothing has been removed since task 14 (last UI-changing task
before the requirements/roadmap docs). The menu bar gained the **View**
menu in task 11.2, and the notebook action bar was added new in task 19;
nothing was deleted.

---

## TL;DR

- There is no "Godot toolbar" in the deployed app and there never was.
- "Godot" is the engine, not a feature — see
  [task 21](task21_where_is_godot.md) for where it lives in the code.
- The deployed app's toolbars are the **menu bar** at the top (View +
  9 problem categories + Help), the **operation-button row** under the
  input field in the calculator view, and the **action bar** at the top
  of the notebook view.
- If you want the Godot **Editor**'s toolbar (Scene/Project/Debug/Editor/
  Help + Play button), launch Godot in editor mode with `--editor` — that's
  a developer tool for the project, distinct from the user-facing app.
