# ARBORESCENCE.md — Primordia

> Arborescence cible du projet. Mise à jour à chaque ajout de fichier structurant.

```
Primordia/
│
├── project.godot                        — Config Godot 4 (renderer, autoloads, display)
├── README.md                            — Stack, lancement, vision
├── STATE.md                             — Résumé vivant cross-session
├── TODO.md                              — Backlog structuré par phase
├── ARBORESCENCE.md                      — Ce fichier
├── .env.example                         — Pas d'API externe
│
├── autoloads/                           — Singletons globaux (déclarés dans project.godot)
│   ├── SimulationClock.gd               — Tick loop, pause, vitesse (0.25x–8x)
│   ├── WorldGrid.gd                     — Grille monde, cellules, nutriments, agents
│   ├── PopulationManager.gd             — Spawn, limites, stats globales par espèce
│   ├── EventLog.gd                      — Log événements simulation (extinctions, pics)
│   └── FilterManager.gd                 — État actif des filtres visuels
│
├── scenes/                              — Scènes Godot (.tscn)
│   ├── World.tscn                       — Scène principale : grille + camera + UI
│   ├── agents/
│   │   ├── Bacterium.tscn               — Scène agent bactérie
│   │   ├── Virus.tscn                   — Scène agent virus
│   │   ├── Herbivore.tscn               — Macro-organisme herbivore
│   │   ├── Carnivore.tscn               — Macro-organisme carnivore
│   │   └── Decomposer.tscn              — Décomposeur (recyclage nutriments)
│   └── ui/
│       ├── HUD.tscn                     — HUD principal (filtres, vitesse, stats rapides)
│       ├── TimeControlBar.tscn          — Pause / play / speed slider
│       ├── StatsPanel.tscn              — Panel stats globales + graphes
│       ├── SpecimenInspector.tscn       — Panel détail d'un agent sélectionné
│       └── DebugOverlay.tscn            — FPS, tick rate, grille debug
│
├── scripts/                             — GDScript logique (.gd)
│   ├── agents/
│   │   ├── Agent.gd                     — Classe de base : stats, cycle de vie, rendu
│   │   ├── AgentBrain.gd                — FSM individuelle : idle/seek/flee/reproduce/die
│   │   ├── SwarmDirector.gd             — IA collective : groupes, migration, émergence
│   │   ├── Bacterium.gd                 — Déplacement brownien, consommation nutriments
│   │   ├── Virus.gd                     — Propagation, infection, mutation
│   │   ├── MacroOrganism.gd             — Herbivore/carnivore, pathfinding, combat
│   │   └── ContaminationSystem.gd       — Calcul propagation, résistance, quarantaine
│   ├── world/
│   │   ├── Cell.gd                      — Données d'une cellule de grille
│   │   ├── NutrientDiffusion.gd         — Diffusion nutriments entre cellules
│   │   └── BiomeGenerator.gd            — Génération procédurale des biomes
│   └── ui/
│       ├── GraphRenderer.gd             — Rendu courbes temps-réel (populations)
│       ├── HeatmapOverlay.gd            — Calcul + rendu heatmap densité/danger
│       └── SpecimenInspectorController.gd — Logique panel détail agent
│
├── shaders/                             — CanvasItem shaders GLSL (.gdshader)
│   ├── cartoon_outline.gdshader         — Outline noir + aplats couleur
│   ├── filter_blood.gdshader            — Overlay sang, vaisseaux, impacts
│   ├── filter_muscles.gdshader          — Anatomique, fibres musculaires
│   ├── filter_bacteria.gdshader         — Bioluminescence, densité bactérienne
│   └── heatmap.gdshader                 — Rendu heatmap couleur (bleu→rouge)
│
├── assets/                              — Ressources statiques
│   ├── fonts/
│   │   └── primordia_ui.ttf             — Police UI (monospace ou organique)
│   ├── icons/
│   │   ├── pause.svg
│   │   ├── play.svg
│   │   └── speed.svg
│   └── audio/                           — Sons ambiance simulation (optionnel)
│
└── ui/                                  — Thème Godot + styles (.tres)
    ├── theme_primordia.tres             — Thème UI global dark
    └── stylebox_panel.tres              — Styleboxes panels stats
```
