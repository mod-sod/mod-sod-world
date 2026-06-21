-- mod-sod-world: Jornah, the Horde supply officer -- the mirror of Elaine Compton
-- (sod_world_elaine_compton.sql) for the Horde. A quest giver (the shared
-- "A Full Shipment" turn-ins) and a vendor, driven by the sod-world gossip
-- ScriptName 'npc_sod_world_supply_officer'. Rune engraving lives on the dedicated
-- Rune Engraver NPC (mod-rune-engraving 700000), not the supply officers.
--
-- Real SoD ids are reused where free in 3.3.5a (verified against the live DB +
-- on-disk DBCs): creature 214070 (Jornah), faction 2587 (Durotar Supply and
-- Logistics). The faction template also uses 2587 (FactionTemplate.dbc max is 2236;
-- Faction.dbc max is 1160 -- both free).
--
-- The custom FACTION is served to the server via the core's generic `<name>_dbc`
-- override tables (DBCStores.cpp LoadFromDB merges these over the on-disk DBC at
-- startup) -- same mechanism as spell_dbc, no core edits, no server DBC files. The
-- CLIENT gets the matching Faction/FactionTemplate rows from the sod-client patch
-- (without it the tooltip won't show the faction name). A worldserver RESTART is
-- required to reload the *_dbc tables.
--
-- Appearance: stock display 4260 -- the FEMALE variant of the Orgrimmar Grunt
-- (creature 3296), a female orc in the standard Orgrimmar guard armor
-- (creature_model_info.gender = 1). Chosen so Jornah is a female orc in the guard
-- outfit without any custom display:
--   * Stock displays ship PRE-BAKED textures, so they avoid the "HD"-client crash
--     that hand-authored NpcCharacter (empty-BakeName runtime bake) displays cause.
--   * Same safe pattern Elaine uses with stock display 24292.
-- Off-hand tome = item 12743 "Monster - Item, Book - Brown Offhand" (plain neutral
-- brown book, display 23171, no glow), mirroring Elaine's supply-officer look.
--
-- Idempotent: templates / DBC-override rows use REPLACE INTO; spawn rows use
-- INSERT IGNORE (admins reposition with .npc move / .gobject move -- never clobber).
-- No DELETEs.

-- =====================================================================
-- Faction "Durotar Supply and Logistics" (faction_dbc 2587) -- a real, trackable
-- reputation faction, the Horde mirror of Azeroth Commerce Authority (2586). The
-- 3.3.5a client tracks 128 reputation slots (SMSG_INITIALIZE_FACTIONS sends
-- ReputationIndex 0-127); stock factions use 0-104 and 2586 takes 105, so 106 is
-- free. RaceMask 690 = Horde races (Orc 2 + Undead 16 + Tauren 32 + Troll 128 +
-- Blood Elf 512; Goblin is non-playable in WotLK, excluded) -- Alliance never sees
-- it, matching Jornah's Horde alignment. ClassMask 0 = all classes, Base 0 = starts
-- Neutral, Flags 16 = peace-forced (the VISIBLE bit is set by the server on the
-- first rep gain). ParentFactionID 0 = no parent, so the client buckets it under
-- the generated "Other" rep-pane header (where stock parentless factions like
-- Syndicate / Wintersaber Trainers sit) -- matching how real SoD shows these
-- supply factions. (1118 "Classic" would file it under that expansion header.)
-- Unspecified columns default to 0 (slots 2-4, parent mod/cap). The server reads
-- this via the generic faction_dbc override; the matching CLIENT Faction.dbc row
-- (with the same rep fields) ships in the sod-client patch -- without it the rep
-- pane entry will not render. A worldserver RESTART reloads faction_dbc.
-- =====================================================================
REPLACE INTO `faction_dbc`
    (`ID`, `ReputationIndex`,
     `ReputationRaceMask_1`, `ReputationClassMask_1`,
     `ReputationBase_1`, `ReputationFlags_1`,
     `ParentFactionID`, `Name_Lang_enUS`, `Name_Lang_Mask`)
VALUES
    (2587, 106,
     690, 0,
     0, 16,
     0, 'Durotar Supply and Logistics', 16712190);

-- FactionTemplate 2587 -> Faction 2587. Reactions mirror Orgrimmar (the reverse of
-- Elaine's Stormwind clone): FactionGroup 4 (Horde), FriendGroup 4 (Horde),
-- EnemyGroup 2 (Alliance), Friend_1 = self. => friendly/blue to Horde, hostile/red
-- to Alliance.
REPLACE INTO `factiontemplate_dbc`
    (`ID`, `Faction`, `Flags`, `FactionGroup`, `FriendGroup`, `EnemyGroup`,
     `Enemies_1`, `Enemies_2`, `Enemies_3`, `Enemies_4`,
     `Friend_1`, `Friend_2`, `Friend_3`, `Friend_4`)
VALUES
    (2587, 2587, 0, 4, 4, 2,
     0, 0, 0, 0,
     2587, 0, 0, 0);

-- =====================================================================
-- Jornah (creature 214070). Level 30 humanoid, gossip + quest giver + vendor,
-- neutral to attack (non-attackable) but Horde-aligned via faction 2587. Gossip is
-- the sod-world supply-officer menu (ScriptName 'npc_sod_world_supply_officer'):
-- "What do you have for sale?" + the shared "A Full Shipment" turn-ins.
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `flags_extra`,
     `ScriptName`)
VALUES
    (214070, 'Jornah', 'Supply Officer',
     30, 30, 2587, 131,      -- npcflag 131 = GOSSIP(1) | QUESTGIVER(2) | VENDOR(128)
     1.0, 1.14286,
     1, 2, 0, 7, 2,          -- unit_class warrior, NON_ATTACKABLE, humanoid, CIVILIAN
     'npc_sod_world_supply_officer');

-- Stock display 4260 (the female Orgrimmar Grunt variant of creature 3296) -- a
-- female orc in the standard guard armor. Its bounding/gender come from the stock
-- creature_model_info, so no override needed.
REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (214070, 0, 4260, 1.0, 1.0);

-- Off-hand tome (ItemID2 = 12743 plain brown book, no glow), mirroring Elaine.
-- Main-hand/ranged empty. Spawn uses equipment_id 1.
REPLACE INTO `creature_equip_template`
    (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
    (214070, 1, 0, 12743, 0);

-- Finalized placement in Orgrimmar (map 1, Valley of Strength). Coords baked from
-- the live in-game position after .npc move. INSERT IGNORE: re-applying never
-- overwrites a later in-game .npc move; it only seeds a fresh DB. NO npc_vendor
-- rows yet (empty shop).
INSERT IGNORE INTO `creature`
    (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `MovementType`)
VALUES
    (8820002, 214070, 1, 0, 0, 1, 1,
     1, 1677.4825, -4405.1753, 19.879587, 3.1023214,
     300, 0, 0);
