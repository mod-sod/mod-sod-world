# mod-sod-world

Shared, class-agnostic **Season of Discovery** world content for AzerothCore
3.3.5a — the encounters and world objects that class modules (`mod-sod-mage`, a
future `mod-sod-warrior`, …) build on, defined once so nothing is duplicated.

## Current content

**The Awakened Lich** (Raven Hill, Duskwood): loot the Dusty Coffer for a
Decrepit Phylactery, use it by the Slumbering Bones to summon a level 25 elite
Awakened Lich, and kill it for each installed class's rune notes. The Lich
carries no loot of its own — class modules attach theirs.

## For module authors

- **[Adding class loot](adding-class-loot.md)** — hang your class's rune-notes
  drop off the shared Lich (data only, no C++ coupling).
- **[Client patch](client-patch.md)** — how the consolidated `Item.dbc` patch
  works and the per-module `client_items.json` manifest contract.

## Install & IDs

See the repository [README](https://github.com/) for build, SQL apply, the
client-patch step, and the ID allocations. Spawn coordinates in the base SQL are
placeholders — capture the real positions in-game with `.gps`.
