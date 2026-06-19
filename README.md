# mod-sod-world

Shared, class-agnostic **Season of Discovery** world content for AzerothCore
(WotLK 3.3.5a). Where `mod-sod-mage` (and future class modules) add *spells and
runes*, this module owns the **encounters and world objects** those modules build
on — defined once here so every class module can reuse them without duplication.

> **Just want to play?** The [**SoD installer**](https://github.com/mod-sod/sod-installer)
> installs this module (and the class content that uses it) in one command, and
> builds the client patches. The manual steps below are for building from source.

## What's in it

**The Awakened Lich (Raven Hill, Duskwood).** A faithful reproduction of the SoD
rune-acquisition encounter:

1. Loot the **Dusty Coffer** in the north-eastern Raven Hill crypt → a **Decrepit
   Phylactery**.
2. *Use* the phylactery next to the **Slumbering Bones** — a seated skeleton
   wasting away on a broken stone throne in the western crypt → it summons a level
   25 elite **Awakened Lich**. The phylactery is not consumed (reusable).
3. Kill the Lich → it drops each installed class's rune notes.

The Lich is the shared piece: it carries **no loot of its own**. Each class
module hangs its own `creature_loot_template` row off it (Entry `212261`), so a
character only ever sees its own class's notes. See
[Adding class loot](docs/adding-class-loot.md).

## How it couples to class modules (data only)

- **Loot:** a class module adds `creature_loot_template (Entry=212261, Item=<its notes>)`
  plus a Mage/Warrior/... `conditions` row. No C++ linkage.
- **Client item icons:** this module's custom items declare a
  `tools/client_items.json` manifest. The standalone
  [`sod-client`](https://github.com/mod-sod/sod-client) pipeline aggregates every
  module's manifests (and spell specs) into one patch MPQ (WoW replaces whole DBCs
  per archive, so custom rows must live in a single file). See
  [Client patch](docs/client-patch.md).

## IDs

Templates that exist in SoD use the **real SoD id** (greppable to wowhead, and so
modules never negotiate bands): Awakened Lich `212261`, Dusty Coffer `411348`,
Decrepit Phylactery `210568`. IDs with no SoD counterpart are custom:

| Kind | Allocation |
|------|------------|
| Custom gameobjects (no SoD id) | `701000`–`701099` (Broken Stone Throne `701000`, Slumbering Bones `701001`) |
| Gameobject spawn guids | `8821000`+ (Coffer, Throne, Skeleton) |
| Custom `ItemDisplayInfo` ids | `99000`+ (Phylactery icon `99000`) |

The only creature is the Awakened Lich (real SoD id `212261`, summon-only — no
spawn), so the custom-creature band is currently unused.

## Install

1. Clone into `modules/` alongside the core, build the server with
   `-DMODULES=static` (the module compiles into `worldserver`).
2. Apply `data/sql/db-world/base/*.sql` to `acore_world`.
3. Build the client patch from a [`sod-client`](https://github.com/mod-sod/sod-client)
   checkout: `python build_patch.py --server <ac root> --client <wow>` (needs
   `pympq`). Rebuild whenever any module's `client_items.json` changes.
4. Configure via `conf/mod_sod_world.conf.dist` (`SodWorld.Enable`, despawn
   timer, summon range).

> **Spawn coordinates** in the base SQL are placeholders — capture the real Raven
> Hill crypt positions in-game with `.gps` and replace them.

## Contributing

Adding a creature, gameobject, or world item? Start from a skeleton in
[`templates/`](templates/README.md) — copy it into place and fill the blanks. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

GPL-2.0 (see [LICENSE](LICENSE)), matching AzerothCore.
