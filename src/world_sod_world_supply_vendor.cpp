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

#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "sod_world_supply.h"

// Builds the supply officers' reputation-tier vendor lists IN MEMORY from the
// sod_world_supply_vendor source table. Each row is (item, minimum reputation RANK); the
// faction is derived from the officer at runtime (see player_sod_world_supply_vendor.cpp),
// so the lists are faction-neutral. Cumulative: an item at RequiredRank R is added to
// every tier R..7, so a player sees everything at or below their rank in one list.
// Vendor-store entries 700060+rank (SodWorldSupply::TIER_ENTRY_BASE) hold the lists;
// nothing is written to `npc_vendor` (AddVendorItem persist = false).
//
// Build runs at OnStartup only -- AddVendorItem appends, so re-running on `.reload`
// would duplicate rows; adding an item to the table needs a worldserver restart. The
// runtime SodWorld.Enable gate lives in the redirect/gossip, not here, so a live
// `.reload config` toggle still takes effect without a rebuild.

namespace
{
    constexpr uint8 MAX_REP_RANK = 7; // REP_EXALTED
}

class world_sod_world_supply_vendor : public WorldScript
{
public:
    world_sod_world_supply_vendor() : WorldScript("world_sod_world_supply_vendor") {}

    void OnStartup() override
    {
        QueryResult result = WorldDatabase.Query("SELECT `item`, `RequiredRank` FROM `sod_world_supply_vendor`");
        if (!result)
        {
            LOG_INFO("server.loading", "mod-sod-world: no supply-vendor items defined.");
            return;
        }

        uint32 items = 0;
        do
        {
            Field* fields = result->Fetch();
            uint32 const item = fields[0].Get<uint32>();
            uint8 const rank = std::min<uint8>(fields[1].Get<uint8>(), MAX_REP_RANK);

            // Cumulative: visible at this rank and every higher one.
            for (uint8 tier = rank; tier <= MAX_REP_RANK; ++tier)
                sObjectMgr->AddVendorItem(SodWorldSupply::TierEntryForRank(tier), item, 0, 0, 0, false);

            ++items;
        } while (result->NextRow());

        LOG_INFO("server.loading",
            "mod-sod-world: built supply-vendor reputation tiers for {} item(s).", items);
    }
};

void AddSC_world_sod_world_supply_vendor()
{
    new world_sod_world_supply_vendor();
}
