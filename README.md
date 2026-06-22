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

**Supply officers — a capital-city rep network.** Six `<Supply Officer>` NPCs, one
in each capital, run the supply turn-ins and a reputation-tiered vendor. Alliance
officers belong to the **Azeroth Commerce Authority**, Horde to **Durotar Supply and
Logistics** — mirror reputation factions, one per side:

- **Alliance:** Elaine Compton (Stormwind), Marcy Baker (Darnassus), Tamelyn
  Aldridge (Ironforge).
- **Horde:** Jornah (Orgrimmar), Gishah (Undercity), Dokimi (Thunder Bluff).

Each uses a stock city-officer display — the 3.3.5a *HD* client crashes baking
hand-authored character geosets, so a custom outfit would need a pre-baked texture
rather than runtime geosets. The factions are real reputation factions shipped as
`*_dbc` overrides (server) plus a `sod-client` patch entry (client).

**"A Full Shipment" — repeatable supply turn-ins.** Hand any supply officer a
**Supply Shipment** crate for gold, XP, and reputation with your side's supply
faction (Alliance → Azeroth Commerce Authority, Horde → Durotar Supply and
Logistics). There are four crate tiers (one per SoD phase, item level 10/25/40/50),
each its own repeatable quest. Gold and XP scale to your level; reputation per
turn-in is fixed per tier (300 / 800 / 1000 / 1850). Faithful to SoD, a quest only
appears while you are carrying that tier's crate (with an `inv_crate_03` bag icon).

**Supply-officer stock is reputation-tiered.** The officers sell a shared list — so far
the bags **Small Courier Satchel** (10-slot, Friendly) and **Sturdy Courier Bag**
(12-slot, Honored), plus three Friendly equipment pieces (**Provisioner's Gloves**,
**Courier Treads**, **Hoist Strap**). As in SoD, each item stays hidden until you
reach its required standing with the city's supply faction — there is no "Requires
Friendly" tooltip; the item simply isn't offered until you qualify, then appears for
sale. Different items can sit at different tiers (Friendly, Honored, Exalted), and below
the lowest tier the officer shows no "for sale" option at all.

The crates **drop from SoD world chests** — each tier is added to the loot of the
phase-appropriate chests (e.g. P1 from Battered Chest `106319`, P4 from Solid Chest
`153451`). Drop rates are admin-tunable in the config
(`SodWorld.SupplyDrop.P1Chance`…`P4Chance`, default 10/10/10/5%) and applied live on
`.reload config`. The crate drops ready to turn in — SoD's fuller "Waylaid Supplies →
Replace Supplies crafting" chain is intentionally out of scope.

**Grizzby — the Ratchet rune-notes vendor.** A goblin merchant in **Ratchet** (The
Barrens) who sells class rune-unlock notes. This module ships only Grizzby himself
(creature + spawn, the neutral Ratchet faction, a stock goblin display); each class
module stocks him with its own notes via an `npc_vendor` row — so far
[`mod-sod-mage`](../mod-sod-mage)'s **Spell Notes: Rewind Time**. With no class module
installed he's simply an empty vendor.

## How it couples to class modules (data only)

- **Loot:** a class module adds `creature_loot_template (Entry=212261, Item=<its notes>)`
  plus a Mage/Warrior/... `conditions` row. No C++ linkage.
- **Supply-vendor stock:** add one row to `sod_world_supply_vendor (item, RequiredRank)`.
  The item then sells on every supply officer, hidden until the buyer reaches that
  reputation rank with the officer's faction. No C++ linkage.
- **Plain vendor stock (Grizzby):** add an `npc_vendor (entry=211653, item=<its notes>)`
  row to stock the Ratchet vendor Grizzby. No C++ linkage.
- **Client item icons:** this module's custom items declare a
  `tools/client_items.json` manifest. The standalone
  [`sod-client`](https://github.com/mod-sod/sod-client) pipeline aggregates every
  module's manifests (and spell specs) into one patch MPQ (WoW replaces whole DBCs
  per archive, so custom rows must live in a single file). See
  [Client patch](docs/client-patch.md).

## IDs

Templates that exist in SoD use the **real SoD id** (greppable to wowhead, and so
modules never negotiate bands): Awakened Lich `212261`; supply officers Elaine
Compton `213077`, Marcy Baker `214101`, Tamelyn Aldridge `214099` (Alliance) and
Jornah `214070`, Gishah `214098`, Dokimi `214096` (Horde); Dusty Coffer `411348`,
Decrepit Phylactery `210568`, Small Courier Satchel `211382`, Sturdy Courier Bag
`211384`, supply-officer equipment Provisioner's Gloves `212588` / Courier Treads
`212589` / Hoist Strap `212590`, Supply Shipment crates
`211367` / `211839` / `217337` / `221008`, "A Full Shipment" quests `78612` /
`79103` / `80309` / `82309` (P1–P4); the Ratchet vendor Grizzby `211653` (faction 69,
stock goblin display 7099); reputation factions Azeroth Commerce Authority
`2586` (`ReputationIndex 105`, Alliance) and Durotar Supply and Logistics `2587`
(`ReputationIndex 106`, Horde). IDs with no SoD counterpart are custom:

| Kind | Allocation |
|------|------------|
| Custom gameobjects (no SoD id) | `701000`–`701099` (Throne `701000`, Bones `701001`) |
| Supply-vendor tier lists (in-memory, not creatures) | `700060`–`700067` (one per reputation rank) |
| Custom `CreatureDisplayInfo` / `…Extra` | `700000`+ (reserved; officers use stock displays) |
| Custom `ItemDisplayInfo` ids | `99000`+ (Phylactery `99000`, Courier Satchel `99001`, Sturdy Bag `99002`) |
| Creature spawn guids | `8820000`+ (six supply officers `8820001`–`8820006`, Grizzby `8820007`) |
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
