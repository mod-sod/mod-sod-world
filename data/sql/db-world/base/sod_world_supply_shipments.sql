-- mod-sod-world: Season of Discovery "A Full Shipment" repeatable supply turn-ins.
--
-- Elaine Compton (creature 213077, the shared Azeroth Commerce Authority supply
-- officer) accepts a "Supply Shipment" crate for gold, XP, and ACA reputation.
-- SoD ships four Supply Shipment items, one per phase/level bracket, so there are
-- four repeatable quests -- one per crate tier.
--
-- Real SoD ids are reused where free (verified against the live DB + on-disk
-- DBCs): the four Supply Shipment items 211367 / 211839 / 217337 / 221008, and
-- the four "A Full Shipment" quests 78612 (P1) / 79103 (P2) / 80309 (P3) /
-- 82309 (P4). Wowhead's item "provided for" links point at the wrong tiers, so
-- the quest->tier mapping here is by reputation value, confirmed against the
-- nether.wowhead.com tooltip endpoint (all four are named "A Full Shipment").
--
-- Sourced values (wago.tools wow_classic_era 1.15.8.67156 + Wowhead):
--   Items: Trade Goods (class 7 / subclass 0), Material 0, Quality 2 (uncommon),
--     BoP (bonding 1), non-stackable, RequiredLevel 1, icon INV_Crate_03
--     (FileDataID 132763 -> stock displayid 8928), tooltip "Deliver to a supply
--     officer for a substantial reward." ItemLevel marks the bracket: 10/25/40/50.
--   Reputation per turn-in (Azeroth Commerce Authority 2586): P1 300, P2 800,
--     P3 1000, P4 1850. The core stores rep x100 in RewardFactionOverride1
--     (Player::RewardReputation does override / 100), so 30000/80000/100000/185000.
--   Gold + XP scale to the turning-in player's level (faithful to SoD): QuestLevel
--     = -1 scales XP via QuestXP, and RewardMoneyDifficulty scales gold via
--     quest_money_reward. RewardXPDifficulty / RewardMoneyDifficulty (5) are
--     tunable knobs -- adjust if the in-game reward feels off.
--
-- The quests are gated to appear ONLY while the player is carrying that tier's
-- crate (conditions: CONDITION_SOURCE_TYPE_QUEST_AVAILABLE 19 + CONDITION_ITEM 2),
-- matching SoD -- they are not standing quests you hold empty. Being repeatable
-- (quest_template_addon.SpecialFlags 1) and consuming one crate on turn-in, each
-- quest vanishes after completion until another crate is acquired.
--
-- Elaine herself, her vendor/gossip flags, and the ACA faction live in
-- sod_world_elaine_compton.sql (that file also upgrades faction 2586 to a real,
-- trackable reputation faction so these rep rewards register and show in the pane).
--
-- Idempotent: REPLACE INTO throughout (brand-new custom ids). No DELETEs.

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
-- The four "A Full Shipment" quests. QuestType 2 + QuestLevel -1 (player-scaled
-- XP); RewardMoneyDifficulty 5 (player-scaled gold); RewardFactionID1 2586 with
-- RewardFactionOverride1 = rep x100. RequiredItemId1 = the tier's crate (count 1,
-- consumed on turn-in). QuestSortID 1519 = Stormwind City. Text is the same per
-- tier (one "A Full Shipment" flow); rewards differ. QuestDescription/
-- LogDescription are authored (the SoD accept text is not reproduced verbatim).
-- In AzerothCore the turn-in text fields live in side tables, not quest_template:
-- the progress/"return" text is quest_request_items.CompletionText and the
-- thank-you is quest_offer_reward.RewardText (both REPLACEd below).
-- =====================================================================
REPLACE INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`,
     `SuggestedGroupNum`, `Flags`, `RewardXPDifficulty`, `RewardMoneyDifficulty`,
     `RewardMoney`, `RewardFactionID1`, `RewardFactionOverride1`,
     `RequiredItemId1`, `RequiredItemCount1`,
     `LogTitle`, `LogDescription`, `QuestDescription`)
VALUES
    (78612, 2, -1, 1, 1519, 0, 0, 0, 5, 5, 0, 2586, 30000, 211367, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to Elaine Compton in Stormwind.',
     'The Azeroth Commerce Authority keeps Stormwind stocked, and that means moving a great many crates. If you have a Supply Shipment ready, hand it over and I will see you are paid for your trouble.$B$BEvery shipment helps, $N. The Authority remembers those who keep the wheels turning.'),
    (79103, 2, -1, 25, 1519, 0, 0, 0, 5, 5, 0, 2586, 80000, 211839, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to Elaine Compton in Stormwind.',
     'The Azeroth Commerce Authority keeps Stormwind stocked, and that means moving a great many crates. If you have a Supply Shipment ready, hand it over and I will see you are paid for your trouble.$B$BEvery shipment helps, $N. The Authority remembers those who keep the wheels turning.'),
    (80309, 2, -1, 40, 1519, 0, 0, 0, 5, 5, 0, 2586, 100000, 217337, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to Elaine Compton in Stormwind.',
     'The Azeroth Commerce Authority keeps Stormwind stocked, and that means moving a great many crates. If you have a Supply Shipment ready, hand it over and I will see you are paid for your trouble.$B$BEvery shipment helps, $N. The Authority remembers those who keep the wheels turning.'),
    (82309, 2, -1, 50, 1519, 0, 0, 0, 5, 5, 0, 2586, 185000, 221008, 1,
     'A Full Shipment',
     'Bring a Supply Shipment to Elaine Compton in Stormwind.',
     'The Azeroth Commerce Authority keeps Stormwind stocked, and that means moving a great many crates. If you have a Supply Shipment ready, hand it over and I will see you are paid for your trouble.$B$BEvery shipment helps, $N. The Authority remembers those who keep the wheels turning.');

-- Turn-in / progress text (shown when you talk to Elaine to hand the crate over);
-- this is the SoD tooltip line verbatim.
REPLACE INTO `quest_request_items` (`ID`, `CompletionText`) VALUES
    (78612, 'Do you have something for me?'),
    (79103, 'Do you have something for me?'),
    (80309, 'Do you have something for me?'),
    (82309, 'Do you have something for me?');

-- Reward text (shown on the completion frame).
REPLACE INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
    (78612, 'The Authority thanks you, $N. Keep them coming.'),
    (79103, 'The Authority thanks you, $N. Keep them coming.'),
    (80309, 'The Authority thanks you, $N. Keep them coming.'),
    (82309, 'The Authority thanks you, $N. Keep them coming.');

-- Repeatable (SpecialFlags 1) + no-rep-spillover (64) = 65, so the standalone
-- custom faction never spills rep into a faction group it does not belong to.
REPLACE INTO `quest_template_addon`
    (`ID`, `SpecialFlags`)
VALUES
    (78612, 65),
    (79103, 65),
    (80309, 65),
    (82309, 65);

-- Elaine (213077) both starts and ends each quest.
REPLACE INTO `creature_queststarter` (`id`, `quest`) VALUES
    (213077, 78612), (213077, 79103), (213077, 80309), (213077, 82309);

REPLACE INTO `creature_questender` (`id`, `quest`) VALUES
    (213077, 78612), (213077, 79103), (213077, 80309), (213077, 82309);

-- Gate: each quest is OFFERED only while the player holds >=1 of that tier's
-- Supply Shipment. SourceType 19 = CONDITION_SOURCE_TYPE_QUEST_AVAILABLE,
-- ConditionType 2 = CONDITION_ITEM (Value1 item, Value2 count, Value3 bank=0).
REPLACE INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `Comment`)
VALUES
    (19, 0, 78612, 0, 0, 2, 0, 211367, 1, 0, 'A Full Shipment (P1) offered only while holding a Supply Shipment'),
    (19, 0, 79103, 0, 0, 2, 0, 211839, 1, 0, 'A Full Shipment (P2) offered only while holding a Supply Shipment'),
    (19, 0, 80309, 0, 0, 2, 0, 217337, 1, 0, 'A Full Shipment (P3) offered only while holding a Supply Shipment'),
    (19, 0, 82309, 0, 0, 2, 0, 221008, 1, 0, 'A Full Shipment (P4) offered only while holding a Supply Shipment');
