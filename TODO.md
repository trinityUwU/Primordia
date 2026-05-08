# TODO.md — Primordia

---

## Phase 1 — Core Engine

- [ ] Initialiser le projet Godot 4 (`project.godot`, dossiers de base)
- [ ] Créer l'autoload `SimulationClock` (tick loop, pause, set_speed)
- [ ] Implémenter la grille monde (`WorldGrid`) : cellules, nutriments, température, humidité
- [ ] Système de coordonnées discrètes ↔ monde 2D
- [ ] Scène principale `World.tscn` avec camera et grille
- [ ] Camera2D multi-échelle : niveaux macro / meso / micro
- [ ] Zoom smooth avec affichage conditionnel des détails
- [ ] UI `TimeControlBar` : pause / play / vitesse (0.25x – 8x)
- [ ] Debug overlay : affichage grille, FPS, tick rate

---

## Phase 2 — Bacteria & Virus

- [ ] Classe de base `Agent` avec stats (vitesse, énergie, âge, métabolisme)
- [ ] Classe `Bacterium` : déplacement brownien, consommation nutriments
- [ ] Classe `Virus` : propagation par contact, taux d'infection, mutation
- [ ] Système de contamination : rayon de propagation, probabilité, résistance hôte
- [ ] Cycle de vie : naissance, reproduction, mort, décomposition
- [ ] Rendu cartoon des agents (CircleShape2D + outline shader)
- [ ] Population manager : spawn initial, limites, stats globales par espèce
- [ ] Propagation de nutriments dans la grille (diffusion simple)

---

## Phase 3 — Macro Organisms & Ecosystems

- [ ] Classe `MacroOrganism` hérite de `Agent` : force, dangerosité, taille
- [ ] Chaîne alimentaire : herbivore / carnivore / omnivore / décomposeur
- [ ] Comportement prédateur/proie (pathfinding simple sur grille)
- [ ] IA individuelle `AgentBrain` : FSM (idle, seek food, flee, reproduce, die)
- [ ] IA collective `SwarmDirector` : groupes, migration, comportements emergents
- [ ] Territorialité et zones d'influence
- [ ] Évolution légère : mutation stats à chaque génération (±X%)
- [ ] Équilibre écosystème : régulation automatique via ressources

---

## Phase 4 — Visuals & Shaders

- [ ] Shader cartoon : outline noir, aplats, palette par espèce
- [ ] Filtre "sang" : overlay rouge, vaisseaux, impact visuel sur morts/combats
- [ ] Filtre "muscles" : shader anatomique, fibres visibles
- [ ] Filtre "bactérien" : overlay bioluminescent, densité de population
- [ ] Effets particules : mort, reproduction, contamination, explosion nutriments
- [ ] Génération procédurale des sprites agents (taille, couleur, forme selon stats)
- [ ] Background world : biomes visuels (aquatique, terrestre, désert)
- [ ] Transitions douces entre filtres (lerp shader params)

---

## Phase 5 — Stats UI & Inspector

- [ ] Panel stats globales : populations par espèce, ressources, taux contamination
- [ ] Graphes temps-réel : courbes de population (style Lotka-Volterra)
- [ ] Specimen inspector : clic sur agent → panel détail (toutes stats, historique)
- [ ] Heatmap overlay : densité population / nutriments / danger
- [ ] Leaderboard espèces : les plus dominantes, les en danger
- [ ] Export snapshot stats (JSON local)
- [ ] Log événements : extinctions, pics de contamination, prédations majeures
