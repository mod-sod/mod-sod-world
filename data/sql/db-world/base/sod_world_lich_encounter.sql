-- mod-sod-world: the shared Season of Discovery "Awakened Lich" encounter in
-- Raven Hill (Duskwood). This is class-agnostic world content: the encounter is
-- defined ONCE here, and each class module (mod-sod-mage, a future
-- mod-sod-warrior, ...) hangs its own rune-notes loot row off the Lich
-- (creature_loot_template Entry = 212261) plus its own rune + unlock mapping.
--
-- Chain (faithful to SoD):
--   1. Loot the Dusty Coffer (411348) in the NE Raven Hill crypt -> Decrepit
--      Phylactery (210568).
--   2. Use the phylactery near the Slumbering Bones (gameobject 701001) -- a
--      seated-skeleton prop wasting away on the Broken Stone Throne (gameobject
--      701000) in the W Raven Hill crypt -> summons the level 25 elite Awakened
--      Lich (212261). The phylactery is NOT consumed (reusable). Summon logic =
--      the mod-sod-world ItemScript 'item_sod_world_phylactery'.
--   3. The Lich drops each installed class's "Spell Notes: ..." (class modules).
--
-- IDs: templates that exist in SoD use the REAL SoD id (item 210568, gameobject
-- 411348, creature 212261) so modules coordinate with no band negotiation. The
-- throne and skeleton are pure decoration with no SoD analogue, so they use
-- mod-sod-world custom gameobject ids (701000 throne, 701001 skeleton); the
-- skeleton is the phylactery's summon anchor. Spawn guids are per-server:
-- gameobjects 8821000+ (creatures 8820000+ if ever needed).
--
-- Sourced values (wago.tools wow_classic_era 1.15.8.67156):
--   210568 Decrepit Phylactery: Common, BoP, Unique, ilvl/req 1,
--     desc "A heinous aura eminates from the artifact." (SoD verbatim);
--     SoD icon spell_shadow_devouringplague -> custom client displayid 99000
--     (ItemDisplayInfo row shipped in the sod-client consolidated patch, from
--     tools/client_displays.json).
--
-- The Dusty Coffer spawn is at its captured Raven Hill position. The throne and
-- skeleton spawns start near the captured Bones location; fine-tune them in-game
-- (`.gobject move`) so the skeleton sits on the throne, then re-bake the coords.
-- Idempotent and safe to re-run.

-- =====================================================================
-- Decrepit Phylactery (item 210568). class 15/subclass 0 (Misc). AllowableClass
-- -1 (any class summons the Lich). spell 55884 is a harmless existing use-spell,
-- present only so the client offers "Use"; the ItemScript suppresses it.
-- =====================================================================
REPLACE INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`,
     `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `bonding`, `Material`, `sheath`,
     `spellid_1`, `spelltrigger_1`, `ScriptName`, `description`)
VALUES
    (210568, 15, 0, 'Decrepit Phylactery', 99000, 1, 0,
     1, 0, 0, 0,
     -1, -1, 1, 1,
     1, 1, 1, 0, 0,
     55884, 0, 'item_sod_world_phylactery',
     'A heinous aura eminates from the artifact.');

-- =====================================================================
-- Dusty Coffer (gameobject 411348). type 3 = CHEST: Data0 = lockId, Data1 = lootId
-- (-> gameobject_loot_template), Data3 = consumable (1: despawns on loot and
-- respawns via spawntimesecs). lockId 43 is the canonical "free-open" chest lock
-- (no key/skill; used by hundreds of supply-crate/simple chests) -- a type-3 chest
-- with lockId 0 and non-quest loot is NOT clickable for normal players, so it must
-- carry a lock. displayId 10 is a 3.3.5a coffer/chest model.
-- =====================================================================
REPLACE INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `size`,
     `Data0`, `Data1`, `Data2`, `Data3`)
VALUES
    (411348, 3, 10, 'Dusty Coffer', 1.0,
     43, 411348, 0, 1);

REPLACE INTO `gameobject_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (411348, 210568, 0, 100, 0, 1, 0, 1, 1, 'mod-sod-world Dusty Coffer -> Decrepit Phylactery');

-- Spawn seed (Raven Hill crypt, Duskwood/map 0). INSERT IGNORE: re-applying never
-- overwrites a position adjusted in-game (.gobject move/turn) -- it only seeds a
-- fresh DB. Update these coords only to change what a fresh install gets.
INSERT IGNORE INTO `gameobject`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `rotation0`, `rotation1`, `rotation2`, `rotation3`,
     `spawntimesecs`, `animprogress`, `state`)
VALUES
    (8821001, 411348, 0, 0, 0, 1, 1,
     -10272.3, 129.001, 4.68861, 1.73373,
     0, 0, -0.762305, -0.647218,
     300, 100, 1);

-- =====================================================================
-- The Slumbering Bones are a lifeless prop: a seated-skeleton gameobject (701001,
-- display 7308 "Sitting Skeleton 01") wasting away on a Broken Stone Throne
-- gameobject (701000, display 5592). The throne display is a PLACEHOLDER -- the
-- original SoD Karazhan-style throne (9478) is not in the 3.3.5a server DBC, so a
-- valid stand-in is used.
--
-- The throne is GAMEOBJECT_TYPE_GENERIC (5) scenery. The skeleton is
-- GAMEOBJECT_TYPE_GOOBER (10) so it is hoverable, shows its "Slumbering Bones" name
-- tooltip (a generic/doodad GO shows none), and is clickable -- its ScriptName
-- (go_sod_world_slumbering_bones) makes a click summon the Lich for a phylactery
-- holder. The phylactery used nearby is the other trigger; both anchor the summon
-- on the skeleton (FindNearestGameObject 701001 for the item path).
--
-- NOTE: a GO displayId MUST exist in the server's GameObjectDisplayInfo.dbc or the
-- spawn is rejected at load ("invalid displayId ... not loaded" in Errors.log).
-- Valid stone-throne alternatives: 5592, 2810, 2087, 2088, 8238, 8283, 8323, 660, 7744.
-- =====================================================================
-- The bones carry the ScriptName 'go_sod_world_slumbering_bones': clicking them
-- summons the Lich too (a second, more intuitive trigger), but only for a player
-- carrying the Decrepit Phylactery -- so the phylactery is still the real key.
REPLACE INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `size`, `ScriptName`)
VALUES
    (701000, 5, 5592, 'Broken Stone Throne', 1.0, ''),
    (701001, 10, 7308, 'Slumbering Bones', 1.0, 'go_sod_world_slumbering_bones');

-- Spawn seed near the captured Bones location. INSERT IGNORE: re-applying never
-- overwrites in-game position/rotation (.gobject move/turn); it only seeds a fresh
-- DB. throne 8821002, skeleton 8821003.
INSERT IGNORE INTO `gameobject`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `rotation0`, `rotation1`, `rotation2`, `rotation3`,
     `spawntimesecs`, `animprogress`, `state`)
VALUES
    (8821002, 701000, 0, 0, 0, 1, 1,
     -10400.2, 342.648, 24.8345, 1.32,
     0, 0, -0.613117, -0.789992,
     300, 0, 1),
    (8821003, 701001, 0, 0, 0, 1, 1,
     -10400.2, 342.648, 25.3, 1.32,
     0, 0, -0.613117, -0.789992,
     300, 0, 1);

-- =====================================================================
-- Awakened Lich (creature 212261, real SoD id). Level 25 elite Undead caster,
-- hostile (faction 14). Summon-only: NO `creature` spawn row. lootid = 212261 so
-- class modules' creature_loot_template rows (Entry = 212261) drop; this module
-- adds NO loot rows itself. display 17444 (3.3.5a Lich) at 0.5 scale -- the model
-- is natively boss-sized (Rage Winterchill uses it at 1.0), so scale it down for a
-- level 25 elite.
--
-- SoD flavor "casts Banish" maps to no player-targetable 3.3.5a spell (Banish,
-- 710, only hits Demon/Elemental), so the Lich casts Shadow Bolt (9613) for a
-- functional necromantic fight. SmartAI below.
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`, `rank`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `lootid`,
     `AIName`, `MovementType`,
     `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`)
VALUES
    (212261, 'Awakened Lich', '',
     25, 25, 14, 0,
     1.0, 1.14286, 1,
     8, 0, 0, 6, 212261,
     'SmartAI', 0,
     6, 1, 1, 1, 0);

REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (212261, 0, 17444, 0.5, 1.0);

-- SmartAI: in combat, cast Shadow Bolt (9613) on the current victim every 3-4.5s.
-- event_type 0 = UPDATE_IC, action_type 11 = CAST, target_type 2 = VICTIM.
-- Single row (id 0); REPLACE keys on the full PK, so if this script ever grows to
-- multiple rows and later shrinks, remove the retired id(s) by hand (REPLACE alone
-- won't purge them).
REPLACE INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `target_type`, `comment`)
VALUES
    (212261, 0, 0, 0,
     0, 0, 100, 0,
     3000, 4500, 3000, 4500,
     11, 9613, 0, 0,
     2, 'Awakened Lich - In Combat - Cast Shadow Bolt on victim');
