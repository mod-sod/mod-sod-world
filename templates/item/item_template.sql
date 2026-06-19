-- TEMPLATE — copy into data/sql/db-world/base/sod_world_<name>.sql, fill the
-- placeholders. Not applied from templates/. Idempotent: scoped DELETE before INSERT.
-- Model: the Decrepit Phylactery row in sod_world_lich_encounter.sql.
--
-- A "use" item carries a harmless ON_USE spell (spellid_1 55884, spelltrigger_1 0) so
-- the client offers "Use"; the ItemScript suppresses it. Drop both for a plain quest
-- item. ScriptName binds the C++ ItemScript (or '' for none).

DELETE FROM `item_template` WHERE `entry` = <ITEM_ID>;

INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`,
     `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `bonding`, `Material`, `sheath`,
     `spellid_1`, `spelltrigger_1`, `ScriptName`, `description`)
VALUES
    (<ITEM_ID>, 12, 0, '<Item Name>', <DISPLAY_ID>, 2, 0,
     1, 0, 0, 0,
     -1, -1, <ILVL>, <REQ_LEVEL>,
     1, 1, 1, 1, 0,
     55884, 0, '<SCRIPT_NAME_OR_EMPTY>', '<Tooltip description.>');
--   class 12 = Quest item (0 = Consumable, 15 = Miscellaneous). AllowableClass -1 =
--   any class. Quality 2 = Uncommon. bonding 1 = BoP.
