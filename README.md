# NBT Compat

Every Compat–style wooden variants without registry bloat: **one registered block** per furniture kind; wood identity and planks texture live in **block-entity NBT** / **item data components**.

## Requirements

- Minecraft 1.21.1 + NeoForge 21.1.x
- Optional: [Moonlight Lib](https://www.curseforge.com/minecraft/mc-mods/selene) — discovers every wood set (vanilla + modded). Without it, falls back to `#minecraft:planks`.

## Recipe patterns (all woods)

Default is 2×2 {@code wood:planks}. Redefine for every wood (and future endpoints) from server scripts:

```js
NbtCompatEvents.defineRecipes(event => {
  event.craftingTable()
    .shaped(['AB', 'CA'], {
      A: 'wood:log',                           // per-wood child
      B: 'artisanworktables:wood_handsaw',     // fixed item
      C: 'minecraft:flint'                     // fixed item
    })
})
```

Wood keys: `wood:planks`, `wood:log`, `wood:wood`, `wood:slab`, `wood:stairs`, `wood:stripped_log`, … (Moonlight children when available). Fixed keys: item ids or `#tags`.


Variants are only an id → planks mapping (NBT), so no extra blocks. Define extras Moonlight/`#minecraft:planks` miss:

```js
// kubejs/startup_scripts/…js  (recommended — client + server)
NbtCompatEvents.defineWoods(event => {
  event.add('biomesoplenty:hellbark', 'biomesoplenty:hellbark_planks')
  event.add('mymod:glow', 'mymod:glow_planks', 'Glow Wood')
  event.remove('minecraft:bamboo')
  // event.clear()  // drop all overrides first
})
```

From `server_scripts`, `NbtCompat.defineWoods(...)` works for the index; prefer startup so creative tab / top sprites see them without a later resource reload.

## Build

```bash
./build.sh
```

Copies `build/libs/nbtcompat-1.0.0.jar` into the kizaotastic instance `mods/` folder.

## How wood is stored

| Place | Key | Value |
| --- | --- | --- |
| Item | data component `nbtcompat:wood` | `ResourceLocation` (e.g. `minecraft:birch`) |
| Block entity | NBT `Wood` | same string |

Client rendering reads that id, resolves the planks block, and remaps the model’s `#wood` texture slots to that planks particle sprite.
