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

#ifndef SOD_WORLD_SUPPLY_H
#define SOD_WORLD_SUPPLY_H

#include "Configuration/Config.h"
#include "Creature.h"
#include "DBCStructure.h"
#include "Player.h"

// Shared helpers for the supply-officer vendor (gossip option + list redirect). The rep
// gate is a vendor redirect: each officer is pointed at a per-rank, faction-neutral
// vendor list built in memory at startup (see world_sod_world_supply_vendor.cpp). The
// required faction is derived from the officer (Alliance officers carry faction 2586,
// Horde 2587), so the player's rank with the officer's OWN faction picks the tier.
namespace SodWorldSupply
{
    // In-memory vendor-store entries 700060..700067 hold the cumulative item list for
    // ReputationRank 0..7 (an item at RequiredRank R is added to every tier R..7).
    constexpr uint32 TIER_ENTRY_BASE = 700060;

    inline bool Enabled()
    {
        return sConfigMgr->GetOption<bool>("SodWorld.Enable", true);
    }

    inline uint32 TierEntryForRank(uint8 rank)
    {
        return TIER_ENTRY_BASE + rank;
    }

    // The tier vendor-list entry this player sees at this officer, or 0 when the module
    // is disabled or the officer has no faction template (no list -> no vendor option).
    inline uint32 TierEntryFor(Player* player, Creature* officer)
    {
        if (!Enabled())
            return 0;

        FactionTemplateEntry const* factionTemplate = officer->GetFactionTemplateEntry();
        if (!factionTemplate)
            return 0;

        uint8 const rank = static_cast<uint8>(player->GetReputationRank(factionTemplate->faction));
        return TierEntryForRank(rank);
    }
}

#endif // SOD_WORLD_SUPPLY_H
