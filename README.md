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
   wasting away on a broken stone throne in the western crypt — **or click the bones
   directly while carrying the phylactery** → it summons an elite **Awakened Lich**
   (level 25 by default; set `SodWorld.AwakenedLich.Level`). The phylactery is not
   consumed (reusable).
3. Kill the Lich → it drops each installed class's rune notes.

The Lich is the shared piece: it carries **no loot of its own**. Each class
module hangs its own `creature_loot_template` row off it (Entry `212261`), so a
character only ever sees its own class's notes. See
[Adding class loot](docs/adding-class-loot.md).

**Elaine Compton — the shared supply / debug NPC.** A Level 30 Human Female
`<Supply Officer>` of the **Azeroth Commerce Authority** (a friendly Alliance
faction), standing in Stormwind's Trade District. She is the
shared, class-agnostic front-end for the rune-engraving debug menu — she reuses
`mod-rune-engraving`'s `npc_rune_engraver` gossip — and is flagged as a vendor
(she'll stock SoD goods later; nothing yet). She replaces the engine's old
placeholder "Rune Engraver". Her **faction** is a real reputation faction shipped
as `*_dbc` overrides (server) + a `sod-client` patch entry (client). Her **look**
uses a stock human-female officer display — the 3.3.5a *HD* client crashes baking
hand-authored character geosets, so an exact custom blue outfit would need a
pre-baked texture rather than runtime geosets.

**"A Full Shipment" — repeatable supply turn-ins.** Hand Elaine a **Supply
Shipment** crate for gold, XP, and Azeroth Commerce Authority reputation. There
are four crate tiers (one per SoD phase, item level 10/25/40/50), each its own
repeatable quest. Gold and XP scale to your level; reputation per turn-in is fixed
per tier (300 / 800 / 1000 / 1850). Faithful to SoD, a quest only appears while
you are actually carrying that tier's crate (with an `inv_crate_03` bag icon).

The crates **drop from SoD world chests** — each tier is added to the loot of the
phase-appropriate chests (e.g. P1 from Battered Chest `106319`, P4 from Solid Chest
`153451`). Drop rates are admin-tunable in the config
(`SodWorld.SupplyDrop.P1Chance`…`P4Chance`, default 10/10/10/5%) and applied live on
`.reload config`. The crate drops ready to turn in — SoD's fuller "Waylaid Supplies →
Replace Supplies crafting" chain is intentionally out of scope.

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
modules never negotiate bands): Awakened Lich `212261`, Elaine Compton `213077`,
Dusty Coffer `411348`, Decrepit Phylactery `210568`, Supply Shipment crates
`211367` / `211839` / `217337` / `221008`, "A Full Shipment" quests `78612` /
`79103` / `80309` / `82309` (P1–P4), faction Azeroth Commerce Authority `2586`
(a reputation faction, `ReputationIndex 105`). IDs with no SoD counterpart are
custom:

| Kind | Allocation |
|------|------------|
| Custom gameobjects (no SoD id) | `701000`–`701099` (Throne `701000`, Bones `701001`) |
| Custom `CreatureDisplayInfo` / `…Extra` | `700000`+ (reserved; Elaine uses a stock display) |
| Custom `ItemDisplayInfo` ids | `99000`+ (Phylactery icon `99000`) |
| Creature spawn guids | `8820000`+ (Elaine `8820001`) |
| Gameobject spawn guids | `8821000`+ (Coffer/Throne/Skeleton) |

Custom creature displays and factions are delivered as core `*_dbc` override rows
(server) plus `sod-client` patch rows (client) — see
[Client patch](docs/client-patch.md).

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
