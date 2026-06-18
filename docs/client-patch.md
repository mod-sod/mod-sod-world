# The consolidated client item patch

## Why one patch

The 3.3.5a client resolves a bag item's icon from `Item.dbc` (itemId →
DisplayInfoID → `ItemDisplayInfo` → icon). A custom item with no `Item.dbc` row
shows the red "?" icon in bags (vendor and loot frames are unaffected — those
packets carry the displayid directly).

WoW MPQ patches replace a DBC file **wholesale** — there is no row-level merge
across archives. So if two modules each shipped their own `Item.dbc` patch, the
higher-priority MPQ would win and the other module's items would revert to "?".
Therefore every SoD module's custom item rows must live in **one** `Item.dbc`.

`mod-sod-world` owns that consolidation. `mod-sod-mage` patches only `Spell.dbc`
(a different file, `patch-enus-z.mpq`), so the two patches coexist.

## The contract: per-module manifests

Each content module ships data files under its `tools/`:

`client_items.json` — one row per custom item:

```json
[
  { "id": 211514, "name": "Spell Notes: Mass Regeneration",
    "class": 15, "subclass": 0, "material": 1,
    "display": 1102, "invtype": 0, "sheath": 0 }
]
```

`client_displays.json` (optional) — custom `ItemDisplayInfo` rows, for an item
whose SoD icon has no existing 3.3.5a item display:

```json
[
  { "id": 99000, "name": "Decrepit Phylactery",
    "icon": "Spell_Shadow_DevouringPlague" }
]
```

Keep these mirrored with your `item_template` rows (`class`/`subclass`/`material`/
`display` must match). `display` is a 3.3.5a `ItemDisplayInfo` id — reuse an
existing one whose icon matches, or define a new one in `client_displays.json`
(pick an id in this module's `99000`+ band and confirm it's free).

## Building

```bash
python tools/build_sod_world_patch.py [--client DIR] [--dry-run]
```

It globs `../mod-sod-*/tools/client_items.json` and `client_displays.json`,
aggregates them (warning on id conflicts), rebuilds `Item.dbc` /
`ItemDisplayInfo.dbc` from the clean client base, and packs `patch-enus-y.mpq`.
Needs `pympq` (StormLib).

> Regenerate **both** patches together when items change: this one
> (`patch-enus-y.mpq`, items) and `mod-sod-mage`'s (`patch-enus-z.mpq`, spells). A
> stale spell patch never carries `Item.dbc`, so it won't fight this one — but a
> stale copy of *this* patch would, so always rebuild after editing any manifest.
