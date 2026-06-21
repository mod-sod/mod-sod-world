-- mod-sod-world: the supply officers' vendor catalog.
--
-- Items sold by the supply officers (Elaine Compton 213077, Jornah 214070). The
-- officers carry the VENDOR npcflag; their gossip (npc_sod_world_supply_officer)
-- surfaces a "What do you have for sale?" option. Other modules may add their own
-- npc_vendor rows for these officers -- this file is just sod-world's own stock.
--
-- First item: Small Courier Satchel (211382), a SoD Phase 1 10-slot bag.
-- Sourced from Wowhead (item=211382): class 1 / subclass 0 (Bag), InventoryType 18,
-- 10 container slots, ItemLevel 15, quality 1 (white), Unique (maxcount 1), BoP
-- (bonding 1), icon inv_misc_bag_05, BuyPrice 4500 (45s), SellPrice 800 (8s).
-- Holes (not in the sourced data): RequiredLevel -> 0, Material -> 0 (cosmetic),
-- Flags -> 0 (Wowhead flags2 not portable; BoP/Unique come from bonding/maxcount).
-- displayid 99001 is a custom ItemDisplayInfo (icon inv_misc_bag_05) built into the
-- sod-client patch (tools/client_items.json + client_displays.json).
--
-- Idempotent: REPLACE INTO throughout. No DELETEs.

-- =====================================================================
-- Small Courier Satchel (item 211382). class 1 = Container, subclass 0 = Bag,
-- InventoryType 18 = Bag, ContainerSlots 10. The client reads ContainerSlots /
-- quality / price from this item_template via the item query; the client Item.dbc
-- row (sod-client patch) only carries class/subclass/display/invtype.
-- =====================================================================
REPLACE INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`,
     `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `ContainerSlots`, `bonding`, `Material`, `sheath`,
     `description`)
VALUES
    (211382, 1, 0, 'Small Courier Satchel', 99001, 1, 0,
     1, 4500, 800, 18,
     -1, -1, 15, 0,
     1, 1, 10, 1, 0, 0,
     '');

-- =====================================================================
-- Sold by both supply officers for gold at the item's BuyPrice (ExtendedCost 0).
-- maxcount 0 = unlimited stock, incrtime 0 = no restock timer.
-- =====================================================================
REPLACE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
VALUES
    (213077, 0, 211382, 0, 0, 0),
    (214070, 0, 211382, 0, 0, 0);
