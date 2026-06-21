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
-- First item: Small Courier Satchel 211382, a SoD Phase 1 10-slot bag, at Friendly (4).
-- Sourced from Wowhead (item=211382): class 1 / subclass 0 (Bag), InventoryType 18,
-- 10 container slots, ItemLevel 15, quality 1 (white), Unique (maxcount 1), BoP
-- (bonding 1), icon inv_misc_bag_05, BuyPrice 4500 (45s), SellPrice 800 (8s). A plain
-- neutral bag -- no tooltip requirement (matches real SoD). displayid 99001 is a custom
-- ItemDisplayInfo (inv_misc_bag_05) shipped in the sod-client patch.
--
-- Idempotent: REPLACE INTO throughout. No DELETEs.

-- =====================================================================
-- Small Courier Satchel (item 211382). class 1 = Container, subclass 0 = Bag,
-- InventoryType 18 = Bag, ContainerSlots 10. Plain neutral bag; the rep gate is the
-- tier system below, not item flags or item_template rep fields.
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

-- Small Courier Satchel -> Friendly (rank 4) with the officer's supply faction.
REPLACE INTO `sod_world_supply_vendor` (`item`, `RequiredRank`)
VALUES
    (211382, 4);
