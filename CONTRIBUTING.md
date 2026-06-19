# Contributing to mod-sod-world

Adding a creature, gameobject, or world item? Start with a template.

1. Open **[`templates/`](templates/README.md)** and find the content type (NPC,
   gameobject, item, plus a config helper).
2. Copy the skeleton into its real location and fill the `<PLACEHOLDER>` blanks. The
   templates live outside `src/` and `data/sql/`, so they're never compiled or
   applied — they're reference only.
3. Follow **[`docs/`](docs/Home.md)** for the full recipes — adding class loot to a
   shared creature, and how the consolidated client patch (built by `sod-client`)
   works.

Source accurate SoD values from the places listed in
[`templates/README.md`](templates/README.md#sources-of-truth) (wago.tools, Wowhead
Classic, the AzerothCore wiki).

Keep content greppable: prefix C++ classes and SQL with `sod_world_` / `SOD_WORLD`,
config keys with `SodWorld.`, and reuse real SoD ids where they exist (else the
documented id bands). Prefer **SmartAI** over a C++ creature script. No core edits —
everything stays under `modules/mod-sod-world/`.
