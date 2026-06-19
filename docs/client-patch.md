# Custom item icons & the client patch

## Why a patch is needed

The 3.3.5a client resolves a bag item's icon from `Item.dbc` (itemId →
DisplayInfoID → `ItemDisplayInfo` → icon). A custom item with no `Item.dbc` row
shows the red "?" icon in bags (vendor and loot frames are unaffected — those
packets carry the displayid directly).

WoW MPQ patches replace a DBC file **wholesale** — there is no row-level merge
across archives. So if two modules each shipped their own `Item.dbc`, the
higher-priority MPQ would win and the other module's items would revert to "?".
Every SoD module's custom rows must live in **one** set of DBCs.

## Who owns it

The standalone [`sod-client`](https://github.com/mod-sod/sod-client) repo owns the
consolidation of **all** client DBCs — items *and* spells — into one patch. This
module (like every content module) contributes **data only**; it builds nothing
itself.

## The contract: per-module manifests

This module ships data files under `tools/`:

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

From a `sod-client` checkout (needs `pympq`, client closed):

```bash
python build_patch.py --server "<azerothcore root>" --client "<WoW client root>"
```

It globs every `mod-sod-*/tools/` for these manifests (and spell specs), rebuilds
the DBCs from the clean client base, and packs the one `patch-z` (both archive
chains). Re-run after editing any manifest. The
[SoD installer](https://github.com/mod-sod/sod-installer) runs it for you. See
`sod-client`'s
[architecture doc](https://github.com/mod-sod/sod-client/blob/main/docs/architecture.md)
for the full contract.
