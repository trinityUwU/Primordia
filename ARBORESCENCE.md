# ARBORESCENCE.md — Primordia

> Arborescence réelle du projet. Mise à jour à chaque ajout de fichier structurant.

```
Primordia/
│
├── project.godot                        — Config Godot 4 (renderer, autoloads, display)
├── README.md                            — Stack, lancement, vision
├── STATE.md                             — Résumé vivant cross-session
├── TODO.md                              — Backlog structuré par phase
├── ARBORESCENCE.md                      — Ce fichier
│
├── scripts/
│   ├── autoloads/
│   │   ├── SimulationClock.gd           — Tick loop, pause, vitesse (0.1x–32x)
│   │   └── WorldGrid.gd                 — Chunks infinis, 7 champs chimiques, BIOME_DEFAULTS/REGEN/CAPACITY
│   ├── managers/
│   │   ├── AgentPool.gd                 — Data-oriented agents (PackedFloat32Array), _chunk_counts
│   │   ├── ChunkSpawner.gd              — Spawn écologique filtré par biome
│   │   └── PopulationLOD.gd             — Agrégation hors zone active (counts par chunk)
│   ├── rendering/
│   │   ├── SimRenderer.gd               — MultiMeshInstance2D, culling O(viewport), clustering
│   │   ├── BiomeRenderer.gd             — Flat color + shader procédural par biome
│   │   ├── HeatmapOverlay.gd            — Overlay nutrients/toxins/temperature
│   │   └── DensityFogRenderer.gd        — Halos luminescents chunks agrégés (1 quad/chunk)
│   ├── world/
│   │   ├── WorldCamera.gd               — WASD + scroll zoom + pan, zoom adaptatif
│   │   └── World.gd                     — Scène principale, orchestration
│   └── ui/
│       ├── TimeControlBar.gd            — Pause / play / vitesse UI
│       ├── DebugOverlay.gd              — FPS, tick rate, zoom, coords, O2 production (F1)
│       ├── SpawnControlPanel.gd         — Toggle spawn par type (bacteria/virus/protozoa/plants/fungi)
│       └── BiomeEditor.gd               — Outil peinture biomes in-game
│
├── shaders/
│   ├── agent.gdshader                   — 8 types visuels (gram+/-, spore, virus, dead, protozoa, plant, fungi)
│   ├── biome.gdshader                   — Texturing procédural par biome
│   ├── grid_debug.gdshader              — Grille debug toggle G
│   ├── heatmap.gdshader                 — Rendu heatmap couleur (bleu→rouge)
│   └── density_fog.gdshader             — Bloom radial, couleur dominante, intensité densité
│
├── scenes/
│   ├── World.tscn                       — Scène principale (BiomeRenderer→DensityFogLayer→HeatmapOverlay→AgentLayer)
│   ├── AgentLayer.tscn                  — Container SimRenderer
│   ├── BiomeRenderer.tscn               — Rendu biomes
│   ├── HeatmapOverlay.tscn              — Overlay heatmap
│   ├── DensityFogLayer.tscn             — Rendu density fog LOD
│   └── ui/
│       ├── TimeControlBar.tscn
│       ├── DebugOverlay.tscn
│       ├── SpawnControlPanel.tscn
│       └── BiomeEditor.tscn
│
└── research/                            — 10 fichiers de recherche scientifique Phase 0
```
