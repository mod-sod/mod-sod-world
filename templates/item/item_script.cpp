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

// TEMPLATE — a "use" item (summon, key, trigger). Set the item's
// item_template.ScriptName to this script's name. Copy into src/, then add
// AddSC_item_sod_world_<name>() to the module loader. Not built from templates/.
// Model: src/item_sod_world_phylactery.cpp.

#include "Chat.h"
#include "Configuration/Config.h"
#include "GameObject.h"
#include "Item.h"
#include "ItemScript.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"

enum SodWorld<Name>
{
    NPC_SOD_WORLD_<NAME> = <NPC_ID>,
    GO_SOD_WORLD_<NAME>  = <GO_ID>,   // the prop the item must be used near, if any
};

class item_sod_world_<name> : public ItemScript
{
public:
    item_sod_world_<name>() : ItemScript("item_sod_world_<name>") {}

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!player || !item)
            return false;

        if (!sConfigMgr->GetOption<bool>("SodWorld.Enable", true))
            return false; // module disabled — let the benign use-spell run

        // Example: require the player to be near a prop, then summon a creature.
        float const range = sConfigMgr->GetOption<float>("SodWorld.<Name>.Range", 10.0f);

        GameObject* anchor = player->FindNearestGameObject(GO_SOD_WORLD_<NAME>, range);
        if (!anchor)
        {
            player->SendEquipError(EQUIP_ERR_OUT_OF_RANGE, item, nullptr);
            return true; // handled — suppress the benign use-spell
        }

        // TODO: your action. e.g. summon, unlock a door, start an event.
        // player->SummonCreature(NPC_SOD_WORLD_<NAME>, anchor->GetPositionX(), ...,
        //     TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 300 * IN_MILLISECONDS);

        return true; // handled — suppress the benign use-spell
    }
};

void AddSC_item_sod_world_<name>()
{
    new item_sod_world_<name>();
}
