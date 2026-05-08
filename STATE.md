# STATE.md — Primordia
> Résumé vivant cross-session. Dernière mise à jour : 2026-05-08

---

## Current State

Phase 1 et Phase 2 terminées et fonctionnelles. Le jeu tourne avec des bactéries et virus simulés en temps réel, monde infini par chunks, rendu MultiMesh GPU, performances correctes.

**Dernier état testé** : ~800 agents, 60fps à x1, ~40fps à x16 (à confirmer après dernier fix). Clustering visuel + tooltip hover implémentés mais pas encore testés.

---

## Active Features

- **SimulationClock** : tick loop 10Hz, pause/play, vitesses 0.1x→32x, MAX_TICKS_PER_FRAME=4
- **WorldGrid** : monde infini par chunks 32×32 cellules (256×256px), 7 champs chimiques (nutrients/water/temperature/oxygen/ph/toxins/light), diffusion Fick wall-clock 0.1s
- **AgentPool** : data-oriented, PackedFloat32Array, zéro Node2D par agent, MAX=3000, stagger TICK_STRIDE=2
  - Bactéries : chimiotaxie run-and-tumble, division avec mutation génomique, sporulation, gram+/-
  - Virus : mouvement brownien, propagation par contact, infection, lifetime
  - Cadavres : 300 ticks de decay avec fade visuel
- **ChunkSpawner** : spawn dans 800px autour caméra, règles écologiques (nutrients > 0.1, densité < 2/chunk), throttlé 10 ticks
- **SimRenderer** : MultiMeshInstance2D (1 draw call GPU), culling viewport, clustering 24px, tooltip hover
- **WorldCamera** : WASD + flèches + scroll zoom + pan clic milieu, zoom adaptatif au viewport
- **TimeControlBar** : pause/play/vitesse UI bas d'écran
- **DebugOverlay** : FPS, tick rate, zoom, coords souris (F1)
- **Grille debug** : toggle G

---

## In Progress

- Vérification FPS à x16/x32 après dernier fix (dirty flag + MAX_TICKS 4)
- Clustering tooltip : pas encore testé visuellement

---

## Known Issues

- Les UID Godot dans les .tscn sont invalides (warnings inoffensifs au lancement)
- Population affiche "0" dans le debug overlay (non branché à AgentPool)

---

## Architecture critique — à lire en session

### Stack
- Godot 4.6 GDScript pur, zéro dépendance externe
- Lancement : `godot .` dans `/home/trinity/Documents/DEVS/Primordia`

### Autoloads (ordre de chargement)
1. `SimulationClock` — tick loop
2. `WorldGrid` — chunks infinis
3. `AgentPool` — tous les agents en PackedFloat32Array
4. `ChunkSpawner` — spawn écologique

### Données agents (AgentPool)
Chaque agent = index i dans des tableaux plats :
- `pos_x[i], pos_y[i]` — position monde
- `dir_x[i], dir_y[i]` — direction
- `energy[i], speed[i], size_arr[i], metabolism[i]`
- `division_threshold[i], mutation_rate[i], resistance[i], virulence[i]`
- `age[i], max_age[i], agent_type[i]` — 0=bacterium, 1=virus
- `flags[i]` — bitmask : FLAG_ALIVE=1, FLAG_GRAM_POS=2, FLAG_SPORE=4
- `dead_timer[i]` — 300 ticks decay cadavre
- `run_timer[i], spore_timer[i]`

### WorldGrid chunks
- Chunk = Vector2i(cx, cy), world pos → chunk : `floor(pos / 256.0)`
- Champs par chunk : Dictionary { "fields": {key: Array[float] 1024 cells}, "last_active": float }
- Éviction après 300s inactivité
- `get_cell_value(wx, wy, key)` / `set_cell_value(wx, wy, key, val)` avec coords globales

### Rendu
- `SimRenderer` (Node2D dans AgentLayer) : MultiMeshInstance2D + shader `agent.gdshader`
- Culling viewport, `visible_instance_count` dynamique
- Clustering : cellule 24px écran, > 3 agents → cercle groupé, tooltip au hover
- `_dirty` flag dans AgentPool → rendu seulement si simulation a tiqué

### Fichiers clés
```
scripts/autoloads/SimulationClock.gd
scripts/autoloads/WorldGrid.gd
scripts/managers/AgentPool.gd
scripts/managers/ChunkSpawner.gd
scripts/rendering/SimRenderer.gd
scripts/world/WorldCamera.gd
scripts/world/World.gd
scripts/ui/TimeControlBar.gd
scripts/ui/DebugOverlay.gd
shaders/agent.gdshader
scenes/World.tscn
scenes/AgentLayer.tscn
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
