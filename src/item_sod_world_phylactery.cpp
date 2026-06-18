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

#include "Chat.h"
#include "Configuration/Config.h"
#include "Creature.h"
#include "GameObject.h"
#include "Item.h"
#include "ItemScript.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "TemporarySummon.h"

// The Decrepit Phylactery (item 210568): used near the Slumbering Bones it
// awakens the Awakened Lich (the shared Season of Discovery elite that drops
// each class's rune notes). The phylactery is NOT consumed — it is reusable,
// faithful to SoD. Pure summon logic; the item carries a harmless ON_USE spell
// only so the client offers "Use", which this script suppresses (returns true).
//
// IDs: the Lich is the real SoD npc id (so class modules can hang loot rows off
// it); the Slumbering Bones is a decorative seated-skeleton gameobject prop (on a
// Broken Stone Throne) with no cross-module contract, so it uses a mod-sod-world
// custom gameobject id.
enum SodWorldPhylactery
{
    NPC_SOD_WORLD_AWAKENED_LICH    = 212261, // creature (real SoD id)
    GO_SOD_WORLD_SLUMBERING_BONES  = 701001, // seated-skeleton gameobject prop
};

class item_sod_world_phylactery : public ItemScript
{
public:
    item_sod_world_phylactery() : ItemScript("item_sod_world_phylactery") {}

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!player || !item)
            return false;

        if (!sConfigMgr->GetOption<bool>("SodWorld.Enable", true))
            return false; // module disabled — let the benign use-spell run

        float const range = sConfigMgr->GetOption<float>("SodWorld.Phylactery.SummonRange", 10.0f);

        GameObject* bones = player->FindNearestGameObject(GO_SOD_WORLD_SLUMBERING_BONES, range);
        if (!bones)
        {
            // Not near the Slumbering Bones — nothing here to awaken.
            player->SendEquipError(EQUIP_ERR_OUT_OF_RANGE, item, nullptr);
            return true; // handled — suppress the benign use-spell
        }

        // Already awakened nearby: don't stack summons.
        if (player->FindNearestCreature(NPC_SOD_WORLD_AWAKENED_LICH, 60.0f))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF0000[Decrepit Phylactery]|r Something already stirs nearby.");
            return true;
        }

        uint32 const despawn = sConfigMgr->GetOption<uint32>(
            "SodWorld.AwakenedLich.DespawnSeconds", 300) * IN_MILLISECONDS;

        // Awaken the Lich at the bones; it despawns on death (after its corpse is
        // looted) or after the timeout if the player flees.
        if (TempSummon* lich = player->SummonCreature(NPC_SOD_WORLD_AWAKENED_LICH,
                bones->GetPositionX(), bones->GetPositionY(), bones->GetPositionZ(),
                bones->GetOrientation(), TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, despawn))
        {
            if (lich->AI())
                lich->AI()->AttackStart(player);
        }

        return true; // handled — suppress the benign use-spell
    }
};

void AddSC_item_sod_world_phylactery()
{
    new item_sod_world_phylactery();
}
