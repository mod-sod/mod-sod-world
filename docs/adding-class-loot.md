# Adding class loot to the Awakened Lich

In SoD the Awakened Lich drops a different rune for each class. This module
defines the Lich (`creature` 212261) but **no loot** — each class module adds its
own drop. The contract is pure data; your module never links this one.

## 1. Drop your notes off the Lich

The Lich's `creature_template.lootid` is `212261`, so it rolls
`creature_loot_template` rows with `Entry = 212261`:

```sql
DELETE FROM `creature_loot_template` WHERE `Item` = <your_notes_item> AND `Entry` = 212261;
INSERT INTO `creature_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (212261, <your_notes_item>, 0, 100, 0, 1, 0, 1, 1, '<your-module> rune notes');
```

Scope the `DELETE` to **your** item id and `Entry = 212261` — never clear the
whole Lich loot table (you'd wipe other classes' drops).

## 2. Make it class-only (SoD class loot)

So only your class rolls it, add a `conditions` row
(`CONDITION_SOURCE_TYPE_CREATURE_LOOT_TEMPLATE = 1`, `CONDITION_CLASS = 15`):

```sql
DELETE FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 1 AND `SourceGroup` = 212261 AND `SourceEntry` = <your_notes_item>;
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `Comment`)
VALUES
    (1, 212261, <your_notes_item>, 0, 0, 15, 0, <your_classmask>, 0, 0, 0, '<module>: notes drop for <class> only');
```

`ConditionValue1` is the AC classmask (Mage = `128`, Warrior = `1`).

## 3. Unlock the rune from the notes

The notes item itself is yours: give it `ScriptName = 'item_rune_unlock'` (the
`mod-rune-engraving` engine script) and map it in `rune_item_unlock`, exactly as
`mod-sod-mage`'s Mass Regeneration does. The Lich encounter is independent of the
rune engine — this module doesn't know or care which rune your notes unlock.

## 4. Ship the bag icon

Add your notes item to your module's `tools/client_items.json` so the consolidated
client patch carries its `Item.dbc` row — see [client-patch.md](client-patch.md).

`mod-sod-mage`'s `sod_mage_mass_regeneration.sql` is the worked example.
