# NBT Compat

Every Compat–style variants without registry bloat: **one registered block** per kind; identity lives in **block-entity NBT** / **item data components**.

Covers wood furniture, dyed wood, Chipped-style planks/stone/doors, Create casings, Macaw-style roofs / gutters / awnings, and stone cobble → gravel → sand — driven by indexes you can extend from KubeJS.

## Requirements

- Minecraft **1.21.1** + NeoForge **21.1.x**
- Optional:
  - [KubeJS](https://kubejs.com/) — woods / metals / dyes / stones / recipe patterns
  - [Moonlight Lib](https://www.curseforge.com/minecraft/mc-mods/selene) — discovers wood sets (else `#minecraft:planks`)
  - [Artisan Worktables](https://www.curseforge.com/minecraft/mc-mods/artisan-worktables) — dual-register carpenter recipes
  - JEI 19.x — subtypes / recipe views
  - Chipped, Create, Mekanism — richer content when present
  - [Macaw's Roofs](https://www.curseforge.com/minecraft/mc-mods/macaws-roofs) — NBT gutter models/textures load from this mod (gutters are useless without it)

## Build

```bash
./build.sh
```

Installs `build/libs/nbtcompat-1.0.0.jar` into the kizaotastic instance `mods/` folder.

---

## KubeJS overview

| Event | Script type | Purpose |
| --- | --- | --- |
| `NbtCompatEvents.defineWoods` | **startup** | Add / remove wood sets |
| `NbtCompatEvents.defineMetals` | **startup** | Add / remove metals (casing trims) |
| `NbtCompatEvents.defineDyes` | **startup** | Add / remove dyes |
| `NbtCompatEvents.defineStones` | **startup** | Add / remove stones (+ optional real cobble/gravel/sand) |
| `NbtCompatEvents.defineRecipes` | **server** | Reshape wood / dyed endpoints; artisan dual-register |

Prefer **startup** for indexes so creative tabs and client sprites see them without a later reload. From server scripts you can also call `NbtCompat.defineWoods(...)`, `defineMetals`, `defineDyes`, `defineStones`, `defineRecipes` (same APIs; indexes update for that side).

Restart after startup script changes. `/reload` (or rejoining) picks up server `defineRecipes`.

---

## `defineWoods` (startup)

```js
NbtCompatEvents.defineWoods(event => {
  event.add('biomesoplenty:hellbark', 'biomesoplenty:hellbark_planks')
  event.add('mymod:glow', 'mymod:glow_planks', 'Glow Wood')
  event.remove('minecraft:bamboo')
  // event.clear()
})
```

Woods are an id → planks mapping (no extra blocks). Use this for sets Moonlight / `#minecraft:planks` miss.

---

## `defineMetals` (startup)

```js
NbtCompatEvents.defineMetals(event => {
  event.add('createmoremachines:netherite_alloy', {
    ingot: 'createmoremachines:netherite_alloy',
    block: 'createmoremachines:netherite_alloy_block', // preferred for trim textures
    nugget: 'createmoremachines:netherite_alloy_nugget',
    name: 'Netherite Alloy'
  })
  // shorthand
  event.add('modid:steel', 'modid:steel_ingot')
  event.add('modid:steel', 'modid:steel_ingot', 'modid:steel_block')
  event.remove('minecraft:gold')
})
```

---

## `defineDyes` (startup)

```js
NbtCompatEvents.defineDyes(event => {
  event.add('kubejs:neon', 'kubejs:neon_dye', 0xff00aa)
  event.add('kubejs:neon', 'kubejs:neon_dye', 0xff00aa, 'Neon')
  event.add('kubejs:neon', {
    dye: 'kubejs:neon_dye',
    color: 0xff00aa,   // number, '#ff00aa', or [r,g,b]
    name: 'Neon'
  })
  event.remove('minecraft:black')
})
```

---

## `defineStones` (startup)

```js
NbtCompatEvents.defineStones(event => {
  event.add('mymod:slate', 'mymod:slate_rough', 'Slate')
  event.add('mymod:slate', {
    stone: 'mymod:slate_rough',
    cobble: 'mymod:slate_cobbled', // if set, skip NBT cobble for this stone
    gravel: 'mymod:slate_gravel',
    sand: 'mymod:slate_sand',
    name: 'Slate'
  })
  event.remove('minecraft:netherrack')
})
```

Used for NBT cobble / gravel / sand, Chipped-style stone patterns, and processing chains (Create / Mek when present).

---

## `defineRecipes` (server)

Reshape patterns for all woods / dyes. Keys may be:

| Key | Meaning |
| --- | --- |
| `wood:planks`, `wood:log`, `wood:slab`, … | Per-wood child (Moonlight when available) |
| `dye` | Any registered dye item |
| `dyed:planks` | NBT dyed planks matching the wood+dye being crafted |
| `minecraft:stick`, `#c:ingots` | Fixed item or tag |

Chipped decorative planks count as `wood:planks` for their base wood. Macaw / furniture namespaces are not treated as woods.

### Builder API

```js
event.craftingTable()
  .shaped(['AA', 'AA'], { A: 'wood:planks' })
  .artisan('carpenter')                          // optional — no-op if Artisan missing
  .tool('#artisanworktables:tools/handsaw', 1)   // artisan side only
  .removeCrafting()                              // drop the crafting-table recipe
// .crafting(false)  // same as removeCrafting()
```

Also: `event.removeCrafting('nbtcompat:dyed_slab')` without reshaping.

### Wood endpoints

| Method | Result |
| --- | --- |
| `craftingTable()` | `nbtcompat:crafting_table` |
| `bookshelf()` | `nbtcompat:bookshelf` |
| `nailedLog()`, `centerCutLog()`, `edgeCutLog()`, `damagedLog()`, `plankedLog()`, `overgrownLog()`, `floweringLog()`, `firewoodLog()`, `mixedLog()` | Cut / styled logs |
| `chippedPlanks(kind)` | Shared `nbtcompat:chipped_planks` + kind NBT |
| `chippedPlanksKinds()` | List of kind ids (`vertical_planks`, …) |
| `endpoint(id, resultItem)` | Custom wood endpoint |

### Dyed endpoints

| Method | Result |
| --- | --- |
| `dyedPlanks()`, `dyedStairs()`, `dyedSlab()`, `dyedFence()`, `dyedFenceGate()` | Dyed furniture |
| `dyedDoor()`, `dyedTrapdoor()`, `dyedPressurePlate()`, `dyedButton()` | Same |
| `dyedEndpoint(id, resultItem)` | Custom dyed endpoint |

Chipped **door styles** use datapack recipes under `data/nbtcompat/recipe/dyed_door/{style}.json`. `event.dyedDoor()` only reshapes the vanilla (empty style) door; `dyedDoor(style)` logs that and does the same.

### Example

```js
NbtCompatEvents.defineRecipes(event => {
  const hasArtisan = Platform.isLoaded('artisanworktables')

  event.craftingTable()
    .shaped(['AA', 'AA'], { A: 'wood:planks' })

  const bookshelf = event.bookshelf()
    .shaped(['PPP', 'BBB', 'PPP'], { P: 'wood:planks', B: 'minecraft:book' })
  if (hasArtisan) bookshelf.artisan('carpenter').removeCrafting()

  event.dyedPlanks()
    .shaped(['PPP', 'PDP', 'PPP'], { P: 'wood:planks', D: 'dye' })

  event.dyedStairs()
    .shaped(['#  ', '## ', '###'], { '#': 'dyed:planks' })

  for (const kind of event.chippedPlanksKinds()) {
    event.chippedPlanks(kind).shaped(['P'], { P: 'wood:planks' })
  }
})
```

Roofs, gutters, stone cutting, and most Chipped stone / door style recipes ship as **datapack JSON** (not `defineRecipes`).

**Gutters:** `nbtcompat:rain_gutter` / `nbtcompat:gutter_downspout` store dye in `nbtcompat:dye`. Geometry and metal/water textures come from Macaw Roofs at runtime (not vendored). Bulk-dye Macaw’s undyed `gutter_base` / `gutter_middle` (8 + dye → 8 NBT), recolor, or convert old colored Macaw blocks. Macaw’s 32 colored gutter recipes are disabled while this mod is present.

**Awnings:** `nbtcompat:striped_awning` stores dye the same way. Geometry parents Macaw awning models; only the colored wool stripe is remapped (`{color}_wool`), white stripe stays. Craft from carpets (Macaw `BAB` pattern), recolor with dye, or convert old Macaw colored awnings. Macaw’s 15 colored awning recipes are disabled.

---

## How identity is stored

| Kind | Item component | Block entity |
| --- | --- | --- |
| Wood | `nbtcompat:wood` | `Wood` |
| Dye | `nbtcompat:dye` | `Dye` |
| Stone | `nbtcompat:stone` | `Stone` |
| Chipped plank/stone kind | `nbtcompat:chipped_kind` | `ChippedKind` |
| Roof source | `nbtcompat:source` | `Source` (+ optional dye / stone) |

Client remaps templates / planks sprites from those ids (multiply tint for dyed wood, Chipped templates, gravel/sand, etc.).
