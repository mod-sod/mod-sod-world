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

// TEMPLATE — only when SmartAI can't express the behavior. For most enemies, use the
// smart_scripts rows in creature.sql instead (no rebuild). Copy into src/, set the
// creature_template.AIName to '' and ScriptName to 'npc_sod_world_<name>', then add
// AddSC_npc_sod_world_<name>() to the module loader. Not built from templates/.

#include "ScriptMgr.h"
#include "ScriptedCreature.h"

enum SodWorld<Name>Spells
{
    SPELL_SOD_WORLD_<NAME> = <SPELL_ID>,
};

struct npc_sod_world_<name> : public ScriptedAI
{
    npc_sod_world_<name>(Creature* creature) : ScriptedAI(creature) {}

    void Reset() override
    {
        _scheduler.CancelAll();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        // Schedule abilities. TaskScheduler handles repeats/cancellation — don't roll
        // your own tick counters.
        _scheduler.Schedule(3s, 4500ms, [this](TaskContext task)
        {
            DoCastVictim(SPELL_SOD_WORLD_<NAME>);
            task.Repeat();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _scheduler.Update(diff);
        DoMeleeAttackIfReady();
    }

private:
    TaskScheduler _scheduler;
};

void AddSC_npc_sod_world_<name>()
{
    RegisterCreatureAI(npc_sod_world_<name>);
}
