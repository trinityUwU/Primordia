# ARBORESCENCE.md — Primordia
> Mise à jour : 2026-05-09

```
Primordia/
├── project.godot                          # Godot 4.6, OpenGL 3.3 Compat, MainMenu scène principale
├── icon.svg
├── STATE.md                               # État vivant cross-session
├── TODO.md                                # Tâches en cours + backlog
├── ARBORESCENCE.md                        # Ce fichier
├── README.md                              # Lancement, stack, ports
├── .env.example
│
├── tools/
│   └── eco_sim.py                         # Simulation Python écologie (paliers 500/2000/5000/10000 ticks)
│
├── research/                              # 10 docs de recherche scientifique Phase 0
│   ├── 2026-05-08_01_microbiologie-bacterienne.md
│   ├── 2026-05-08_02_virologie.md
│   ├── 2026-05-08_03_epidemiologie.md
│   ├── 2026-05-08_04_ecologie-chaine-alimentaire.md
│   ├── 2026-05-08_05_ia-collective.md
│   ├── 2026-05-08_06_genetique-evolution.md
│   ├── 2026-05-08_07_anatomie-fonctionnelle.md
│   ├── 2026-05-08_08_physique-simulation.md
│   ├── 2026-05-08_09_parasitisme-symbiose.md
│   └── 2026-05-08_10_references-jeux-simulation.md
│
├── scenes/
│   ├── MainMenu.tscn                      # Scène d'entrée — menu principal
│   ├── World.tscn                         # Scène de jeu principale
│   ├── AgentLayer.tscn                    # Conteneur SimRenderer + ChunkSpawner
│   ├── BiomeRenderer.tscn                 # CanvasLayer(-10), full-screen biome shader
│   ├── TerritoryOverlay.tscn              # Overlay zones par type d'entité
│   ├── HeatmapOverlay.tscn                # Heatmap nutrients/toxins/temperature
│   ├── DensityFogLayer.tscn               # Halos densité hors zone active
│   └── ui/
│       ├── TimeControlBar.tscn            # Barre pause/vitesse bas d'écran
│       ├── DebugOverlay.tscn              # F1 — FPS, population, O2/CO2, coords
│       ├── SpawnControlPanel.tscn         # Panel entités (spawn + visibility + territoire)
│       ├── BiomeEditor.tscn               # E — peinture biomes in-game
│       ├── TerritoryInfoPanel.tscn        # Panel flottant clic zone territoire
│       ├── InGameHUD.tscn                 # CanvasLayer(20) — autosave status
│       └── PauseMenu.tscn                 # CanvasLayer(50) — Escape in-game
│
├── scripts/
│   ├── autoloads/
│   │   ├── SaveManager.gd                 # Slots sauvegarde, autosave, emergence_mode persisté
│   │   ├── SimulationClock.gd             # Tick loop 10Hz, pause, vitesse
│   │   └── WorldGrid.gd                   # Chunks infinis, 7 champs chimiques, biomes, regen, CO2 implicite
│   ├── managers/
│   │   ├── AgentPool.gd                   # Tous les agents PackedFloat32Array, FSM, division, mort
│   │   ├── ChunkSpawner.gd                # Spawn écologique, emergence_mode, seed_world
│   │   └── PopulationLOD.gd               # Agrégation counts hors zone active
│   ├── rendering/
│   │   ├── BiomeRenderer.gd               # Texture 128×128, uniforms caméra → shader biome
│   │   ├── SimRenderer.gd                 # MultiMeshInstance2D, spatial hash, clustering, tooltip
│   │   ├── TerritoryOverlay.gd            # MeshInstance2D pool, zones par type
│   │   ├── HeatmapOverlay.gd              # MultiMesh heatmap fields
│   │   └── DensityFogRenderer.gd          # Halos par chunk agrégé
│   ├── world/
│   │   ├── World.gd                       # Scène principale, wiring signals
│   │   └── WorldCamera.gd                 # Camera2D WASD + zoom + pan
│   └── ui/
│       ├── MainMenu.gd                    # Menu principal, panels slide, animations stagger/hover
│       ├── PauseMenu.gd                   # Pause in-game, settings autosave + emergence toggle
│       ├── InGameHUD.gd                   # Autosave flash label
│       ├── SpawnControlPanel.gd           # Toggle spawn/visibility/territoire par type, counts
│       ├── BiomeEditor.gd                 # Peinture biomes, brush size
│       ├── TerritoryInfoPanel.gd          # Stats chunk cliqué (total + visibles)
│       ├── DebugOverlay.gd                # Stats temps réel (pop, O2, CO2 local, net)
│       └── TimeControlBar.gd              # Pause/play/vitesse
│
├── shaders/
│   ├── biome.gdshader                     # Voronoi jitter + eau animée world-space
│   ├── agent.gdshader                     # 8 types visuels (gram+/-, spore, virus, dead, protozoa, plant, fungi)
│   ├── territory.gdshader                 # Zones territoires pulsantes (MeshInstance2D)
│   ├── density_fog.gdshader               # Halos bloom par chunk agrégé
│   ├── heatmap.gdshader                   # Overlay champs chimiques
│   ├── menu_noise.gdshader                # Bruit fond MainMenu
│   ├── grid_debug.gdshader                # Grille debug (G)
│   ├── bacterium.gdshader                 # (legacy)
│   └── virus.gdshader                     # (legacy)
│
└── addons/
    └── simple-gui-transitions/            # Plugin transitions UI (v0.5.0, godot-4 branch)
```
