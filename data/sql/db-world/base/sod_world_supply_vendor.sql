-- mod-sod-world: the supply officers' shared vendor catalog.
--
-- All supply officers sell the SAME list. Rather than repeat every item on every
-- officer, the items live ONCE under a shared "reference" entry (700050) and each
-- officer carries a single reference row: a negative `item` in npc_vendor means
-- "also sell everything entry 700050 sells" (core: ObjectMgr::LoadReferenceVendor).
-- ==> To add an item to every officer, add ONE row to the 700050 catalog below.
--
-- 700050 is a reference id, not a real NPC; the dummy creature_template below just
-- gives it the VENDOR flag so the catalog rows pass IsVendorItemValid without an
-- error (the officers resolve the reference either way). Other modules can stock the
-- officers too -- either add their item to the 700050 catalog, or add their own
-- per-officer npc_vendor rows.
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
-- Reference-list holder (entry 700050) -- NOT spawned. A minimal VENDOR-flagged
-- template so the catalog rows below load cleanly. faction 35 is incidental.
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `unit_class`, `type`)
VALUES
    (700050, 'Supply Vendor Catalog', 'shared reference list (never spawned)',
     1, 1, 35, 128, 1, 7);

-- A display is required even for a never-spawned template (else a load warning);
-- 24292 is incidental.
REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (700050, 0, 24292, 1.0, 1.0);

-- =====================================================================
-- The shared catalog (entry 700050). Add items HERE -- every officer that
-- references 700050 sells them. Gold at the item's BuyPrice (ExtendedCost 0),
-- unlimited stock (maxcount 0), no restock timer (incrtime 0).
-- =====================================================================
REPLACE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
VALUES
    (700050, 0, 211382, 0, 0, 0);   -- Small Courier Satchel

-- =====================================================================
-- Each officer references the shared catalog (negative item = reference to 700050).
-- These rows are fixed -- new items go in the catalog above, not here. Officers:
-- Elaine 213077, Jornah 214070, Marcy 214101, Tamelyn 214099, Gishah 214098,
-- Dokimi 214096.
-- =====================================================================
REPLACE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
VALUES
    (213077, 0, -700050, 0, 0, 0),
    (214070, 0, -700050, 0, 0, 0),
    (214101, 0, -700050, 0, 0, 0),
    (214099, 0, -700050, 0, 0, 0),
    (214098, 0, -700050, 0, 0, 0),
    (214096, 0, -700050, 0, 0, 0);
