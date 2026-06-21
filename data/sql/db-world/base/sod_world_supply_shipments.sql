-- mod-sod-world: Season of Discovery "A Full Shipment" repeatable supply turn-ins.
--
-- Four repeatable supply turn-ins (one per Supply Shipment crate tier) shared by
-- BOTH supply officers: Elaine Compton (creature 213077, Alliance) and Jornah
-- (214070, Horde) each START and END all four -- the same quests, no duplication.
--
-- AUTO-COMPLETE flow (QUEST_FLAGS_AUTOCOMPLETE, QuestType 0): talking to the officer
-- while carrying that tier's crate completes the quest in one interaction (gossip ->
-- "Do you have something for me?" request frame -> Complete) -- no accept-then-return.
-- The crate is still required and consumed (CanCompleteRepeatableQuest checks the
-- RequiredItemId; RewardQuest destroys it), and the option shows the repeatable blue
-- "!". This matches real SoD (verified in-game).
--
-- REPUTATION IS GRANTED BY TEAM IN C++ (src/player_sod_world_supply_quests.cpp), NOT
-- here: a turn-in grants the player's OWN supply faction only -- Alliance -> Azeroth
-- Commerce Authority (2586), Horde -> Durotar Supply and Logistics (2587), +300 / 800
-- / 1000 / 1850 by tier. Wowhead lists BOTH factions on the quest, but that is the raw
-- quest data; SoD filters it to the player's team -- granting rep with a faction the
-- player can never interact with is wrong. So RewardFactionID1 = 0 (no built-in rep).
--
-- Real SoD ids are reused (verified against the live DB + on-disk DBCs): the four
-- Supply Shipment items 211367 / 211839 / 217337 / 221008, and the four
-- "A Full Shipment" quests 78612 (P1) / 79103 (P2) / 80309 (P3) / 82309 (P4).
--
-- Sourced values (Wowhead quest=78612...82309): QuestLevel 9 / 25 / 40 / 50,
-- RewardMoney 600 / 3000 / 120000 / 154000 (fixed, faithful to SoD -- no scaling),
-- MinLevel 1, rep 300 / 800 / 1000 / 1850. XP is UNSOURCEABLE (Wowhead shows 80/200
-- for P1/P2 and no value for P3/P4; no reliable source) -- these read as gold-only
-- quests, so XP is forced to 0 in the C++ hook (commented there).
--
-- Authentic text (confirmed in-game): name "A Full Shipment"; request/progress
-- "Do you have something for me?"; reward "Everything's accounted for! Thank you,
-- $N. These supplies are critical for the front lines." LogDescription/
-- QuestDescription are not shown for an auto-complete quest, but are set to a clean
-- neutral line so no stale Elaine/Stormwind text lingers in the DB.
--
-- The quests are gated to appear ONLY while the player carries that tier's crate
-- (conditions: CONDITION_SOURCE_TYPE_QUEST_AVAILABLE 19 + CONDITION_ITEM 2), matching
-- SoD. Repeatable (quest_template_addon.SpecialFlags 1) and consuming one crate on
-- turn-in, each quest vanishes after completion until another crate is acquired.
--
-- The officers, their flags, and the two supply factions (2586 / 2587, real
-- trackable reputation factions so the rep rewards register and show) all live in
-- sod_world_supply_officers.sql.
--
-- Idempotent: REPLACE INTO for templates; INSERT IGNORE never used here. No DELETEs.

-- =====================================================================
-- The four Supply Shipment crates (turn-in items). class 7 = Trade Goods.
-- AllowableClass/Race -1 = any. displayid 8928 = a stock INV_Crate_03 display.
-- =====================================================================
REPLACE INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`,
     `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `bonding`, `Material`, `sheath`, `description`)
VALUES
    (211367, 7, 0, 'Supply Shipment', 8928, 2, 0,
     1, 0, 0, 0, -1, -1, 10, 1,
     0, 1, 1, 0, 0, 'Deliver to a supply officer for a substantial reward.'),
    (211839, 7, 0, 'Supply Shipment', 8928, 2, 0,
     1, 0, 0, 0, -1, -1, 25, 1,
     0, 1, 1, 0, 0, 'Deliver to a supply officer for a substantial reward.'),
    (217337, 7, 0, 'Supply Shipment', 8928, 2, 0,
     1, 0, 0, 0, -1, -1, 40, 1,
     0, 1, 1, 0, 0, 'Deliver to a supply officer for a substantial reward.'),
    (221008, 7, 0, 'Supply Shipment', 8928, 2, 0,
     1, 0, 0, 0, -1, -1, 50, 1,
     0, 1, 1, 0, 0, 'Deliver to a supply officer for a substantial reward.');

-- =====================================================================
-- The four "A Full Shipment" quests. QuestType 0 + Flags 65536 = auto-complete
-- (instant turn-in on talk). QuestLevel/RewardMoney are authentic fixed values;
-- MinLevel 1. RewardFactionID1 0 -- rep is granted by team in the C++ hook, NOT
-- here. RewardXPDifficulty 0 (the hook also forces 0 XP). RequiredItemId1 = the
-- tier's crate (count 1, consumed on turn-in). QuestSortID 0 = faction-neutral.
-- =====================================================================
REPLACE INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`,
     `SuggestedGroupNum`, `Flags`, `RewardXPDifficulty`, `RewardMoneyDifficulty`,
     `RewardMoney`, `RewardFactionID1`, `RewardFactionOverride1`,
     `RequiredItemId1`, `RequiredItemCount1`,
     `LogTitle`, `LogDescription`, `QuestDescription`)
VALUES
    (78612, 0, 9, 1, 0, 0, 0, 65536, 0, 0, 600, 0, 0, 211367, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to a supply officer.',
     'Deliver a Supply Shipment to a supply officer for a substantial reward.'),
    (79103, 0, 25, 1, 0, 0, 0, 65536, 0, 0, 3000, 0, 0, 211839, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to a supply officer.',
     'Deliver a Supply Shipment to a supply officer for a substantial reward.'),
    (80309, 0, 40, 1, 0, 0, 0, 65536, 0, 0, 120000, 0, 0, 217337, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to a supply officer.',
     'Deliver a Supply Shipment to a supply officer for a substantial reward.'),
    (82309, 0, 50, 1, 0, 0, 0, 65536, 0, 0, 154000, 0, 0, 221008, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to a supply officer.',
     'Deliver a Supply Shipment to a supply officer for a substantial reward.');

-- Request / progress text (the auto-complete frame body). Authentic SoD line.
REPLACE INTO `quest_request_items` (`ID`, `CompletionText`) VALUES
    (78612, 'Do you have something for me?'),
    (79103, 'Do you have something for me?'),
    (80309, 'Do you have something for me?'),
    (82309, 'Do you have something for me?');

-- Reward text (the completion frame). Authentic SoD line (confirmed in-game).
REPLACE INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
    (78612, 'Everything''s accounted for! Thank you, $N. These supplies are critical for the front lines.'),
    (79103, 'Everything''s accounted for! Thank you, $N. These supplies are critical for the front lines.'),
    (80309, 'Everything''s accounted for! Thank you, $N. These supplies are critical for the front lines.'),
    (82309, 'Everything''s accounted for! Thank you, $N. These supplies are critical for the front lines.');

-- Repeatable (SpecialFlags 1) + no-rep-spillover (64) = 65.
REPLACE INTO `quest_template_addon`
    (`ID`, `SpecialFlags`)
VALUES
    (78612, 65),
    (79103, 65),
    (80309, 65),
    (82309, 65);

-- Every capital-city supply officer starts AND ends every quest (Alliance: Elaine
-- 213077 Stormwind, Marcy Baker 214101 Darnassus, Tamelyn Aldridge 214099 Ironforge;
-- Horde: Jornah 214070 Orgrimmar, Gishah 214098 Undercity, Dokimi 214096 Thunder
-- Bluff). A quest may have multiple starter/ender NPCs -- the same quest, shared.
-- (The officer creatures live in sod_world_supply_officers.sql; this is just the
-- quest contract.)
REPLACE INTO `creature_queststarter` (`id`, `quest`) VALUES
    (213077, 78612), (213077, 79103), (213077, 80309), (213077, 82309),
    (214070, 78612), (214070, 79103), (214070, 80309), (214070, 82309),
    (214101, 78612), (214101, 79103), (214101, 80309), (214101, 82309),
    (214099, 78612), (214099, 79103), (214099, 80309), (214099, 82309),
    (214098, 78612), (214098, 79103), (214098, 80309), (214098, 82309),
    (214096, 78612), (214096, 79103), (214096, 80309), (214096, 82309);

REPLACE INTO `creature_questender` (`id`, `quest`) VALUES
    (213077, 78612), (213077, 79103), (213077, 80309), (213077, 82309),
    (214070, 78612), (214070, 79103), (214070, 80309), (214070, 82309),
    (214101, 78612), (214101, 79103), (214101, 80309), (214101, 82309),
    (214099, 78612), (214099, 79103), (214099, 80309), (214099, 82309),
    (214098, 78612), (214098, 79103), (214098, 80309), (214098, 82309),
    (214096, 78612), (214096, 79103), (214096, 80309), (214096, 82309);

-- Gate: each quest is OFFERED only while the player holds >=1 of that tier's
-- Supply Shipment. SourceType 19 = CONDITION_SOURCE_TYPE_QUEST_AVAILABLE,
-- ConditionType 2 = CONDITION_ITEM (Value1 item, Value2 count, Value3 bank=0).
-- NPC-agnostic -- applies to both Elaine and Jornah.
REPLACE INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `Comment`)
VALUES
    (19, 0, 78612, 0, 0, 2, 0, 211367, 1, 0, 'A Full Shipment (P1) offered only while holding a Supply Shipment'),
    (19, 0, 79103, 0, 0, 2, 0, 211839, 1, 0, 'A Full Shipment (P2) offered only while holding a Supply Shipment'),
    (19, 0, 80309, 0, 0, 2, 0, 217337, 1, 0, 'A Full Shipment (P3) offered only while holding a Supply Shipment'),
    (19, 0, 82309, 0, 0, 2, 0, 221008, 1, 0, 'A Full Shipment (P4) offered only while holding a Supply Shipment');
