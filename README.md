# reQuest — WarioWare-style Micro-Quest Game (Godot 4)

Medieval punk micro-quests. 10 tasks. ~10 seconds each. Then **Long Rest**.

## Pitch
Inspired by WarioWare's cadence + medieval woodcut (Baker-era ink, graffiti, distressed print) mixed with modern grit. You **hit Start → quest (10 micro-tasks back-to-back) → Long Rest (camp)** where you can save/exit safely, choose the next path, and spend gold on upgrades.

## How to run
- Requires **Godot 4.2+** (tested 4.7, `gl_compatibility` for Mac).
- Open `reQuest/` as Godot project → F5. Or:
  ```sh
  godot --path reQuest
  ```

## Gameplay loop — `scripts/GameManager.gd:1`
```
StartMenu ──► Quest (10 tasks) ──► LongRest ──┐
   ▲                                         │
   └─────────────────────────────────────────┘
   Save & Exit only safe at StartMenu / LongRest
```
- `TASKS_PER_QUEST = 10` (`GameManager.gd:15`)
- Each task is its **own scene** (`scenes/tasks/*.tscn`) with a `command_text` ("HAMMER THE ANVIL!", "DODGE!", etc.)
- Timer defaults to `10s / difficulty` + upgrade bonus, clamped 3–12s (`GameManager.gd:58`). Per-task override via `@export var task_time`.
- Gold: `5 + upgrades + time_bonus` on win; lives `-1` on fail (3 lives, game over → wipe to menu).
- Difficulty ramps `+0.12` per quest, modified by path choice at Long Rest.

## Project structure
```
reQuest/
  project.godot          # autoloads: SaveManager → GameManager → TaskManager
  assets/icon.svg        # shield/Q woodcut icon
  scenes/
    StartMenu.tscn       # Begin Quest / Continue / Wipe / Save & Exit
    LongRest.tscn        # Camp — save, picks path (Forest/Crypt/Tower), buys upgrades
    TaskBase.tscn        # Base HUD: CommandLabel, QuestProgress, GoldLabel, TimerBar, ResultLabel
    tasks/
      MashTask.tscn      # [mash]  HAMMER THE ANVIL! — mash F/X
      DodgeTask.tscn     # [move]  DODGE! — WASD survive barrels
      ParryTask.tscn     # [timing] PARRY! — space in gold zone
      SortTask.tscn      # [click] GRAB THE LOOT! — click coins
      LockpickTask.tscn  # [rotate] PICK IT! — A/D find sweet spot + SPACE
      ArcherTask.tscn    # [aim]   LOOSE! — mouse/WASD aim + shoot
      StirTask.tscn      # [circle] STIR THE STEW! — circular WASD/drag
      SealTask.tscn      # [drag]  SEAL IT! — drag stamp to letter
      ChantTask.tscn     # [memory] CHANT! — Simon WASD/Arrows sequence
      BalanceTask.tscn   # [balance] DON'T SPILL! — tilt tray A/D
  scripts/
    GameManager.gd       # quest state, gold/lives, difficulty, upgrades
    SaveManager.gd       # user://request_save.json (only at Long Rest / exit)
    TaskManager.gd       # shuffles task_pool (10) → queue of 10, instantiates next
    tasks/
      TaskBase.gd        # class_name TaskBase — timer, succeed()/fail(), signals
      MashTask.gd etc. (10 tasks)
```

## Inputs — `project.godot:25`
- `move_left/right/up/down` — WASD + Arrows + D-pad
- `action` — Space / E / A-button
- `mash` — F / X-button
All tasks use these; add new actions in `project.godot` → map in your task's `_unhandled_input`.

## Creating a new micro-task
1. Duplicate `scenes/TaskBase.tscn` → `scenes/tasks/MyTask.tscn`.
2. Create `scripts/tasks/MyTask.gd`:
   ```gdscript
   extends TaskBase
   func _ready():
       command_text = "DO THE THING!"
       super._ready()
   func on_task_start():
       # spawn your nodes
       pass
   func on_task_tick(delta: float):
       # per-frame logic; call succeed() or fail() when decided
       pass
   ```
3. Register it in `TaskManager.gd:9` → `task_pool` array.
4. Keep it under ~10s; call `succeed()` for win, `fail()` or let timer run out for loss.

`task_time` export lets you extend/shorten per design ("This game will ... have a standard 10 second play time that could be extended or shortened." — prompt spec).

## Art — Baker aesthetic
Reference: https://www.fuckyoubaker.com/ (ink, woodcut, distressed print, high-contrast medieval punk + modern graffiti). Current palette is placeholder code-colors approximating that; replace with Baker textures:
- **Ink:** `#1a1208` on **parchment** `#f2e8c6` — rough paper + grain overlay (see `StartMenu.tscn:Grain`)
- **Rust/iron** `#8c2f12` + **gold** `#ffd94c` for hits
- **Woodcut borders:** thick strokes, halftone dots, hand-drawn imperfections
- Type: condensed blackletter/woodtype for `CommandLabel`, clean mono for HUD
- Swap `ColorRect` placeholders with `Sprite2D` + Baker scans; keep same anchors so HUD doesn't shift.

## Save / Exit
- `SaveManager.gd:8` writes `user://request_save.json` only at Long Rest, Start exit, or buying upgrades — never mid-quest (prevents scumming).
- "Save and exit safely" is Long Rest's contract; Start Menu's Exit also saves.
- Wipe via StartMenu button calls `GameManager.reset_progress()`.

## Roadmap
- [ ] SFX: woodblock hit + fuse tick; screen shake on mash
- [ ] Interstitial "NEXT: <task>" card between tasks (0.5s)
- [ ] More tasks: drag-reorder, hold, shake, mic blow (stretch goals)
- [ ] Juice: Baker halftone shader for TimerBar
- [ ] Controller rumble + touch friendliness

## License
Placeholder — add before Baker art reuse (Baker's work is not CC; get permission or use as *inspiration*, not direct rips).
