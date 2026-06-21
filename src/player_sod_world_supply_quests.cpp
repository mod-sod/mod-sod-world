/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Configuration/Config.h"
#include "DBCStores.h"
#include "Player.h"
#include "QuestDef.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include <unordered_map>

// Reputation + XP for the four "A Full Shipment" supply turn-ins
// (sod_world_supply_shipments.sql). Two things the quest_template cannot express
// correctly are handled here:
//
//   * Reputation is per TEAM. The quests grant no built-in faction
//     (RewardFactionID1 = 0); on turn-in we grant the tier's rep to the player's
//     OWN supply faction -- Alliance -> Azeroth Commerce Authority (2586), Horde ->
//     Durotar Supply and Logistics (2587). Real SoD lists both factions on the
//     quest data, but a player must never gain rep with the opposite team's faction.
//
//   * XP is forced to 0. Real SoD XP for these could not be sourced (Wowhead shows
//     80/200 for P1/P2 and nothing for P3/P4); they read as gold-only quests, so we
//     deliberately award no XP rather than invent a value.
//
// No-op when the module master SodWorld.Enable is off.

namespace
{
    constexpr uint32 FACTION_ACA     = 2586; // Azeroth Commerce Authority (Alliance)
    constexpr uint32 FACTION_DUROTAR = 2587; // Durotar Supply and Logistics (Horde)

    // Quest id -> reputation granted to the turn-in player's own supply faction.
    std::unordered_map<uint32, int32> const SUPPLY_QUEST_REP =
    {
        { 78612, 300 },  // A Full Shipment (P1)
        { 79103, 800 },  // A Full Shipment (P2)
        { 80309, 1000 }, // A Full Shipment (P3)
        { 82309, 1850 }, // A Full Shipment (P4)
    };

    bool IsEnabled()
    {
        return sConfigMgr->GetOption<bool>("SodWorld.Enable", true);
    }
}

class player_sod_world_supply_quests : public PlayerScript
{
public:
    player_sod_world_supply_quests() : PlayerScript("player_sod_world_supply_quests") {}

    // Gold-only quests: no sourced SoD XP value, so award none (see header).
    void OnPlayerQuestComputeXP(Player* /*player*/, Quest const* quest, uint32& xpValue) override
    {
        if (SUPPLY_QUEST_REP.find(quest->GetQuestId()) != SUPPLY_QUEST_REP.end())
            xpValue = 0;
    }

    // Grant the tier's reputation to the player's OWN supply faction on turn-in.
    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (!IsEnabled())
            return;

        auto it = SUPPLY_QUEST_REP.find(quest->GetQuestId());
        if (it == SUPPLY_QUEST_REP.end())
            return;

        uint32 const factionId = (player->GetTeamId() == TEAM_ALLIANCE) ? FACTION_ACA : FACTION_DUROTAR;
        if (FactionEntry const* faction = sFactionStore.LookupEntry(factionId))
            player->GetReputationMgr().ModifyReputation(faction, float(it->second)); // incremental (public wrapper)
    }
};

void AddSC_player_sod_world_supply_quests()
{
    new player_sod_world_supply_quests();
}
