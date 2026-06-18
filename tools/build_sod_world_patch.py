#!/usr/bin/env python3
"""Build the consolidated SoD client item patch MPQ.

WoW MPQ patches replace whole DBC files (no row-level merge), so every SoD
module's custom-item client rows must live in ONE Item.dbc. mod-sod-world owns
that consolidation: it aggregates the per-module item manifests and emits a
single patch carrying:

  * Item.dbc   — every custom item (itemId -> DisplayInfoID) so bag icons resolve
                 (a missing row shows the red "?" icon in bags; vendor/loot
                 frames are unaffected, they carry the displayid directly), and
  * ItemDisplayInfo.dbc — custom display rows (DisplayInfoID -> InventoryIcon)
                 for items whose SoD icon has no existing 3.3.5a item display
                 (e.g. the Decrepit Phylactery's spell_shadow_devouringplague).

Each content module contributes data only:
  tools/client_items.json    — [{id,name,class,subclass,material,display,invtype,sheath}, ...]
  tools/client_displays.json — [{id,name,icon}, ...]   (optional)

This tool globs ../mod-sod-*/tools/*.json (so mod-sod-mage, a future
mod-sod-warrior, and this module all feed the one patch with no C++ or build
coupling). The patch is written to its own locale letter (patch-enus-y.mpq), a
DIFFERENT file from mod-sod-mage's spell patch (patch-enus-z.mpq); since the two
touch disjoint DBCs they both apply. Regenerate BOTH after changing items.

Requires `pympq` (StormLib binding).

Usage:
    python build_sod_world_patch.py [--client DIR] [--dry-run]
"""

import argparse
import glob
import json
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODULE_ROOT = os.path.dirname(HERE)
MODULES_DIR = os.path.dirname(MODULE_ROOT)

DEFAULT_CLIENT = r"E:\Games\World of Warcraft 3.3.5a HD"
PATCH_MPQ_NAME = "patch-enus-y.mpq"          # this module's item patch
MAGE_PATCH_NAME = "patch-enus-z.mpq"         # mod-sod-mage's spell patch (ignored as a base)

ITEM_INNER = "DBFilesClient\\Item.dbc"
IDI_INNER = "DBFilesClient\\ItemDisplayInfo.dbc"

# Archives that may carry stale custom rows — never use them as the extraction
# base, so we always build Item.dbc/ItemDisplayInfo.dbc from the clean client
# data (the HD client's own patch-enus-a.mpq IS a legitimate base and is kept).
IGNORE_AS_BASE = {PATCH_MPQ_NAME.lower(), MAGE_PATCH_NAME.lower()}

# ItemDisplayInfo.dbc (3.3.5a): 25 int fields, field 5 = InventoryIcon[0].
IDI_ICON_FIELD = 5


# ---------------------------------------------------------------------------
# WDBC reader/writer (3.3.5a fixed-width records + trailing string block).
# ---------------------------------------------------------------------------
class WDBC:
    def __init__(self, raw):
        magic, self.nrec, self.nfield, self.recsize, self.strsize = \
            struct.unpack("<4siiii", raw[:20])
        if magic != b"WDBC":
            raise ValueError("not a WDBC file")
        body = 20 + self.nrec * self.recsize
        self.records = [bytearray(raw[20 + i * self.recsize:
                                      20 + (i + 1) * self.recsize])
                        for i in range(self.nrec)]
        self.strings = bytearray(raw[body:body + self.strsize])

    @classmethod
    def load(cls, path):
        with open(path, "rb") as fh:
            return cls(fh.read())

    def get_int(self, rec, field):
        return struct.unpack_from("<i", rec, field * 4)[0]

    def set_int(self, rec, field, value):
        struct.pack_into("<i", rec, field * 4, int(value))

    def add_string(self, text):
        offset = len(self.strings)
        self.strings += text.encode("utf-8") + b"\x00"
        return offset

    def find(self, row_id):
        for rec in self.records:
            if self.get_int(rec, 0) == row_id:
                return rec
        raise KeyError(row_id)

    def serialize(self):
        out = bytearray()
        out += struct.pack("<4siiii", b"WDBC", len(self.records),
                           self.nfield, self.recsize, len(self.strings))
        for rec in self.records:
            out += rec
        out += self.strings
        return bytes(out)


# ---------------------------------------------------------------------------
# Manifest aggregation (data-only contract with sibling modules).
# ---------------------------------------------------------------------------
def _load_manifests(filename):
    rows = {}
    for path in sorted(glob.glob(os.path.join(MODULES_DIR, "mod-sod-*", "tools", filename))):
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError) as exc:
            print("[!] skipping %s: %s" % (path, exc))
            continue
        module = os.path.basename(os.path.dirname(os.path.dirname(path)))
        for row in data:
            rid = int(row["id"])
            if rid in rows and rows[rid][1] != row:
                print("[!] conflict on id %d: %s overrides %s"
                      % (rid, module, rows[rid][0]))
            rows[rid] = (module, row)
    return [r for _, r in sorted(rows.values(), key=lambda kv: int(kv[1]["id"]))]


def load_items():
    return _load_manifests("client_items.json")


def load_displays():
    return _load_manifests("client_displays.json")


# ---------------------------------------------------------------------------
# MPQ extraction / packing (pympq / StormLib).
# ---------------------------------------------------------------------------
def mpq_priority(path):
    """Approximate WoW's archive load priority (higher wins)."""
    name = os.path.basename(path).lower()
    m = re.match(r"patch(?:-[a-z]{2,4})?(?:-([0-9a-z]+))?\.mpq$", name)
    if not m:
        return (0, 0)
    suffix = m.group(1) or ""
    if suffix == "":
        rank = 0
    elif suffix.isdigit():
        rank = int(suffix)
    else:
        rank = 10 + (ord(suffix[0]) - ord("a"))
    return (1, rank)


def extract_client_dbc(client_dir, name, dest):
    """Extract `name` from the highest-priority archive that is not one of our
    own module patches (so we build on the clean client base)."""
    import pympq
    inner = "DBFilesClient\\" + name
    base = os.path.join(client_dir, "data")
    locale = os.path.join(client_dir, "data", "enus")
    search = []
    for d in (base, locale):
        if os.path.isdir(d):
            search += [os.path.join(d, f) for f in os.listdir(d)
                       if f.lower().endswith(".mpq")
                       and f.lower() not in IGNORE_AS_BASE]
    found = None
    best = (-1, -1)
    for p in search:
        try:
            m = pympq.open_archive(p, None)
        except Exception:
            continue
        try:
            if m.has_file(inner) and mpq_priority(p) > best:
                best = mpq_priority(p)
                found = p
        finally:
            m.close()
    if not found:
        raise RuntimeError("not found in any archive: " + name)
    m = pympq.open_archive(found, None)
    try:
        m.extract_file(inner, dest)
    finally:
        m.close()
    return found


def build_item_dbc(workdir, items):
    """Item.dbc rows: ID, ClassID, SubclassID, SoundOverrideSubclassID(-1),
    Material, DisplayInfoID, InventoryType, SheatheType."""
    item = WDBC.load(os.path.join(workdir, "Item.dbc"))
    existing = {item.get_int(r, 0) for r in item.records}
    for it in items:
        if it["id"] in existing:
            rec = item.find(it["id"])      # re-runnable: update in place
        else:
            rec = bytearray(item.recsize)
            item.records.append(rec)
        item.set_int(rec, 0, it["id"])
        item.set_int(rec, 1, it["class"])
        item.set_int(rec, 2, it["subclass"])
        item.set_int(rec, 3, -1)
        item.set_int(rec, 4, it["material"])
        item.set_int(rec, 5, it["display"])
        item.set_int(rec, 6, it["invtype"])
        item.set_int(rec, 7, it["sheath"])
        print("[*] Item.dbc: %d (%s) -> display %d" % (it["id"], it["name"], it["display"]))
    out = os.path.join(workdir, "Item.dbc.patched")
    with open(out, "wb") as fh:
        fh.write(item.serialize())
    return out


def build_item_display_info(workdir, displays):
    """ItemDisplayInfo.dbc rows for custom displayids: set only the id and
    InventoryIcon[0]; all model/texture fields stay empty (these displays are
    only ever resolved for a bag icon, never equipped)."""
    if not displays:
        return None
    idi = WDBC.load(os.path.join(workdir, "ItemDisplayInfo.dbc"))
    existing = {idi.get_int(r, 0) for r in idi.records}
    for disp in displays:
        if disp["id"] in existing:
            rec = idi.find(disp["id"])
            # clear the old icon field's reference by re-appending a fresh string
        else:
            rec = bytearray(idi.recsize)
            idi.records.append(rec)
        idi.set_int(rec, 0, disp["id"])
        idi.set_int(rec, IDI_ICON_FIELD, idi.add_string(disp["icon"]))
        print("[*] ItemDisplayInfo.dbc: %d -> icon %s (%s)"
              % (disp["id"], disp["icon"], disp["name"]))
    out = os.path.join(workdir, "ItemDisplayInfo.dbc.patched")
    with open(out, "wb") as fh:
        fh.write(idi.serialize())
    return out


def pack_mpq(files, out_mpq):
    import pympq
    if os.path.exists(out_mpq):
        os.remove(out_mpq)
    m = pympq.create_archive(
        out_mpq,
        [pympq.MPQ_CREATE_ARCHIVE_V1, pympq.MPQ_CREATE_LISTFILE,
         pympq.MPQ_CREATE_ATTRIBUTES],
        8)
    try:
        for src, inner in files:
            m.add_file(src, inner,
                       [pympq.MPQ_FILE_COMPRESS, pympq.MPQ_FILE_REPLACEEXISTING],
                       [pympq.MPQ_COMPRESSION_ZLIB])
    finally:
        m.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", default=DEFAULT_CLIENT,
                    help="WoW client root (contains Data/ or data/)")
    ap.add_argument("--workdir", default=os.path.join(HERE, "_work"),
                    help="scratch dir for extracted DBCs / patched output")
    ap.add_argument("--dry-run", action="store_true",
                    help="build patched DBCs but do not write the MPQ")
    args = ap.parse_args()

    items = load_items()
    displays = load_displays()
    print("[*] aggregated %d item(s), %d custom display(s) from module manifests"
          % (len(items), len(displays)))
    if not items and not displays:
        print("[*] nothing to patch")
        return

    os.makedirs(args.workdir, exist_ok=True)
    print("[*] extracting client base DBCs from", args.client)
    src = extract_client_dbc(args.client, "Item.dbc",
                             os.path.join(args.workdir, "Item.dbc"))
    print("    Item.dbc            <- %s" % os.path.basename(src))
    if displays:
        src = extract_client_dbc(args.client, "ItemDisplayInfo.dbc",
                                 os.path.join(args.workdir, "ItemDisplayInfo.dbc"))
        print("    ItemDisplayInfo.dbc <- %s" % os.path.basename(src))

    item_patched = build_item_dbc(args.workdir, items)
    idi_patched = build_item_display_info(args.workdir, displays)

    if args.dry_run:
        print("[*] dry-run: skipping MPQ pack")
        return

    out_mpq = os.path.join(args.client, "data", "enus", PATCH_MPQ_NAME)
    files = [(item_patched, ITEM_INNER)]
    if idi_patched:
        files.append((idi_patched, IDI_INNER))
    pack_mpq(files, out_mpq)
    print("[*] wrote client patch -> %s (%d DBC file(s))" % (out_mpq, len(files)))


if __name__ == "__main__":
    sys.exit(main())
