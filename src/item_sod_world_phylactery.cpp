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
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "TemporarySummon.h"

// Awakening the Awakened Lich (the shared Season of Discovery elite that drops
// each class's rune notes) has two triggers, both requiring the Decrepit
// Phylactery (item 210568) and the Slumbering Bones, and both reusable (the
// phylactery is never consumed, faithful to SoD):
//   1. *Using* the phylactery while near the bones (item_sod_world_phylactery).
//   2. *Clicking* the bones gameobject while carrying the phylactery
//      (go_sod_world_slumbering_bones).
// The phylactery carries a harmless ON_USE spell only so the client offers "Use";
// the item script suppresses it (returns true).
//
// IDs: the Lich is the real SoD npc id (so class modules can hang loot rows off
// it); the Slumbering Bones is a decorative seated-skeleton gameobject prop (on a
// Broken Stone Throne) with no cross-module contract, so it uses a mod-sod-world
// custom gameobject id.
enum SodWorldPhylactery
{
    NPC_SOD_WORLD_AWAKENED_LICH    = 212261, // creature (real SoD id)
    ITEM_SOD_WORLD_PHYLACTERY      = 210568, // Decrepit Phylactery (real SoD id)
    GO_SOD_WORLD_SLUMBERING_BONES  = 701001, // seated-skeleton gameobject prop
};

namespace
{
    // Awaken the Lich at the Slumbering Bones. Shared by both triggers; the caller
    // has already confirmed the module is enabled and the player is at the bones.
    // Only one Lich at a time. `source` labels the "already stirs" message.
    void AwakenLich(Player* player, GameObject* bones, char const* source)
    {
        // Already awakened nearby: don't stack summons.
        if (player->FindNearestCreature(NPC_SOD_WORLD_AWAKENED_LICH, 60.0f))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cFFFF0000[{}]|r Something already stirs nearby.", source);
            return;
        }

        uint32 const despawn = sConfigMgr->GetOption<uint32>(
            "SodWorld.AwakenedLich.DespawnSeconds", 300) * IN_MILLISECONDS;

        // Apply the configured Lich level to its template so the summon scales to
        // it (the level + stats come from creature_template at summon via
        // SelectLevel). The Lich is summon-only, so mutating the cached template
        // only ever affects future summons -- no spawned instance to refresh.
        uint8 const level = uint8(sConfigMgr->GetOption<uint32>(
            "SodWorld.AwakenedLich.Level", 25));
        if (CreatureTemplate const* tmpl =
                sObjectMgr->GetCreatureTemplate(NPC_SOD_WORLD_AWAKENED_LICH))
            if (tmpl->minlevel != level || tmpl->maxlevel != level)
            {
                const_cast<CreatureTemplate*>(tmpl)->minlevel = level;
                const_cast<CreatureTemplate*>(tmpl)->maxlevel = level;
            }

        // Awaken the Lich at the bones; it despawns on death (after its corpse is
        // looted) or after the timeout if the player flees.
        if (TempSummon* lich = player->SummonCreature(NPC_SOD_WORLD_AWAKENED_LICH,
                bones->GetPositionX(), bones->GetPositionY(), bones->GetPositionZ(),
                bones->GetOrientation(), TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, despawn))
        {
            if (lich->AI())
                lich->AI()->AttackStart(player);
        }
    }
}

// Trigger 1: using the phylactery near the bones.
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

        float const range = sConfigMgr->GetOption<float>(
            "SodWorld.Phylactery.SummonRange", 10.0f);

        GameObject* bones =
            player->FindNearestGameObject(GO_SOD_WORLD_SLUMBERING_BONES, range);
        if (!bones)
        {
            // Not near the Slumbering Bones — nothing here to awaken.
            player->SendEquipError(EQUIP_ERR_OUT_OF_RANGE, item, nullptr);
            return true; // handled — suppress the benign use-spell
        }

        AwakenLich(player, bones, "Decrepit Phylactery");
        return true; // handled — suppress the benign use-spell
    }
};

// Trigger 2: clicking the Slumbering Bones while carrying the phylactery.
class go_sod_world_slumbering_bones : public GameObjectScript
{
public:
    go_sod_world_slumbering_bones()
        : GameObjectScript("go_sod_world_slumbering_bones") { }

    bool OnGossipHello(Player* player, GameObject* go) override
    {
        if (!player || !go)
            return false;

        if (!sConfigMgr->GetOption<bool>("SodWorld.Enable", true))
            return false; // module disabled — leave the prop inert

        // The bones only stir for someone carrying the Decrepit Phylactery.
        if (!player->HasItemCount(ITEM_SOD_WORLD_PHYLACTERY, 1))
            return false;

        AwakenLich(player, go, "Slumbering Bones");
        return true; // handled — we drove the interaction
    }
};

void AddSC_item_sod_world_phylactery()
{
    new item_sod_world_phylactery();
    new go_sod_world_slumbering_bones();
}
