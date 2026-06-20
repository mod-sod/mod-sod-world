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
#include "DatabaseEnv.h"
#include "Log.h"
#include "LootMgr.h"
#include "ScriptMgr.h"

// Bridges the SodWorld.SupplyDrop.P{1..4}Chance config keys onto the Supply
// Shipment chest-loot rows seeded in sod_world_supply_drops.sql. The rows live in
// gameobject_loot_template (so the drop relationships stay greppable in SQL); this
// script just tunes their `Chance` from the .conf, making the rates admin-editable
// without touching SQL. When SodWorld.Enable is off every chance is forced to 0.
//
// Applied at startup (OnStartup runs after both the scripts and the loot store are
// loaded) and on a live `.reload config`. OnAfterConfigLoad(false) is NOT used for
// the startup pass: at startup config is loaded before module scripts register, so
// that callback never reaches this script.

namespace
{
    // (loot table id = chest gameobject_template.Data1, crate item, phase 1-4).
    // Phase selects the .conf chance key. Mirrors sod_world_supply_drops.sql.
    struct SupplyDropRow
    {
        uint32 LootTable;
        uint32 Item;
        uint8  Phase;
    };

    constexpr SupplyDropRow SUPPLY_DROP_ROWS[] =
    {
        { 2279, 211367, 1 },
        { 2280, 211839, 2 },
        { 2281, 211839, 2 },
        { 2284, 217337, 3 },
        { 9931, 221008, 4 },
        { 5278, 221008, 4 },
    };
}

class world_sod_world_supply_drops : public WorldScript
{
public:
    world_sod_world_supply_drops() : WorldScript("world_sod_world_supply_drops") {}

    void OnStartup() override
    {
        Apply();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        // Only a live `.reload config`; the startup pass is OnStartup (see header).
        if (reload)
            Apply();
    }

private:
    static void Apply()
    {
        bool const enabled = sConfigMgr->GetOption<bool>("SodWorld.Enable", true);

        auto rate = [enabled](char const* key, float def)
        {
            return enabled ? sConfigMgr->GetOption<float>(key, def) : 0.0f;
        };

        float const chance[4] =
        {
            rate("SodWorld.SupplyDrop.P1Chance", 10.0f),
            rate("SodWorld.SupplyDrop.P2Chance", 10.0f),
            rate("SodWorld.SupplyDrop.P3Chance", 10.0f),
            rate("SodWorld.SupplyDrop.P4Chance", 5.0f),
        };

        for (SupplyDropRow const& row : SUPPLY_DROP_ROWS)
            WorldDatabase.DirectExecute(
                "UPDATE `gameobject_loot_template` SET `Chance` = {} "
                "WHERE `Entry` = {} AND `Item` = {}",
                chance[row.Phase - 1], row.LootTable, row.Item);

        // Re-read the gameobject loot store so the updated chances take effect.
        LoadLootTemplates_Gameobject();

        LOG_INFO("server.loading",
            "mod-sod-world: Supply Shipment drop chances applied "
            "(P1 {}%, P2 {}%, P3 {}%, P4 {}%).",
            chance[0], chance[1], chance[2], chance[3]);
    }
};

void AddSC_world_sod_world_supply_drops()
{
    new world_sod_world_supply_drops();
}
