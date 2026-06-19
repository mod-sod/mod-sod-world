-- TEMPLATE — copy into data/sql/db-world/base/sod_world_<name>.sql, fill the
-- placeholders, keep what you need. Not applied from templates/. Idempotent for the
-- template/model/AI (scoped DELETE before INSERT); the spawn uses INSERT IGNORE so it
-- never clobbers an in-game placement. Model: sod_world_lich_encounter.sql.

-- =====================================================================
-- Creature template + display. Reuse a real SoD npc id when one exists; else use the
-- mod-sod-world custom band. lootid = entry so the loot row below drops.
-- =====================================================================
DELETE FROM `smart_scripts` WHERE `entryorguid` = <NPC_ID> AND `source_type` = 0;
DELETE FROM `creature_template_model` WHERE `CreatureID` = <NPC_ID>;
DELETE FROM `creature_template` WHERE `entry` = <NPC_ID>;

INSERT INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`, `rank`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `lootid`,
     `AIName`, `MovementType`,
     `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`)
VALUES
    (<NPC_ID>, '<Name>', '<subname or empty>',
     <MINLEVEL>, <MAXLEVEL>, <FACTION>, 0,
     1.0, 1.14286, <RANK>,
     <UNIT_CLASS>, 0, 0, <TYPE>, <NPC_ID>,
     'SmartAI', 0,
     1, 1, 1, 1, 0);
--   faction 14 = hostile monster. rank 0 = normal, 1 = elite. unit_class 1 warrior,
--   2 paladin, 4 rogue, 8 mage. type 6 = Undead, 7 = Humanoid, ... lootid = entry.

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (<NPC_ID>, 0, <DISPLAY_ID>, 1.0, 1.0);

-- =====================================================================
-- Loot (optional). Scope the DELETE to YOUR item + this entry. Add a class-gate
-- `conditions` row (see templates/item) if only one class should roll it.
-- =====================================================================
DELETE FROM `creature_loot_template` WHERE `Item` = <ITEM_ID> AND `Entry` = <NPC_ID>;
INSERT INTO `creature_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (<NPC_ID>, <ITEM_ID>, 0, <CHANCE>, 0, 1, 0, 1, 1, 'mod-sod-world <name>');

-- =====================================================================
-- SmartAI: in combat, cast <SPELL_ID> on the victim every 3-4.5s.
-- event_type 0 = UPDATE_IC, action_type 11 = CAST, target_type 2 = VICTIM.
-- Prefer SmartAI over a C++ script. See the AzerothCore SmartAI wiki.
-- =====================================================================
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `target_type`, `comment`)
VALUES
    (<NPC_ID>, 0, 0, 0,
     0, 0, 100, 0,
     3000, 4500, 3000, 4500,
     11, <SPELL_ID>, 0, 0,
     2, '<Name> - In Combat - Cast <Spell> on victim');

-- =====================================================================
-- Spawn (optional; omit for a summon-only NPC). INSERT IGNORE: never overwrites an
-- in-game move. guid from the spawn-guid band; capture coords with .gps.
-- =====================================================================
INSERT IGNORE INTO `creature`
    (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `MovementType`)
VALUES
    (<SPAWN_GUID>, <NPC_ID>, <MAP>, 0, 0, 1, 1,
     <X>, <Y>, <Z>, <O>,
     300, 0);
