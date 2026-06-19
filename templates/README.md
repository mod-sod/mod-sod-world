# Contribution templates — mod-sod-world

Copy-paste starting points for the **shared world content** this module owns:
encounters, NPCs, gameobjects, and the props/items class modules build on. Each file
is a bare-minimum skeleton with `<PLACEHOLDER>` tokens — copy it into its real
location, fill the blanks, and delete the banner comment.

These files are **never built or applied** from `templates/`. The C++ build globs
only `src/`, and the database updater only applies `.sql` under `data/sql/db-*/` — so
nothing here is sibling to those paths.

## What's here

| Folder / file | For adding | Copy into |
|---|---|---|
| `npc/` | a creature/enemy (template, spawn, loot, AI) | `data/sql/db-world/base/` + `src/` |
| `gameobject/` | a chest, prop, or interactive object | `data/sql/db-world/base/` |
| `item/` | a quest/use item with a bag icon | `data/sql/db-world/base/` + `tools/` |
| `conf_snippet.conf` | a new config tunable | `conf/mod_sod_world.conf.dist` |

Each folder has its own README with the recipe.

## ID bands

Reuse the **real SoD id** whenever the thing exists in SoD. Only invent an id when
there's no SoD analogue — then pick from a documented custom band:

| Kind | Band |
|---|---|
| Custom gameobjects | `701000–701099` |
| Custom creatures | `701000–701099` (creature space; currently unused) |
| Gameobject spawn guids | `8821000+` |
| Custom `ItemDisplayInfo` ids | `99000+` |

## Sources of truth

- **[wago.tools](https://wago.tools)** — authoritative SoD values from the modern
  Classic Era client's DB2s, as CSV (`/db2/<Table>/csv?build=<classic-era build>`).
- **[Wowhead Classic](https://www.wowhead.com/classic)** — human-readable
  cross-reference for ids, display models, and drop sources.
- **[AzerothCore wiki](https://www.azerothcore.org/wiki)** — table schemas, the
  [SmartAI reference](https://www.azerothcore.org/wiki/smart-scripts), and the
  [hooks list](https://www.azerothcore.org/wiki/hooks-script).
- This module's [docs/](../docs/Home.md) — adding class loot and the client patch.
