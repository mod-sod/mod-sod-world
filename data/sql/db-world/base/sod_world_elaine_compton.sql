-- mod-sod-world: Elaine Compton, the shared class-agnostic supply/debug NPC.
-- Replaces the old placeholder "Rune Engraver" (mod-rune-engraving entry 700000,
-- a reused City Guard). Elaine keeps the SAME debug gossip by reusing the engine's
-- ScriptName 'npc_rune_engraver' (data-only coupling: mod-rune-engraving owns the
-- C++); she is also flagged as a vendor (sells nothing yet).
--
-- Real SoD ids are reused where free in 3.3.5a (verified against the live DB +
-- on-disk DBCs): creature 213077 (Elaine Compton), faction 2586 (Azeroth Commerce
-- Authority). The faction template also uses 2586 (FactionTemplate.dbc max is 2236;
-- Faction.dbc max is 1160 -- both free).
--
-- The custom FACTION is served to the server via the core's generic `<name>_dbc`
-- override tables (DBCStores.cpp LoadFromDB merges these over the on-disk DBC at
-- startup) -- same mechanism as spell_dbc, no core edits, no server DBC files. The
-- CLIENT gets the matching Faction/FactionTemplate rows from the sod-client patch
-- (without it the tooltip won't show the faction name). A worldserver RESTART is
-- required to reload the *_dbc tables.
--
-- Appearance: stock display 24292 (the female human NPC "Lisa Philbrook") -- a
-- brown-haired woman, no hat, in a shirt + blue Skyshroud leggings. Chosen for a
-- dark-brown-haired female in blue cloth.
--
-- Two HD-client gotchas drove this choice:
--   1) A hand-authored custom NpcCharacter display (empty-BakeName runtime bake)
--      CRASHES the "HD" client on render -- every stock clothed human ships a
--      PRE-BAKED .blp instead. So an exact custom outfit needs a pre-baked texture.
--   2) The human model is ALWAYS HumanFemale.mdx; a display's apparent GENDER comes
--      from its baked texture (the owning NPC's gender), not the model. A male NPC's
--      display (e.g. Horizon Scout Crewman 7608) bakes male even on the female
--      model -- so pick displays owned by FEMALE NPCs.
-- Off-hand tome = item 12743 "Monster - Item, Book - Brown Offhand" (plain neutral
-- brown book, display 23171, no glow). 3.3.5a has no purple book model; the simple
-- book textures are Brown/Blue/Black/Skull, all effect-free (Tome of Divine Right
-- 34802 was rejected for its ItemVisual=103 glow).
--
-- Idempotent: templates / DBC-override rows use REPLACE INTO; spawn rows use
-- INSERT IGNORE (admins reposition with .npc move / .gobject move -- never clobber).
-- No DELETEs.

-- =====================================================================
-- Faction "Azeroth Commerce Authority" (faction_dbc 2586). Non-reputation
-- (ReputationIndex -1): it only provides the unit-tooltip faction name. The
-- server reads all 57 columns; unspecified ones default to 0/NULL (correct for a
-- no-rep faction). The client shows this name only with the sod-client patch.
-- =====================================================================
REPLACE INTO `faction_dbc`
    (`ID`, `ReputationIndex`, `Name_Lang_enUS`, `Name_Lang_Mask`)
VALUES
    (2586, -1, 'Azeroth Commerce Authority', 16712190);

-- FactionTemplate 2586 -> Faction 2586. Reactions cloned from Stormwind (template
-- 12): FactionGroup 2 (Alliance), FriendGroup 2 (Alliance), EnemyGroup 4 (Horde),
-- Friend_1 = self. => friendly/blue to Alliance, hostile/red to Horde.
REPLACE INTO `factiontemplate_dbc`
    (`ID`, `Faction`, `Flags`, `FactionGroup`, `FriendGroup`, `EnemyGroup`,
     `Enemies_1`, `Enemies_2`, `Enemies_3`, `Enemies_4`,
     `Friend_1`, `Friend_2`, `Friend_3`, `Friend_4`)
VALUES
    (2586, 2586, 0, 2, 2, 4,
     0, 0, 0, 0,
     2586, 0, 0, 0);

-- =====================================================================
-- Elaine Compton (creature 213077). Level 30 humanoid, gossip + vendor, neutral to
-- attack (non-attackable) but Alliance-aligned via faction 2586. Gossip is the
-- engine's rune debug menu via ScriptName 'npc_rune_engraver'.
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `flags_extra`,
     `ScriptName`)
VALUES
    (213077, 'Elaine Compton', 'Supply Officer',
     30, 30, 2586, 129,      -- npcflag 129 = GOSSIP(1) | VENDOR(128)
     1.0, 1.14286,
     1, 2, 0, 7, 2,          -- unit_class warrior, NON_ATTACKABLE, humanoid, CIVILIAN
     'npc_rune_engraver');

-- Stock display 24292 ("Lisa Philbrook", a female human NPC) -- see header. Its
-- bounding/gender come from the stock creature_model_info, so no override needed.
REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (213077, 0, 24292, 1.0, 1.0);

-- Off-hand tome (ItemID2 = 12743 plain brown book, no glow). Main-hand/ranged
-- empty. Spawn uses equipment_id 1.
REPLACE INTO `creature_equip_template`
    (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
    (213077, 1, 0, 12743, 0);

-- Spawn seed at the retired engraver's spot (Stormwind Trade District). INSERT
-- IGNORE: re-applying never overwrites an in-game .npc move; it only seeds a fresh
-- DB. Tune position in-game and re-bake here. NO npc_vendor rows yet (empty shop).
INSERT IGNORE INTO `creature`
    (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `MovementType`)
VALUES
    (8820001, 213077, 0, 0, 0, 1, 1,
     1, -8825.063, 649.7763, 94.57176, 4.7048225,
     300, 0, 0);
