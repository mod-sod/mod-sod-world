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

#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "sod_world_supply.h"

// Reputation gate for the supply officers, via a vendor-list REDIRECT. When a player
// opens a supply officer, point the merchant list at the in-memory tier entry matching
// the player's rank with that officer's faction (built by world_sod_world_supply_vendor).
// The core builds the list from this entry (ItemHandler::SendListInventory) AND keys the
// buy off it (Player::BuyItemFromVendorSlot via GetCurrentVendor), so this single redirect
// gates both display and purchase -- no per-item conditions, no buy hook. Other vendors
// are untouched (we only act on creatures running the supply-officer script).

class player_sod_world_supply_vendor : public PlayerScript
{
public:
    player_sod_world_supply_vendor() : PlayerScript("player_sod_world_supply_vendor") {}

    void OnPlayerSendListInventory(Player* player, ObjectGuid vendorGuid, uint32& vendorEntry) override
    {
        Creature* officer = ObjectAccessor::GetCreature(*player, vendorGuid);
        if (!officer)
            return;

        // Only redirect our supply officers; leave every other vendor alone.
        static uint32 const officerScriptId = sObjectMgr->GetScriptId("npc_sod_world_supply_officer");
        if (officer->GetScriptId() != officerScriptId)
            return;

        vendorEntry = SodWorldSupply::TierEntryFor(player, officer);
    }
};

void AddSC_player_sod_world_supply_vendor()
{
    new player_sod_world_supply_vendor();
}
