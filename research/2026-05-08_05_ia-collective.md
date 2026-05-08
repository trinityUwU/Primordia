# IA Collective — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : IA collective & comportements émergents
**État** : final
**Sources** :
- Craig Reynolds — Boids (1987), SIGGRAPH paper + red3d.com/cwr/boids/
- Reynolds, C. W. (1999). Steering Behaviors For Autonomous Characters. GDC Proceedings.
- Dorigo, M. & Stützle, T. (2004). Ant Colony Optimization. MIT Press.
- Camazine et al. (2001). Self-Organization in Biological Systems. Princeton University Press.
- Couzin, I.D. et al. (2002). Collective Memory and Spatial Sorting in Animal Groups. J. Theor. Biol.
- Muro, C. et al. (2011). Wolf-pack hunting strategies emerge from simple rules. Behav. Processes.
- Seeley, T. (2010). Honeybee Democracy. Princeton University Press.
- Hart & Moriarty (2006). Behavior Trees for AI. AI Game Programming Wisdom 3.
- Björnsson et al. — Flow field pathfinding for large-scale simulations

---

## Synthèse actionnable pour la simulation

### 1. Boids — Paramètres de référence (Reynolds 1987, calibrés en pratique)

**Trois règles fondamentales :**

| Règle | Description | Poids recommandé |
|---|---|---|
| Séparation | Éviter les voisins trop proches | 1.5 – 2.0 |
| Alignement | Matcher la vélocité moyenne du voisinage | 1.0 |
| Cohésion | Se diriger vers le centre de masse du groupe | 1.0 |

**Rayons de perception typiques (unités du monde) :**
```
separation_radius   : 25–35 px (zone de répulsion forte)
alignment_radius    : 50–75 px (zone de synchronisation)
cohesion_radius     : 75–100 px (zone d'attraction)
// Règle : separation < alignment <= cohesion
```

**Angle de vision :**
- Champ de vision : **270°** (angle mort de 90° derrière l'agent)
- Implémentation : `dot(forward, to_neighbor) > cos(135°)` → `dot > -0.707`

**Voisins considérés :**
- Max 7 ± 2 voisins (recherches sur murmuration d'étourneaux : 6-7 voisins topologiques, pas métriques)
- Optimisation : spatial hash grid ou quadtree — jamais O(n²) au-delà de 100 agents

**Vitesse & forces :**
```
max_speed        : 150–200 px/s
max_force        : 10–20 px/s² (steering force)
min_speed        : 40 px/s (boids ne s'arrêtent pas)
```

**Pipeline de mise à jour :**
```
1. Requête spatiale (voisins dans rayon)
2. Calcul des trois forces
3. Pondération + clamping à max_force
4. Intégration vélocité → position
5. Wrap ou rebond sur les bords
```

**Paramètre clé souvent oublié — le flocking quality index :**
Ratio cohésion/séparation ~ 0.8–1.2 → groupe stable. < 0.5 → dispersion. > 2.0 → collision constante.

---

### 2. Stigmergie & Phéromones

**Principe** : les agents modifient l'environnement, et ces modifications guident les agents suivants. Pas de communication directe.

**Modèle de phéromone — paramètres numériques :**

```
deposit_amount      : 1.0 par passage (normalisé)
evaporation_rate    : 0.01–0.05 par tick (typique : 2% par frame @ 60fps)
diffusion_radius    : 1–3 cellules voisines par tick
diffusion_factor    : 0.1–0.2 (% transféré aux voisines)
max_pheromone       : 10.0 (cap pour éviter saturation)
response_threshold  : 0.1 (en dessous : ignoré)
```

**Types distincts dans Primordia :**
- `PHEROMONE_FOOD` — trail vers la nourriture
- `PHEROMONE_DANGER` — alarme, rayon de diffusion large
- `PHEROMONE_HOME` — retour au nid
- `PHEROMONE_TERRITORY` — marquage territorial (loups)

**Grille de phéromones :**
- Grille 2D indépendante de la grille de collision
- Résolution recommandée : 1 cellule = 16–32 px (pas la pixel-perfect)
- Update sur thread séparé si > 512×512 cellules
- Godot : `Image` + `ImageTexture` pour visualiser en debug

**Formule d'évaporation/diffusion (chaque tick) :**
```python
for cell in grid:
    # Diffusion vers voisins
    for neighbor in cell.neighbors_4:
        delta = cell.value * diffusion_factor / 4
        neighbor.value += delta
        cell.value -= delta
    # Évaporation
    cell.value *= (1.0 - evaporation_rate)
    cell.value = clamp(cell.value, 0, max_pheromone)
```

**Décision de suivi :**
```python
# Probabilité proportionnelle à la concentration
weights = [cell.pheromone ** alpha for cell in candidates]
chosen = weighted_random(candidates, weights)
# alpha = 1.0 (linéaire) à 3.0 (très sensible aux gradients)
```

---

### 3. Comportements de meute — Loups

**Étude de référence : Muro et al. (2011)**
Simulation de chasse de loups à partir de deux règles locales seulement :
1. **Approcher la proie** si à distance > d_chase
2. **S'éloigner de la proie** si à distance < d_repulse (et des autres loups)

**Paramètres Muro :**
```
d_chase   : 300–500 m (échelle réelle) → 150–250 px dans sim
d_repulse : 50–100 m → 25–50 px
speed_wolf : 1.3–1.5× speed_prey
```

**Rôles émergents (pas codés en dur, émergent de la position) :**
- Alpha/Beta : loups en tête → guident par position, pas par statut
- Flanqueurs : convergent latéralement pour encercler
- Rabatteurs : poussent la proie vers le centre

**Territoire :**
- Zone de marquage : rayon 500–2000 m (50–200 unités sim)
- Patrouille : waypoints aléatoires dans le territoire, pas de chemin fixe
- Intrusion : boost d'agressivité si agent étranger détecté dans territoire

**Hiérarchie sociale (FSM état supplémentaire) :**
```
DOMINANT → accès ressources en premier, ignore les subordonnés
SUBMISSIVE → attend, évite les dominants
JUVENILE → suit les adultes, rayon de perception réduit
```

---

### 4. Colonies d'abeilles / fourmis — Intelligence distribuée

**Division du travail (fourmis) :**
- Pas de chef — seuil de réponse individuel variable
- Agent A : seuil bas pour nettoyage → fait le nettoyage avant B
- Agent B : seuil bas pour fourragement → sort chercher nourriture

```python
# Threshold model (Bonabeau et al. 1997)
task_stimulus = environment.get_task_level(task_type)
response_prob = stimulus² / (stimulus² + threshold²)
if random() < response_prob:
    switch_to_task(task_type)
```

**Recrutement par tandem running / trail (fourmis) :**
- Scout trouve ressource → dépose trail de retour
- Intensité du trail ∝ qualité de la ressource
- Renforcement positif : meilleur trail → plus de recrues → trail plus fort

**Abeilles — Danse frétillante (waggle dance) :**
- Distance → durée de la danse (1 sec ≈ 1 km)
- Direction → angle par rapport au soleil
- Qualité → enthousiasme (répétitions)
- Vote distribué : plusieurs scouts → quorum de 15 abeilles sur un site → décision

**Paramètres de quorum :**
```
quorum_threshold  : 15 individus minimum sur une option
scout_ratio       : 5% de la colonie = scouts actifs
inhibition_signal : STOP signal si trop de scouts sur un site (régulation)
```

---

### 5. Murmuration & bancs de poissons

**Étude topologique (Ballerini et al. 2008, étourneaux) :**
- Les étourneaux répondent aux **6-7 voisins les plus proches** (topologique, pas métrique)
- Ce nombre est invariant quelle que soit la densité du groupe
- → Dans le code : ne pas filtrer par rayon mais par rang (les 7 plus proches)

**Bancs de poissons :**
- Zones identiques aux Boids mais + une règle : **attraction vers la lumière/surface** (paramètre bias)
- Vitesse de propagation d'un signal de danger : ~20 ms par individu (quasi-instantané à l'échelle du groupe)
- Modélisation : `ALARM` state → boost séparation × 5, ignorer cohésion pendant 0.5–1.0s

**Paramètres spécifiques poissons :**
```
polarization_threshold : vitesse angulaire < 5°/s → groupe "ordonné"
milling_threshold      : si cohésion élevée + alignement faible → rotation collective
```

---

### 6. FSM pour agents individuels — États classiques en sim

**FSM de base pour faune (7 états) :**
```
IDLE        → attend, scan environnement
WANDER      → déambule (Perlin noise sur heading)
FORAGE      → cherche nourriture (follow pheromone / gradient)
FLEE        → fuite prédateur (boost vitesse, ignorer obstacles)
HUNT        → poursuite proie (approach + encircle)
SLEEP       → repos (cycle jour/nuit, stats régénèrent)
DEAD        → corpse, devient ressource
```

**Transitions clés :**
```
IDLE → WANDER      : timer expires (5–30s random)
IDLE → FLEE        : predator detected in danger_radius
WANDER → FORAGE    : food_pheromone > threshold
FORAGE → IDLE      : food found + collected
HUNT → IDLE        : prey lost (> hunt_timeout) ou trop fatigué
any → DEAD         : hp <= 0
```

**Extension : sous-états (HSM — Hierarchical State Machine) :**
Godot `AnimationTree` + custom `StateMachine` resource → évite l'explosion d'états plats.

---

### 7. Behaviour Trees vs FSM

| Critère | FSM | Behaviour Tree |
|---|---|---|
| Lisibilité | Bien pour < 10 états | Bien pour comportements complexes imbriqués |
| Réutilisabilité | Faible (états liés) | Haute (sous-arbres réutilisables) |
| Priorités | Explicite mais verbeux | Selector node = élégant |
| Debug | Facile | Moyen (traces d'exécution nécessaires) |
| Performance | O(1) par tick | O(log n) selon profondeur |
| Primordia recommandé | Agents simples (insectes, proies) | Agents complexes (loups, hominidés) |

**Règle pratique :**
- < 8 états + transitions simples → **FSM**
- Comportements conditionnels imbriqués + réutilisation entre espèces → **BT**
- Godot : utiliser `GDScript` FSM simple ou plugin [Beehave](https://github.com/bitbra1n/beehave) pour BT

**Structure BT pour loup :**
```
Selector
├── Sequence (Survie)
│   ├── HP < 30% ?
│   └── Flee to safe zone
├── Sequence (Chasse)
│   ├── Prey in sight radius ?
│   ├── Pack size >= 2 ?
│   └── Selector
│       ├── Encircle prey
│       └── Chase prey
├── Sequence (Territoire)
│   ├── Intruder detected ?
│   └── Challenge / Attack
└── Wander
```

---

### 8. Pathfinding pour milliers d'agents

**Comparatif :**

| Méthode | Forces | Limites | Agents cibles |
|---|---|---|---|
| A* individuel | Précis, optimal | O(n×grid) → inutilisable à grande échelle | < 50 agents |
| Navigation Mesh | Rapide, espaces ouverts | Recalcul si terrain dynamique | 50–500 agents |
| Flow Field | Calcul unique → N agents | Mémoire (une grille par destination) | 500–10 000 agents |
| Steering seul (Boids) | Ultra-léger | Pas d'objectif global | > 10 000 agents |

**Flow Field — recommandé pour Primordia :**
```
1. Dijkstra depuis la destination → distance field (coût par cellule)
2. Gradient du champ → vecteur de direction par cellule
3. Chaque agent lit le vecteur de sa cellule → steering force
4. Recalcul uniquement si terrain change (pas chaque frame)
```

**Godot implémentation :**
- `NavigationServer3D` / `NavigationAgent2D` → NavMesh OK pour 100–300 agents
- Flow field custom en GDScript + `TileMap` → meilleur au-delà
- Spatial hash : diviser le monde en cellules de 64px, stocker agents par cellule → voisinage O(1)

**Paramètres flow field :**
```
cell_size        : 32–64 px (trade-off précision/mémoire)
update_interval  : 0.5–2.0s (pas chaque frame)
max_destinations : 10–20 simultanées (une par ressource/nid actif)
```

---

## Détails scientifiques

### Boids — Contexte historique
Craig Reynolds publie "Flocks, Herds and Schools: A Distributed Behavioral Model" au SIGGRAPH 1987. Première démonstration qu'un comportement global complexe émerge de trois règles locales simples sans contrôle centralisé. Le terme "Boids" (contraction de "bird-oid objects") entre dans le lexique de l'IA de jeux vidéo.

L'extension de 1999 ("Steering Behaviors for Autonomous Characters", GDC) ajoute des comportements de steering vectoriel : seek, flee, arrive, pursue, evade, wander, path following, obstacle avoidance — tous compositables.

### Stigmergie — Grassé (1959)
Terme introduit par Pierre-Paul Grassé pour décrire la coordination des termites via des piliers de ciment. Deux formes :
- **Sématectonic stigmergy** : modification physique de l'environnement (terrier, nid)
- **Marker-based stigmergy** : signaux chimiques (phéromones)

La phéromone de piste des fourmis (acide formique + trail pheromone) a une demi-vie de 30–50 minutes en conditions réelles. En simulation, l'évaporation doit être calibrée pour que les trails "récents" restent visibles mais s'effacent quand la ressource est épuisée.

### Ant Colony Optimization (ACO) — Dorigo (1992)
Base mathématique pour les algorithmes de fourmis :
```
τ_ij(t+1) = (1-ρ) × τ_ij(t) + Δτ_ij
```
- τ_ij = phéromone sur arc (i→j)
- ρ = taux d'évaporation (0.01–0.1)
- Δτ_ij = 1/L_k si la fourmi k a utilisé cet arc (L_k = longueur totale du tour)

**Probabilité de sélection d'un chemin :**
```
p_ij = (τ_ij^α × η_ij^β) / Σ(τ_il^α × η_il^β)
```
- α = importance des phéromones (typique : 1.0)
- β = importance de l'heuristique locale (typique : 2.0–5.0)
- η_ij = visibilité = 1/distance

### Murmuration d'étourneaux — résultats expérimentaux
Projet STARFLAG (Rome, 2006–2010) : tracking 3D de vols de 1000–3000 étourneaux.
- Corrélation topologique (7 voisins) explique la propagation ultrarapide des ondes de forme
- Les perturbations se propagent à ~25 m/s dans le groupe (vitesse de l'information > vitesse individuelle)
- Pas de leader identifiable : tout individu peut initier un changement de direction

### Chasse coopérative des loups — mécanismes
Muro et al. (2011) démontrent que l'encerclement de la proie émerge sans communication :
- Les loups maximisent distance aux autres loups ET minimisent distance à la proie
- Le conflit entre ces deux forces produit naturellement l'encerclement
- Population minimale pour chasse efficace : **3 loups**

### Honeybee Democracy — Seeley (2010)
Essaim d'abeilles cherche nouveau nid :
1. ~5% de l'essaim part en reconnaissance
2. Les scouts dansent à leur retour (intensité ∝ qualité du site)
3. Recrutement en cascade jusqu'au quorum (~15 danseuses sur même site)
4. Signal STOP (vibration) inhibe les danseuses des sites perdants
5. Décision : unanimité avant départ (jamais de départ sur vote partiel)

Ce mécanisme est plus robuste que le vote majoritaire et évite les décisions sur des options insuffisamment explorées.

### FSM vs BT — littérature de référence
- Millington & Funge (2009). *Artificial Intelligence for Games*. MK.
- Champandard (2007). *The Behavior Tree Starter Kit*. AI Game Prog. Wisdom 4.
- Isla (2005). *Handling Complexity in Halo 2 AI*. GDC. (première utilisation documentée de BT en jeu AAA)

---

## Notes d'implémentation Godot 4

```gdscript
# Structure agent type pour Primordia
class_name CreatureAgent extends CharacterBody2D

# Paramètres Boids (exportés pour tweaking in-editor)
@export var separation_radius: float = 30.0
@export var alignment_radius: float = 60.0
@export var cohesion_radius: float = 80.0
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var max_speed: float = 180.0
@export var max_force: float = 15.0

# Perception
@export var vision_angle_deg: float = 270.0
@export var max_neighbors: int = 7

# Phéromones
@export var pheromone_deposit: float = 1.0
@export var pheromone_response_threshold: float = 0.1

# FSM state
enum State { IDLE, WANDER, FORAGE, FLEE, HUNT, SLEEP, DEAD }
var current_state: State = State.IDLE
```

**Optimisations critiques pour > 500 agents :**
1. Spatial hash grid (mise à jour chaque frame, query O(1))
2. LOD comportemental : agents hors caméra → update 1x/s au lieu de 60x/s
3. Phéromone grid sur texture GPU (compute shader si Godot 4.1+)
4. Flow field pré-calculé, rechargé uniquement sur changement terrain
