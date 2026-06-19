# Template — new NPC / enemy

## Files

- **`creature.sql`** — the full set in one file: `creature_template`,
  `creature_template_model`, a spawn row, a loot row, and a SmartAI script. Model:
  [sod_world_lich_encounter.sql](../../data/sql/db-world/base/sod_world_lich_encounter.sql).
- **`creature_script.cpp`** — optional `CreatureAI`, only when SmartAI's vocabulary
  isn't enough.

## SmartAI vs CreatureScript

**Prefer SmartAI** (the data-driven `smart_scripts` rows in `creature.sql`) for most
behavior — casts, movement, phases, timers. It needs no rebuild. Reach for a
`CreatureScript` only when the event/action vocabulary can't express what you need.

## Notes

- A **summon-only** NPC (like the Awakened Lich) has **no spawn row** — it's summoned
  by an item/spell script. Drop the `creature` INSERT if so.
- Spawns use **`INSERT IGNORE`** with **no preceding DELETE**, so re-applying never
  overwrites a position someone adjusted in-game (`.npc move`). The coords only seed a
  fresh DB — capture real positions with `.gps`.
- A creature's `lootid` (often = its entry) is what `creature_loot_template` rows hang
  off. Class modules attach their own loot to a **shared** creature — see
  [docs/adding-class-loot.md](../../docs/adding-class-loot.md).
- `CreatureDisplayID` must exist in the client; reuse a real one (find it on Wowhead
  Classic) and scale with `DisplayScale`.
