# Template — new gameobject

Chests, props, and interactive doodads. Most are pure data — no C++.

## File

- **`gameobject.sql`** — `gameobject_template`, an optional loot table, and a spawn
  row. Model:
  [sod_world_lich_encounter.sql](../../data/sql/db-world/base/sod_world_lich_encounter.sql)
  (the Dusty Coffer chest + the Slumbering Bones / throne props).

## Common types

- **Chest** (`type 3`) — openable, holds loot. Needs a **lockId** (set `Data0`); a
  type-3 chest with `lockId 0` and non-quest loot is **not clickable** by normal
  players. `lockId 43` is a common free-open lock.
- **Generic** (`type 5`) — scenery; no interaction, no tooltip.
- **Goober** (`type 10`) — hoverable, shows its name tooltip; a clickable prop.

## Notes

- **No client patch needed.** A GO's `displayId` must already exist in the server's
  `GameObjectDisplayInfo.dbc` — reuse a real one (find it on Wowhead Classic). An
  invalid displayId makes the spawn fail to load ("invalid displayId" in `Errors.log`).
- Spawns use **`INSERT IGNORE`** with **no preceding DELETE**, so re-applying never
  overwrites an in-game placement (`.gobject move/turn`). Capture position **and the
  rotation quaternion** in-game; the coords only seed a fresh DB.
- A custom GO id comes from the `701000–701099` band; spawn guids from `8821000+`.
