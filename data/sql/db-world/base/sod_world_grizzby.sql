-- mod-sod-world: Grizzby, the Ratchet goblin vendor (real SoD creature id 211653).
--
-- A plain merchant in Ratchet, The Barrens. In SoD he sells the Mage rune-unlock
-- notes "Spell Notes: Rewind Time" (item 210654). Following the module split, this
-- file owns only WHO Grizzby is and WHERE he stands; WHAT he sells is owned by the
-- buying content module -- mod-sod-mage adds the `npc_vendor` row (211653 -> 210654)
-- in sod_mage_rewind_time_unlock.sql (the same direction as the shared Lich loot:
-- class modules reference sod-world's ids, never the reverse). With mod-sod-mage
-- absent, Grizzby is simply a vendor with no stock -- a clean no-op.
--
-- Sourced (wowhead/wago + acore_world): Level 30 Humanoid, Ratchet. Faction 69 is
-- the existing neutral Ratchet/Steamwheedle faction every Ratchet vendor uses
-- (Grazlix, Jazzik, Ranik, ...). Display 7099 is a STOCK goblin-merchant model
-- (Ranik's), reused -- the HD client crashes on hand-baked custom displays, and
-- Grizzby's exact SoD model isn't 1:1 sourceable to 3.3.5a, so a stock goblin fits.
--
-- IDs: creature 211653 (real SoD), spawn guid 8820007 (sod-world creature band
-- 8820000+). Idempotent: REPLACE for templates, INSERT IGNORE for the spawn (never
-- clobber a later in-game .npc move). No DELETEs.

-- =====================================================================
-- The vendor. npcflag 128 = VENDOR (right-click opens the merchant window; stock is
-- supplied by content modules). NON_ATTACKABLE (unit_flags 2) + CIVILIAN
-- (flags_extra 2), faction 69 (Ratchet). No ScriptName -- the core drives a plain
-- npc_vendor merchant; no gossip needed.
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `flags_extra`,
     `ScriptName`)
VALUES
    (211653, 'Grizzby', NULL, 30, 30, 69, 128, 1.0, 1.14286, 1, 2, 0, 7, 2, '');

-- Stock goblin-merchant display (7099, Ranik's model).
REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (211653, 0, 7099, 1.0, 1.0);

-- =====================================================================
-- Spawn in Ratchet, The Barrens (map 1), among the merchants. zoneId/areaId 0 =
-- auto-detect. Coords are the finalized in-game placement; admins can still
-- fine-tune with .npc move (INSERT IGNORE preserves it). Spawn guid 8820007.
-- =====================================================================
INSERT IGNORE INTO `creature`
    (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `MovementType`)
VALUES
    (8820007, 211653, 1, 0, 0, 1, 1, 0, -1044.63062, -3650.60767, 23.87782, 4.53271, 300, 0, 0);
