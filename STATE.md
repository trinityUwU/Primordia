# STATE.md — Primordia
> Résumé vivant cross-session. Dernière mise à jour : 2026-05-09

---

## Current State

Phases 1, 2, 3b et 3c terminées et fonctionnelles. 5 types d'entités simulés (bactéries, virus, protozoaires, plantes, champignons), monde infini par chunks avec biomes différenciés, rendu MultiMesh GPU, LOD simulation + rendu densité fog.

**Dernier état testé** : écologie en cours de validation in-game (chaîne alimentaire, production O2 visible). MAX_AGENTS dynamique ~8000 SOFT_CAP sur budget 4GB RAM.

---

## Active Features

- **SimulationClock** : tick loop 10Hz, pause/play, vitesses 0.1x→32x, MAX_TICKS_PER_FRAME=4
- **WorldGrid** : monde infini par chunks 32×32 cellules (256×256px), 7 champs chimiques (nutrients/water/temperature/oxygen/ph/toxins/light), diffusion Fick wall-clock 0.1s
  - `BIOME_DEFAULTS` : valeurs initiales réalistes par biome (nutrients, water, temp, O2, pH, toxins, light)
  - `BIOME_REGEN` : taux et caps de régénération par biome (forêt régénère nutrients vite, roche stérile, etc.)
  - Regen tourne sur TOUS les chunks, pas seulement actifs
- **AgentPool** : data-oriented, PackedFloat32Array, zéro Node2D par agent, MAX dynamique RAM-based (~8000), TICK_STRIDE=2
  - Bactéries : chimiotaxie run-and-tumble, division avec mutation génomique, sporulation, gram+/-
  - Virus : mouvement brownien, propagation par contact, infection, lifetime
  - Cadavres : 300 ticks de decay avec fade visuel
  - Protozoaires : FSM IDLE→SEEK→HUNT→REPRODUCE, prédateurs bactéries, sense_radius 200px, metabolism 0.002, division_threshold 1.2 (2 kills)
  - Plantes : photosynthèse (light+water→nutrients+O2), spread every 100-300 ticks, O2 production visible debug
  - Champignons : décomposeurs, spread conditionné nutrients > 0.4 (proxy dead matter)
- **ChunkSpawner** : spawn dans 800px autour caméra, filtre par biome (plantes light>0.15, champignons nutrients>0.1, pas de spawn sur roche)
- **PopulationLOD** (autoload) : zone active = individus, hors zone = counts agrégés par chunk
- **SimRenderer** : MultiMeshInstance2D (1 draw call GPU), culling O(viewport) via spatial hash AgentPool, `_rebuild_spatial` every 2 ticks, clustering 24px, tooltip hover
- **DensityFogRenderer** : halos luminescents par chunk agrégé (1 quad/chunk), bloom shader, couleur par type dominant, intensité par densité
- **Carrying capacity** : `WorldGrid.BIOME_CAPACITY` — max agents par type par chunk, scale dynamique selon nutrients. `_chunk_counts` tracker dans AgentPool pour tous spawns/divisions/reproductions
- **WorldCamera** : WASD + flèches + scroll zoom + pan clic milieu, zoom adaptatif au viewport
- **TimeControlBar** : pause/play/vitesse UI bas d'écran
- **DebugOverlay** : FPS, tick rate, zoom, coords souris (F1), production O2 par chunk visible
- **SpawnControlPanel** : toggle buttons par type (bacteria, virus, protozoa, plants, fungi)
- **BiomeEditor** : outil peinture in-game, palette biomes, raccourci clavier
- **HeatmapOverlay** : nutrients/toxins/temperature (toggle)
- **Grille debug** : toggle G

---

## In Progress

- Validation de l'équilibre écologique in-game (chaîne alimentaire, production O2 visible)

---

## Known Issues

- Les UID Godot dans les .tscn sont invalides (warnings inoffensifs au lancement)

---

## Architecture critique — à lire en session

### Stack
- Godot 4.6 GDScript pur, zéro dépendance externe
- Lancement : `godot .` dans `/home/trinity/Documents/DEVS/Primordia`

### Autoloads (ordre de chargement)
1. `SimulationClock` — tick loop
2. `WorldGrid` — chunks infinis + biome defaults/regen/capacity
3. `AgentPool` — tous les agents en PackedFloat32Array + _chunk_counts
4. `ChunkSpawner` — spawn écologique filtré par biome
5. `PopulationLOD` — agrégation hors zone active

### Données agents (AgentPool)
Chaque agent = index i dans des tableaux plats :
- `pos_x[i], pos_y[i]` — position monde
- `dir_x[i], dir_y[i]` — direction
- `energy[i], speed[i], size_arr[i], metabolism[i]`
- `division_threshold[i], mutation_rate[i], resistance[i], virulence[i]`
- `age[i], max_age[i], agent_type[i]` — 0=bacterium, 1=virus, 2=protozoa, 3=plant, 4=fungi
- `flags[i]` — bitmask : FLAG_ALIVE=1, FLAG_GRAM_POS=2, FLAG_SPORE=4
- `dead_timer[i]` — 300 ticks decay cadavre
- `run_timer[i], spore_timer[i]`

### WorldGrid chunks
- Chunk = Vector2i(cx, cy), world pos → chunk : `floor(pos / 256.0)`
- Champs par chunk : Dictionary { "fields": {key: Array[float] 1024 cells}, "last_active": float }
- Éviction après 300s inactivité (biome_type jamais évicté)
- `get_cell_value(wx, wy, key)` / `set_cell_value(wx, wy, key, val)` avec coords globales
- `BIOME_DEFAULTS` : valeurs initiales par biome
- `BIOME_REGEN` : taux + caps par biome, appliqué sur tous chunks chaque tick
- `BIOME_CAPACITY` : max par type d'agent par chunk, scale avec nutrients

### Rendu
- `SimRenderer` (Node2D dans AgentLayer) : MultiMeshInstance2D + shader `agent.gdshader`
  - Culling O(viewport) via spatial hash, `_rebuild_spatial` every 2 ticks
  - Clustering : cellule 24px écran, > 3 agents → cercle groupé, tooltip hover
  - `_dirty` flag dans AgentPool → rendu seulement si simulation a tiqué
- `DensityFogRenderer` : agrège PopulationLOD, 1 quad par chunk hors zone, shader `density_fog.gdshader`
  - Bloom radial, couleur dominante, intensité proportionnelle à la densité
- Shader `agent.gdshader` : 8 types visuels (gram+, gram-, spore, virus, dead, protozoa, plant, fungi)
- Scene order dans World.tscn : BiomeRenderer → DensityFogLayer → HeatmapOverlay

### Fichiers clés
```
scripts/autoloads/SimulationClock.gd
scripts/autoloads/WorldGrid.gd
scripts/managers/AgentPool.gd
scripts/managers/ChunkSpawner.gd
scripts/managers/PopulationLOD.gd
scripts/rendering/SimRenderer.gd
scripts/rendering/BiomeRenderer.gd
scripts/rendering/HeatmapOverlay.gd
scripts/rendering/DensityFogRenderer.gd
scripts/world/WorldCamera.gd
scripts/world/World.gd
scripts/ui/TimeControlBar.gd
scripts/ui/DebugOverlay.gd
scripts/ui/SpawnControlPanel.gd
scripts/ui/BiomeEditor.gd
shaders/agent.gdshader
shaders/biome.gdshader
shaders/grid_debug.gdshader
shaders/heatmap.gdshader
shaders/density_fog.gdshader
scenes/World.tscn
scenes/AgentLayer.tscn
scenes/BiomeRenderer.tscn
scenes/HeatmapOverlay.tscn
scenes/DensityFogLayer.tscn
scenes/ui/TimeControlBar.tscn
scenes/ui/DebugOverlay.tscn
scenes/ui/SpawnControlPanel.tscn
scenes/ui/BiomeEditor.tscn
research/  ← 10 fichiers de recherche scientifique Phase 0
```

---

## Décisions architecturales majeures prises

- **Monde infini chunks** au lieu de grille fixe (décision session 2026-05-08)
- **Data-oriented AgentPool** au lieu de Node2D par agent — gain x10-100 perf
- **MultiMeshInstance2D** au lieu de _draw() batch — 1 draw call GPU
- **Diffusion wall-clock** découplée du tick rate (0.1s fixe)
- **Wrap-around supprimé** — monde vraiment infini, pas toroïdal
- **Godot 4 pur** — pas d'éditeur requis, tout généré en fichiers texte
- **Per-chunk carrying capacity** (BIOME_CAPACITY) au lieu de cap global — équilibre écologique local, scale avec nutrients
- **Density fog LOD** : hors zone active, chunks rendus comme halos (1 quad/chunk) via DensityFogRenderer — permet O(viewport) pur côté rendu sans sacrifier la lisibilité macro
- **Fungi dead scan O(n) remplacé** par proxy nutrients > 0.4 — évite le scan complet des agents morts
- **Toxin production réduite 16x** (0.003/tick) + dégradation 10x plus rapide (0.002/regen) — évite empoisonnement permanent du monde
