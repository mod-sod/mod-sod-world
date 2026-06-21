-- mod-sod-world: supply-officer vendor stock + per-item reputation tiers.
--
-- The six supply officers sell a shared, reputation-gated list. Real SoD HIDES an item
-- until you reach its required standing with the city's supply faction (no "Requires
-- Friendly" tooltip -- the item simply isn't offered), and different items sit at
-- different tiers (Friendly / Honored / Exalted).
--
-- We do NOT gate with vendor `conditions` (6 rows per item, one per officer -- scales
-- badly and can't share a tier across officers) nor item_template rep fields (single
-- faction; can't cover a shared cross-faction item). Instead the gate is a VENDOR
-- REDIRECT done in C++ (src/player_sod_world_supply_vendor.cpp + world_sod_world_supply_vendor.cpp):
--   * This table is the SOURCE OF TRUTH: one row per item = (item, minimum rep RANK).
--     The faction is NOT stored -- it's derived from the officer you talk to (Alliance
--     officers -> Azeroth Commerce Authority 2586, Horde -> Durotar Supply and Logistics
--     2587), so one rank-only row gates the item for BOTH sides.
--   * At startup a WorldScript reads this table and builds cumulative per-rank vendor
--     lists IN MEMORY (store entries 700060+rank, ranks 0..7): an item with RequiredRank
--     R is added to every tier R..7. Nothing is written to `npc_vendor`.
--   * When a player opens an officer, a PlayerScript redirects the merchant list to the
--     tier entry matching the player's rank with that officer's faction -- so the list
--     (and the buy, which keys off the same redirect) shows exactly the items they
--     qualify for. Below the lowest tier the list is empty and the officer shows no
--     vendor option at all.
--
-- ==> To add an item to every officer, add ONE row here: (item, RequiredRank). Other
-- modules add their stock the same way. RequiredRank uses the ReputationRank enum:
--   0 = ungated (Hated..Neutral all see it)   4 = Friendly    6 = Revered
--   (1 Hostile, 2 Unfriendly, 3 Neutral)       5 = Honored     7 = Exalted
-- Adding a row needs a worldserver restart (the in-memory lists build at startup).
--
-- Items so far (all values sourced from wago ItemSparse + the wowhead tooltip CDN; no
-- item carries a tooltip rep requirement -- the gate is the tier system below).
--
-- Bags (class 1, plain neutral, custom icon-only ItemDisplayInfo):
--   * Small Courier Satchel 211382 -- Friendly. subclass 0 (Bag), InvType 18, 10 slots,
--     ItemLevel 15, quality 1 (white), Unique, BoP, icon inv_misc_bag_05,
--     BuyPrice 4500 (45s) / SellPrice 800 (8s), displayid 99001.
--   * Sturdy Courier Bag 211384 -- Honored. 12 slots, ItemLevel 25, quality 2 (green),
--     Unique, BoP, icon inv_misc_bag_07_black, BuyPrice 21500 / SellPrice 3600,
--     displayid 99002.
--
-- Equipment (class 4, quality 2 green, BoP, ItemLevel 17, RequiredLevel 12, all Friendly):
--   * Provisioner's Gloves 212588 -- Hands, Cloth. 20 armor, +3 Sta +3 Spi, dura 20,
--     BuyPrice 1259 / SellPrice 251, displayid 25885 (Mystic's Gloves model).
--   * Courier Treads     212589 -- Feet,  Leather. 50 armor, +4 Agi, dura 35,
--     BuyPrice 2104 / SellPrice 420, displayid 16981 (Bandit Boots model).
--   * Hoist Strap        212590 -- Waist, Mail. 85 armor, +2 Str +2 Sta, dura 25,
--     BuyPrice 2428 / SellPrice 205, displayid 7563 (Cinched Belt model).
--
-- DISPLAYS: SoD ids don't exist in the 3.3.5a client, so each needs a client Item.dbc
-- row (tools/client_items.json) pointing at a displayid the client DOES have. The bags
-- use CUSTOM icon-only ItemDisplayInfo (99001/99002, in client_displays.json). The
-- equipment instead REUSES stock 3.3.5a displays (verified present in the on-disk
-- ItemDisplayInfo.dbc, with the right slot model + icon, and used by stock items): the
-- SoD displayids diverged from 3.3.5a, so they can't be reused directly. Item displays
-- are client-only -> no server `*_dbc` override row for either kind.
--
-- Idempotent: REPLACE INTO throughout. No DELETEs.

-- =====================================================================
-- The bags. class 1 = Container, subclass 0 = Bag, InventoryType 18 = Bag. Plain
-- neutral items; the rep gate is the tier system below, not item flags or rep fields.
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
     ''),
    (211384, 1, 0, 'Sturdy Courier Bag', 99002, 2, 0,
     1, 21500, 3600, 18,
     -1, -1, 25, 0,
     1, 1, 12, 1, 0, 0,
     '');

-- =====================================================================
-- The equipment. class 4 = Armor; subclass 1 Cloth / 2 Leather / 3 Mail. Stats use the
-- ITEM_MOD enum (3 Agi, 4 Str, 6 Spi, 7 Sta). displayid reuses a stock 3.3.5a display
-- (Material/sheath taken from that display's stock item). Neutral; gated by tier below.
-- =====================================================================
REPLACE INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`,
     `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `bonding`, `Material`, `sheath`, `armor`,
     `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`,
     `MaxDurability`, `description`)
VALUES
    (212588, 4, 1, 'Provisioner''s Gloves', 25885, 2, 0,
     1, 1259, 251, 10,
     -1, -1, 17, 12,
     0, 1, 1, 7, 0, 20,
     7, 3, 6, 3,
     20, ''),
    (212589, 4, 2, 'Courier Treads', 16981, 2, 0,
     1, 2104, 420, 8,
     -1, -1, 17, 12,
     0, 1, 1, 8, 0, 50,
     3, 4, 0, 0,
     35, ''),
    (212590, 4, 3, 'Hoist Strap', 7563, 2, 0,
     1, 2428, 205, 6,
     -1, -1, 17, 12,
     0, 1, 1, 5, 0, 85,
     4, 2, 7, 2,
     25, '');

-- =====================================================================
-- Source-of-truth table: supply-officer items + the minimum reputation RANK to buy.
-- The WorldScript world_sod_world_supply_vendor reads this at startup and builds the
-- cumulative in-memory tier lists. Faction is derived from the officer, not stored here.
-- =====================================================================
CREATE TABLE IF NOT EXISTS `sod_world_supply_vendor`
(
    `item`         INT UNSIGNED     NOT NULL,
    `RequiredRank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`item`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
    COMMENT 'mod-sod-world: supply-officer vendor items + min reputation rank (faction derived from the officer)';

-- item -> minimum rank with the officer's supply faction (4 = Friendly, 5 = Honored).
REPLACE INTO `sod_world_supply_vendor` (`item`, `RequiredRank`)
VALUES
    (211382, 4),   -- Small Courier Satchel
    (211384, 5),   -- Sturdy Courier Bag
    (212588, 4),   -- Provisioner's Gloves
    (212589, 4),   -- Courier Treads
    (212590, 4);   -- Hoist Strap
