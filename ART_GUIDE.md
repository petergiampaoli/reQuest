# reQuest — Art Guide (Baker-inspired)

Source: https://www.fuckyoubaker.com/ — study directly for line quality, texture, attitude.

## Core traits to steal (not trace)
- **Ink on cheap paper:** bleed, rough edges, mis-registration. Scan real ink then threshold.
- **Woodcut medieval:** knights, shields, beasts, but with modern tags, chrome, bubble letters.
- **Distressed palette:** off-white paper, deep black ink, single accent (rust red or acid yellow), occasional gold foil.
- **Hand-made imperfection:** wobble, halftone dots, overspray, visible grain.

## In-game mapping
| Element | Current placeholder | Baker target |
|---|---|---|
| BG | ColorRect `#1a1208` | Scanned parchment paper, tiled + grain shader |
| CommandLabel | Gold text + black outline | Blackletter woodtype, slightly skewed, ink bleed |
| TimerBar | green→gold→red ProgressBar | Fuse / wick burning down, halftone fill |
| Player / Anvil / Barrels | ColorRect blocks | Linocut sprites, thick outlines, limited palette |
| Gold coins | Button "◉" | Woodcut coin with Baker-style face, gold foil effect |

## Constraints
- Keep HUD anchors fixed (QuestProgress top-left, Gold top-right, Timer bottom-center, Command top-center) — never move between tasks.
- All tasks share same `CanvasLayer` z; unique gameplay nodes live under root Node2D, not inside CanvasLayer.
- Export textures as `.png` with power-of-two size, import filter OFF (preserve hard ink).

## Doing it without infringing
- Baker's pieces are copyrighted. Use as *reference* for style; create original linocuts or scan your own ink.
- Credit "Medieval punk, inspired by Baker" — don't reuse Baker's lettering 1:1.
