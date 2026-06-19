# Template — world item

Quest items, keys, and "use" items (like the Decrepit Phylactery). Same icon rule as
any custom item: the bag icon comes from the client's `Item.dbc`, so the item needs a
manifest entry.

## Files

- **`item_template.sql`** — the item row. Model: the Phylactery rows in
  [sod_world_lich_encounter.sql](../../data/sql/db-world/base/sod_world_lich_encounter.sql).
- **`client_items.json`** — one manifest object, added to
  [tools/client_items.json](../../tools/client_items.json) (or your module's own).
- **`client_displays.json`** — *optional*: only when the SoD icon you want has **no**
  existing 3.3.5a `ItemDisplayInfo`. Defines a custom display in the `99000+` band.
  Model: [tools/client_displays.json](../../tools/client_displays.json).
- **`item_script.cpp`** — optional `ItemScript` for a "use" item (summon, key, etc.).
  Model: [src/item_sod_world_phylactery.cpp](../../src/item_sod_world_phylactery.cpp).

## Notes

- **Reuse a real `displayid`** whose icon matches before defining a custom one — find
  it by its `InventoryIcon` in `ItemDisplayInfo.dbc` / on Wowhead Classic.
- The manifest's `class` / `subclass` / `material` / `display` must mirror the
  `item_template` row.
- This module **owns the consolidated client patch**. After editing any manifest,
  rebuild it: `python tools/build_sod_world_patch.py` (client closed). See
  [docs/client-patch.md](../../docs/client-patch.md).
