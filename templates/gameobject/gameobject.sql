-- TEMPLATE — copy into data/sql/db-world/base/sod_world_<name>.sql, fill the
-- placeholders, keep what you need. Not applied from templates/. Idempotent for the
-- template/loot (scoped DELETE before INSERT); the spawn uses INSERT IGNORE so it
-- never clobbers an in-game placement. Model: sod_world_lich_encounter.sql.

-- =====================================================================
-- Gameobject template. This example is a CHEST (type 3): displayId is a 3.3.5a
-- chest model; Data0 = lockId (43 = free-open), Data1 = lootId, Data3 = consumable.
-- A type-3 chest with lockId 0 + non-quest loot is NOT clickable -- give it a lock.
-- =====================================================================
DELETE FROM `gameobject_loot_template` WHERE `Entry` = <GO_ID>;
DELETE FROM `gameobject_template` WHERE `entry` = <GO_ID>;

INSERT INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `size`,
     `Data0`, `Data1`, `Data2`, `Data3`)
VALUES
    (<GO_ID>, 3, <DISPLAY_ID>, '<Name>', 1.0,
     43, <GO_ID>, 0, 1);
--   For a non-interactive prop use type 5 (generic) or type 10 (goober, hoverable):
--   INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`)
--   VALUES (<GO_ID>, 10, <DISPLAY_ID>, '<Name>', 1.0);

-- =====================================================================
-- Loot (chest only; lootId above = <GO_ID>). Drop omit for a prop with no loot.
-- =====================================================================
INSERT INTO `gameobject_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (<GO_ID>, <ITEM_ID>, 0, 100, 0, 1, 0, 1, 1, 'mod-sod-world <name>');

-- =====================================================================
-- Spawn. INSERT IGNORE: never overwrites an in-game move/turn. Capture position AND
-- the rotation quaternion (rotation0..3) in-game; guid from the 8821000+ band.
-- =====================================================================
INSERT IGNORE INTO `gameobject`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `rotation0`, `rotation1`, `rotation2`, `rotation3`,
     `spawntimesecs`, `animprogress`, `state`)
VALUES
    (<SPAWN_GUID>, <GO_ID>, <MAP>, 0, 0, 1, 1,
     <X>, <Y>, <Z>, <O>,
     <ROT0>, <ROT1>, <ROT2>, <ROT3>,
     300, 100, 1);
