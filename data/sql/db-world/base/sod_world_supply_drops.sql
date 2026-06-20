-- mod-sod-world: Supply Shipment crates drop from SoD world chests.
--
-- This is the acquisition half of the "A Full Shipment" turn-in (see
-- sod_world_supply_shipments.sql): each tier's Supply Shipment crate is added to
-- the loot of the SoD-appropriate world chests, so a player can loot one and turn
-- it in to Elaine. (We deliberately skip SoD's "Waylaid Supplies -> Replace
-- Supplies crafting" chain -- the crate drops ready to hand in.)
--
-- The requested chests are all gameobject_template.type 3 (CHEST); their loot
-- table id is `Data1`, resolved against gameobject_loot_template. Several requested
-- chests SHARE one large stock "world-chest" loot pool, so there is one loot row
-- per distinct loot table, carrying the phase's crate:
--
--   Loot table | Crate (phase) | Chest entries fed by that table
--   -----------+---------------+--------------------------------------------------
--   2279       | 211367 (P1)   | 106319            (+ 2847)
--   2280       | 211839 (P2)   | 2849, 111095
--   2281       | 211839 (P2)   | 2850, 3715        (+ 3714, 184619-184622)
--   2284       | 217337 (P3)   | 2857, 105581
--   9931       | 221008 (P4)   | 153451
--   5278       | 221008 (P4)   | 4149
--
-- These are SHARED stock loot tables, so the crate also drops from the few extra
-- chest entries in parentheses and from every world spawn of these generic chest
-- types -- broad by design (accepted trade-off vs cloning 588-909-row loot tables).
-- The SoD object 404352 "Artifact Storage" is not present in 3.3.5a, so P1 uses
-- only Battered Chest 106319.
--
-- The `Chance` values below are the SEED defaults (P1/P2/P3 10%, P4 5%). At runtime
-- they are the configurable knobs SodWorld.SupplyDrop.P{1..4}Chance: the module's
-- WorldScript (world_sod_world_supply_drops) overwrites these Chance values from
-- the .conf on every startup and `.reload config` (and forces 0 when
-- SodWorld.Enable = 0). Edit the .conf, not this file, to retune.
--
-- QuestRequired 0 + GroupId 0 = an independent roll for any player who opens the
-- chest. Idempotent: REPLACE INTO (PK is Entry+Item, so only our rows are touched).
-- No DELETEs, no stock rows modified.

REPLACE INTO `gameobject_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
     `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (2279, 211367, 0, 10, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P1 (Battered Chest 106319)'),
    (2280, 211839, 0, 10, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P2 (chests 2849, 111095)'),
    (2281, 211839, 0, 10, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P2 (chests 2850, 3715)'),
    (2284, 217337, 0, 10, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P3 (chests 2857, 105581)'),
    (9931, 221008, 0, 5, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P4 (Solid Chest 153451)'),
    (5278, 221008, 0, 5, 0, 1, 0, 1, 1, 'mod-sod-world Supply Shipment P4 (Solid Chest 4149)');
