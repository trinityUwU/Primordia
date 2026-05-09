# STATE.md — Primordia
> Résumé vivant cross-session. Dernière mise à jour : 2026-05-09

---

## Current State

Phases 0→3c fonctionnelles. 5 types d'entités simulés. Menu principal + système de sauvegarde complets. Équilibre écologique en cours de stabilisation (O2/CO2, spawn conditionnel).

**Dernier commit** : `342c36a` — équilibre écologique + eco_sim.py + menu/saves

**En attente de test** : Natural Emergence Mode (spawn conditionnel), stabilité O2 avec nouveau buffer atmosphérique, PauseMenu toggle emergence.

---

## Active Features

### Simulation
- **SimulationClock** : tick loop 10Hz, pause/play, vitesses 0.1x→32x, MAX_TICKS_PER_FRAME=4
- **WorldGrid** : monde infini chunks 32×32 cellules (256×256px), 7 champs chimiques
  - `BIOME_REGEN` O2 : GRASS=0.040, WOOD=0.055, EARTH=0.010, WATER=0.018, ROCK=0.008 (tous les 30 ticks)
  - `BIOME_REGEN_CAP` O2 : GRASS=0.45, WOOD=0.55, EARTH=0.26
  - Buffer atmosphérique : O2 drift vers 0.21 (+0.02/30ticks si < 0.21)
  - CO2 implicite : `co2 = 1.0 - o2` — pas de champ dédié
  - Regen sur TOUS les chunks (pas seulement actifs), toxins dégradent -0.002/30ticks
- **AgentPool** : data-oriented PackedFloat32Array, SOFT_CAP=8000, TICK_STRIDE=2
  - Bacteria: metabolism=0.010, uptake=0.018, division_threshold=1.2, max_age=3000
    - O2 : read-only (stress check), pas d'écriture — WorldGrid gère l'équilibre
    - Mort hypoxie si O2 < 0.10
  - Virus : brownien, propagation contact, lifetime
  - Protozoa : FSM IDLE→SEEK→HUNT→REPRODUCE, sense_radius=90, metabolism=0.006, division_threshold=2.5
  - Plantes : photosynthèse, spread timer 250-600 ticks, phytoremediation toxines
  - Fungi : décomposeurs, metabolism=0.003, spread si nutrients > 0.2
- **ChunkSpawner** : `emergence_mode: bool` — si true, spawn seulement si nutrients≥0.25 + O2≥0.18 + water≥0.20 + temp 10-40°C + randf() < 0.002
  - Mode seeded (défaut) : seed 50 bactéries + 4 protozoa + 15 plantes + 12 fungi au démarrage
- **BIOME_CAPACITY** : [bacteria, virus, protozoa, plant, fungi] par chunk
  - GRASS: [30,10,6,6,4] — EARTH: [20,8,4,4,3] — WOOD: [35,8,5,5,8]
- **PopulationLOD** : zone active = individus, hors zone = counts agrégés par chunk

### Rendu
- **BiomeRenderer** : CanvasLayer(-10) + ColorRect full-screen, shader Voronoi jitter (frontières organiques), eau animée (caustics, ondulations, surface wave) en world-space, `time` uniform
- **SimRenderer** : MultiMeshInstance2D, culling O(viewport) spatial hash, clustering 24px, tooltip
  - Zoom < 0.8 → agents cachés, max 1000 à l'écran
- **TerritoryOverlay** : MeshInstance2D pool, zones par type d'entité, shader animé pulsant
- **DensityFogRenderer** : halos par chunk agrégé
- **HeatmapOverlay** : nutrients/toxins/temperature (toggle H)

### UI & Menus
- **MainMenu** : scène d'entrée, animations stagger/slide, panels New Game / Load Game / Settings
  - Slide depuis droite, dimming menu central, hover buttons
- **SaveManager** (autoload) : slots illimités `user://saves/`, autosave Timer, persistence emergence_mode
- **InGameHUD** : autosave status flash (CanvasLayer 20)
- **PauseMenu** : Escape in-game, Resume/Settings/Exit, toggle Natural Emergence Mode, autosave interval slider
- **SpawnControlPanel** : toggle spawn + visibilité + territoire par type, counts live
- **BiomeEditor** : toggle E, peinture biomes, brush size scroll
- **DebugOverlay** : F1, FPS/ticks/population/O2 net/O2 local+CO2 local sous curseur
- **TerritoryInfoPanel** : clic zone → total agents + visibles à l'écran par type

---

## In Progress / Pending

- **O2 stabilisation** : buffer atmosphérique +0.02/30ticks — à valider in-game (O2 devrait tenir 0.19-0.23)
- **Natural Emergence Mode** : implémenté, à tester (menu → Settings → toggle)
- **Équilibre Lotka-Volterra** : oscillation bactéries/protozoa visible en simulation, à confirmer in-game
- **load_save ne charge pas les parties** : bug UI à investiguer (saves existent bien dans user://)

---

## Known Issues

- UIDs Godot invalides dans .tscn (warnings inoffensifs)
- Load Game panel : saves parfois non affichées (race condition queue_free/populate — await process_frame ajouté)
- O2 déficit persistant à investiguer avec les nouveaux paramètres

---

## Architecture critique

### Stack
- Godot 4.6 GDScript pur, OpenGL 3.3 Compatibility
- Lancement : `godot .` dans `/home/trinity/Documents/DEVS/Primordia`
- Scène principale : `MainMenu.tscn` → `World.tscn`

### Autoloads (ordre)
1. `SaveManager` — slots, autosave, persistence
2. `SimulationClock` — tick loop
3. `WorldGrid` — chunks + biomes + champs chimiques
4. `AgentPool` — tous les agents PackedFloat32Array
5. `ChunkSpawner` — spawn écologique
6. `PopulationLOD` — agrégation hors zone

### Données agents (AgentPool)
`pos_x/y, dir_x/y, energy, speed, size_arr, metabolism, division_threshold, mutation_rate, resistance, virulence, age, max_age, agent_type, flags (ALIVE=1, GRAM_POS=2, SPORE=4), dead_timer, run_timer, spore_timer, brain_state, target_i, sense_radius`

### WorldGrid chunks
- Chunk coords : `floor(world_pos / 256.0)`
- Champs : 7 × Array[float] 1024 cellules (32×32)
- Éviction après 300s, biome_type jamais évicté
- CO2 implicite : `1.0 - oxygen`

### Fichiers clés
```
scripts/autoloads/SaveManager.gd
scripts/autoloads/SimulationClock.gd
scripts/autoloads/WorldGrid.gd
scripts/managers/AgentPool.gd
scripts/managers/ChunkSpawner.gd
scripts/managers/PopulationLOD.gd
scripts/rendering/SimRenderer.gd
scripts/rendering/BiomeRenderer.gd
scripts/rendering/TerritoryOverlay.gd
scripts/rendering/HeatmapOverlay.gd
scripts/rendering/DensityFogRenderer.gd
scripts/world/World.gd, WorldCamera.gd
scripts/ui/MainMenu.gd, PauseMenu.gd, InGameHUD.gd
scripts/ui/SpawnControlPanel.gd, BiomeEditor.gd
scripts/ui/TerritoryInfoPanel.gd, DebugOverlay.gd
shaders/biome.gdshader, agent.gdshader, territory.gdshader
shaders/density_fog.gdshader, heatmap.gdshader, menu_noise.gdshader
tools/eco_sim.py  ← simulation Python écologie (paliers 500/2000/5000/10000 ticks)
scenes/World.tscn, MainMenu.tscn
```

### Décisions architecturales majeures
- Monde infini chunks (pas grille fixe)
- Data-oriented AgentPool (pas Node2D par agent) — x10-100 perf
- MultiMeshInstance2D — 1 draw call GPU
- Diffusion wall-clock 0.1s découplée du tick rate
- CO2 implicite (1-O2) — pas de champ dédié, zéro overhead
- O2 write-only par WorldGrid (agents lisent, n'écrivent pas) — stabilité garantie
- Voronoi jitter biome shader — frontières organiques seam-free
- Eau dans biome shader full-screen (world-space) — seamless, pas de sprites individuels
- Natural Emergence Mode — spawn conditionnel environnemental
- SaveManager autoload avec slots, autosave, emergence_mode persisté
