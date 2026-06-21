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

#include "Creature.h"
#include "GossipDef.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

// Gossip for the SoD supply officers (Elaine Compton 213077, Jornah 214070): a
// vendor + quest giver. The rune-engraving gossip used to live here (the officers
// reused ScriptName 'npc_rune_engraver'); that moved to the dedicated Rune Engraver
// NPC (mod-rune-engraving 700000), leaving the officers as pure sod-world content --
// a vendor any module can stock via npc_vendor, plus the supply-shipment quests.

enum SupplyOfficerSender
{
    SENDER_VENDOR = 1, // open the vendor inventory
};

class npc_sod_world_supply_officer : public CreatureScript
{
public:
    npc_sod_world_supply_officer() : CreatureScript("npc_sod_world_supply_officer") {}

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();

        // Vendor option only when the officer actually has goods to sell.
        if (creature->HasNpcFlag(UNIT_NPC_FLAG_VENDOR))
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "What do you have for sale?", SENDER_VENDOR, 0);

        // Surface the officer's quests (the "A Full Shipment" turn-ins) -- the custom
        // gossip would otherwise replace the default menu and hide them.
        player->PrepareQuestMenu(creature->GetGUID());

        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 /*action*/) override
    {
        player->PlayerTalkClass->ClearMenus();

        if (sender == SENDER_VENDOR)
            player->GetSession()->SendListInventory(creature->GetGUID());

        return true;
    }
};

void AddSC_npc_sod_world_supply_officer()
{
    new npc_sod_world_supply_officer();
}
