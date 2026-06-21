-- mod-sod-world: the SoD supply officers and their two reputation factions.
--
-- SoD seats a "Supply Officer" in each capital: a quest giver (the "A Full Shipment"
-- turn-ins, sod_world_supply_shipments.sql) and a vendor (sod_world_supply_vendor.sql),
-- all driven by the sod-world gossip ScriptName 'npc_sod_world_supply_officer'. Rune
-- engraving lives on the engine's dedicated Rune Engraver NPC (mod-rune-engraving
-- 700000), not on these officers.
--
-- The six officers (real SoD creature ids, verified free), by faction/city:
--   Alliance -- faction 2586 (Azeroth Commerce Authority), human-female display 24292:
--     Elaine Compton   213077 -> Stormwind
--     Marcy Baker      214101 -> Darnassus
--     Tamelyn Aldridge 214099 -> Ironforge
--   Horde -- faction 2587 (Durotar Supply and Logistics), orc-female display 4260:
--     Jornah           214070 -> Orgrimmar
--     Gishah           214098 -> Undercity
--     Dokimi           214096 -> Thunder Bluff
--
-- The two FACTIONS reach the server via the core's generic `<name>_dbc` override
-- tables (DBCStores.cpp LoadFromDB merges over the on-disk DBC at startup -- same
-- mechanism as spell_dbc; no core edits, no server DBC files). The CLIENT gets the
-- matching Faction/FactionTemplate rows from the sod-client patch (without it the
-- tooltip / rep-pane name won't render). A worldserver RESTART reloads the *_dbc tables.
--
-- Displays are STOCK (no custom CreatureDisplayInfo), which avoids the "HD"-client
-- crash on hand-authored NpcCharacter (empty-BakeName runtime bake) displays -- stock
-- displays ship PRE-BAKED .blp textures. A display's apparent GENDER comes from its
-- baked texture (the owning NPC's gender), not the model, so female-NPC displays were
-- picked: 24292 ("Lisa Philbrook", a female human) for Alliance; 4260 (the FEMALE
-- variant of the Orgrimmar Grunt, creature 3296, a female orc in guard armor) for
-- Horde. Off-hand tome = item 12743 (plain brown book, display 23171, no glow).
--
-- Idempotent: templates / DBC-override rows use REPLACE INTO; spawn rows use INSERT
-- IGNORE (admins reposition with .npc move -- never clobber). No DELETEs.

-- =====================================================================
-- The two supply reputation factions. Real, trackable rep factions (the "A Full
-- Shipment" turn-ins grant rep here). ReputationIndex 105/106 (stock factions use
-- 0-104). RaceMask: 1101 = Alliance races (2586), 690 = Horde races (2587, Orc 2 +
-- Undead 16 + Tauren 32 + Troll 128 + Blood Elf 512) -- each faction is invisible to
-- the other side. ClassMask 0 = all, Base 0 = Neutral, Flags 16 = peace-forced (the
-- server sets the VISIBLE bit on first rep gain). ParentFactionID 0 -> the client
-- buckets each under its generated "Other" rep-pane header (where stock parentless
-- factions like Syndicate / Wintersaber sit), matching how real SoD shows them.
-- =====================================================================
REPLACE INTO `faction_dbc`
    (`ID`, `ReputationIndex`,
     `ReputationRaceMask_1`, `ReputationClassMask_1`,
     `ReputationBase_1`, `ReputationFlags_1`,
     `ParentFactionID`, `Name_Lang_enUS`, `Name_Lang_Mask`)
VALUES
    (2586, 105, 1101, 0, 0, 16, 0, 'Azeroth Commerce Authority', 16712190),
    (2587, 106,  690, 0, 0, 16, 0, 'Durotar Supply and Logistics', 16712190);

-- FactionTemplates. 2586 clones Stormwind (group/friend Alliance 2, enemy Horde 4);
-- 2587 mirrors Orgrimmar (group/friend Horde 4, enemy Alliance 2). Friend_1 = self =>
-- each is friendly/blue to its own faction, hostile/red to the other.
REPLACE INTO `factiontemplate_dbc`
    (`ID`, `Faction`, `Flags`, `FactionGroup`, `FriendGroup`, `EnemyGroup`,
     `Enemies_1`, `Enemies_2`, `Enemies_3`, `Enemies_4`,
     `Friend_1`, `Friend_2`, `Friend_3`, `Friend_4`)
VALUES
    (2586, 2586, 0, 2, 2, 4, 0, 0, 0, 0, 2586, 0, 0, 0),
    (2587, 2587, 0, 4, 4, 2, 0, 0, 0, 0, 2587, 0, 0, 0);

-- =====================================================================
-- The six officers. Level 30 humanoid, gossip + quest giver + vendor (npcflag 131 =
-- GOSSIP(1)|QUESTGIVER(2)|VENDOR(128)), NON_ATTACKABLE (unit_flags 2), CIVILIAN
-- (flags_extra 2), faction 2586 (Alliance) / 2587 (Horde).
-- =====================================================================
REPLACE INTO `creature_template`
    (`entry`, `name`, `subname`,
     `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`,
     `unit_class`, `unit_flags`, `unit_flags2`, `type`, `flags_extra`,
     `ScriptName`)
VALUES
    (213077, 'Elaine Compton',   'Supply Officer', 30, 30, 2586, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer'),
    (214101, 'Marcy Baker',      'Supply Officer', 30, 30, 2586, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer'),
    (214099, 'Tamelyn Aldridge', 'Supply Officer', 30, 30, 2586, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer'),
    (214070, 'Jornah',           'Supply Officer', 30, 30, 2587, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer'),
    (214098, 'Gishah',           'Supply Officer', 30, 30, 2587, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer'),
    (214096, 'Dokimi',           'Supply Officer', 30, 30, 2587, 131, 1.0, 1.14286, 1, 2, 0, 7, 2, 'npc_sod_world_supply_officer');

-- Displays: 24292 (female human) for Alliance, 4260 (female Orgrimmar Grunt) for Horde.
REPLACE INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (213077, 0, 24292, 1.0, 1.0),
    (214101, 0, 24292, 1.0, 1.0),
    (214099, 0, 24292, 1.0, 1.0),
    (214070, 0, 4260, 1.0, 1.0),
    (214098, 0, 4260, 1.0, 1.0),
    (214096, 0, 4260, 1.0, 1.0);

-- Off-hand tome (item 12743) for each; main-hand/ranged empty. Spawns use equipment_id 1.
REPLACE INTO `creature_equip_template`
    (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
    (213077, 1, 0, 12743, 0),
    (214101, 1, 0, 12743, 0),
    (214099, 1, 0, 12743, 0),
    (214070, 1, 0, 12743, 0),
    (214098, 1, 0, 12743, 0),
    (214096, 1, 0, 12743, 0);

-- =====================================================================
-- Finalized placements (coords baked from live in-game positions after .npc move).
-- INSERT IGNORE never clobbers a later in-game move; it only seeds a fresh DB. Spawn
-- guids in the 8820000+ band.
-- =====================================================================
INSERT IGNORE INTO `creature`
    (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `MovementType`)
VALUES
    (8820001, 213077, 0, 0, 0, 1, 1, 1, -8825.063,   649.7763,   94.57176,  4.7048225, 300, 0, 0), -- Stormwind
    (8820003, 214101, 1, 0, 0, 1, 1, 1,  9838.5,     2299.63,  1319.82,     1.27235,   300, 0, 0), -- Darnassus
    (8820004, 214099, 0, 0, 0, 1, 1, 1, -4925.47,    -905.377,  501.66,     5.27789,   300, 0, 0), -- Ironforge
    (8820002, 214070, 1, 0, 0, 1, 1, 1,  1677.4825, -4405.1753,  19.879587, 3.1023214, 300, 0, 0), -- Orgrimmar
    (8820005, 214098, 0, 0, 0, 1, 1, 1,  1635.27,     252.593,  -43.102,    2.74886,   300, 0, 0), -- Undercity
    (8820006, 214096, 1, 0, 0, 1, 1, 1, -1222.85,     101.869,  131.966,    4.74774,   300, 0, 0); -- Thunder Bluff
