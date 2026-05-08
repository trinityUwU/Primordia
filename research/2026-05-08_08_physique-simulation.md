# Physique de Simulation — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Physique de simulation pour écosystème numérique 2D
**État** : final
**Sources** : Synthèse depuis connaissances scientifiques (WebFetch non disponible dans cette session)

---

## Synthèse actionnable pour la simulation

### Priorités d'implémentation recommandées pour Godot 4

| Priorité | Système | Méthode recommandée | Coût calcul |
|---|---|---|---|
| 1 | Diffusion chimique | Laplacien discret, 5-point stencil | Faible (shader) |
| 2 | Gradient chimique | Différences finies sur grille | Très faible |
| 3 | Nutriments sol/eau | Cellular Automata + diffusion | Faible |
| 4 | Lumière/ombre | Shadowcasting raycast 2D | Moyen |
| 5 | Thermodynamique | Diffusion de chaleur (même algo) | Faible |
| 6 | Fluide simplifié | Shallow Water Equations ou LBM D2Q9 | Moyen-élevé |

**Recommandation centrale** : Tout ce qui est champ scalaire (chimique, thermique, lumineux) partage le même algorithme de diffusion. Implémenter une seule grille générique réutilisable.

---

## Détails scientifiques

### 1. Diffusion Chimique — Loi de Fick

#### Théorie
- **1ère loi de Fick** : flux proportionnel au gradient de concentration
  ```
  J = -D * ∇C
  ```
  J = flux [mol/m²/s], D = coefficient de diffusion [m²/s], ∇C = gradient de concentration

- **2ème loi de Fick** (évolution temporelle) :
  ```
  ∂C/∂t = D * ∇²C
  ```

#### Discrétisation sur grille 2D (5-point stencil)
```
C[x][y](t+1) = C[x][y](t) + D * dt/dx² * (
    C[x+1][y] + C[x-1][y] + C[x][y+1] + C[x][y-1] - 4*C[x][y]
)
```
- `dx` = taille d'une cellule (en mètres ou unités sim)
- `dt` = pas de temps
- **Condition de stabilité numérique** : `D * dt / dx² ≤ 0.25` (schéma explicite FTCS)
  - Au-delà : instabilité numérique → oscillations explosives
  - Alternative stable : schéma implicite (Crank-Nicolson) ou réduire dt

#### Implémentation GDScript / Shader Godot 4
```gdscript
# Mise à jour grille diffusion — à appeler chaque tick
func diffuse_grid(grid: Array, D: float, dt: float, dx: float) -> Array:
    var new_grid = grid.duplicate(true)
    var factor = D * dt / (dx * dx)
    for y in range(1, HEIGHT - 1):
        for x in range(1, WIDTH - 1):
            new_grid[y][x] = grid[y][x] + factor * (
                grid[y][x+1] + grid[y][x-1] +
                grid[y+1][x] + grid[y-1][x] -
                4.0 * grid[y][x]
            )
    return new_grid
```
**Optimisation** : passer ce calcul en compute shader — traite 512×512 en <1ms sur GPU.

---

### 2. Gradient Chimique — Guidage d'Agents

#### Calcul du gradient (différences finies centrées)
```
∇C_x[x][y] = (C[x+1][y] - C[x-1][y]) / (2 * dx)
∇C_y[x][y] = (C[x][y+1] - C[x][y-1]) / (2 * dx)
```
Direction de montée du gradient = direction vers source de nutriment.

#### Guidage chimiotactique d'un agent
```gdscript
func chemotaxis_direction(agent_pos: Vector2i, chem_grid: Array) -> Vector2:
    var x = agent_pos.x
    var y = agent_pos.y
    var grad_x = (chem_grid[y][x+1] - chem_grid[y][x-1]) / 2.0
    var grad_y = (chem_grid[y+1][x] - chem_grid[y-1][x]) / 2.0
    return Vector2(grad_x, grad_y).normalized()
```

#### Pattern biologique réaliste
- Bactéries : **run-and-tumble** — avancer, puis réorienter si gradient décroît
- Probabilité de tumble ∝ `max(0, -dC/dt)` (si concentration baisse → changer direction)
- Pas de navigation directe vers gradient — trop déterministe, pas réaliste

---

### 3. Thermodynamique Cellulaire

#### Modèle discret échange de chaleur
Même équation que diffusion chimique avec coefficient thermique :
```
∂T/∂t = α * ∇²T + Q_sources - Q_pertes
```
- `α` = diffusivité thermique [m²/s]
- `Q_sources` = production métabolique locale
- `Q_pertes` = dissipation (refroidissement passif)

#### Impact sur métabolisme
Loi d'Arrhenius pour taux métabolique :
```
k(T) = A * exp(-Ea / (R * T))
```
Approximation pratique (Q10 rule) :
```
rate(T) = rate_base * Q10^((T - T_ref) / 10.0)
```
- Q10 ≈ 2.0–2.5 pour organismes poïkilothermes
- Doublement du taux métabolique par +10°C
- Plage viable typique : 0°C–45°C selon organisme

#### Implémentation suggérée
```gdscript
const Q10 = 2.0
const T_REF = 20.0  # °C référence

func metabolic_rate(base_rate: float, temperature: float) -> float:
    return base_rate * pow(Q10, (temperature - T_REF) / 10.0)
```

---

### 4. Simulation de Fluides Simplifiée

#### Option A — Shallow Water Equations (recommandé pour 2D aquatique)
Modèle 2D léger pour courants d'eau :
```
∂h/∂t + ∇·(h*u) = 0                          # conservation masse
∂u/∂t + (u·∇)u = -g*∇h + ν*∇²u + f_ext      # conservation quantité mouvement
```
- `h` = hauteur eau, `u` = vitesse, `g` = gravité, `ν` = viscosité
- Solveur semi-implicite (méthode de Stam) : stable à tout dt

#### Option B — Lattice Boltzmann D2Q9 (meilleur pour complexité géométrique)
Grille 2D avec 9 directions de propagation par cellule :
```
Directions : centre + 4 cardinaux + 4 diagonaux
Poids : w0=4/9, w1-4=1/9, w5-8=1/36
```
- Chaque cellule stocke 9 densités de probabilité de particules
- Étape collision (BGK) : relaxation vers équilibre de Maxwell-Boltzmann
  ```
  f_i(t+1) = f_i(t) - (f_i(t) - f_i_eq(t)) / τ
  ```
- Étape propagation : déplacement selon directions
- **Avantages** : parallélisable massivement, gère obstacles naturellement
- **Inconvénient** : mémoire 9x supérieure, implémentation plus complexe

#### Option C — Diffusion seule (suffisant pour micro-organismes)
Pour des organismes microscopiques dans milieu aquatique peu agité : la diffusion seule (Fick) suffit. Les courants peuvent être simulés comme un biais directionnel du coefficient de diffusion.

**Recommandation** : Option C pour prototype, Option A si courants importants, Option B si géométrie complexe (récifs, obstacles).

---

### 5. Cellular Automata pour Écosystèmes

#### Game of Life et variantes
Règles de base (B3/S23) trop simplistes pour écosystème. Variantes utiles :
- **Lenia** (Bert Chan, 2019) : CA continu, noyau de convolution gaussien, produit des comportements proto-cellulaires complexes
  ```
  A(t+1) = clamp(A(t) + dt * (2*G(U(t)) - 1), 0, 1)
  ```
  U = convolution de la grille par noyau K, G = fonction de croissance (gaussienne)
- **SmoothLife** : extension de GoL à densités continues, supporte des "créatures" ressemblant à des organismes

#### Lattice Gas Automata (LGA) — HPP et FHP
- **HPP** (4 directions) : conservation énergie/quantité mouvement, mais anisotropie
- **FHP** (6 directions hexagonales) : isotrope, simule Navier-Stokes correctement
- Transition : LBM (Lattice Boltzmann) = version probabiliste améliorée de LGA

#### CA pour diffusion de nutriments
Règle simple et efficace :
```gdscript
# Règle CA : chaque cellule transfère fraction de ses nutriments aux voisins
func ca_nutrient_step(grid: Array, transfer_rate: float = 0.1) -> Array:
    var new_grid = grid.duplicate(true)
    for y in HEIGHT:
        for x in WIDTH:
            var neighbors = get_4_neighbors(x, y)
            for n in neighbors:
                var delta = grid[y][x] * transfer_rate / 4.0
                new_grid[n.y][n.x] += delta
                new_grid[y][x] -= delta
    return new_grid
```

---

### 6. Diffusion de Nutriments Sol/Eau

#### Coefficients de diffusion réels dans l'eau à 25°C
| Substance | D (m²/s) | D (µm²/ms) sim |
|---|---|---|
| O₂ (oxygène dissous) | 2.1 × 10⁻⁹ | 2.1 |
| CO₂ | 1.9 × 10⁻⁹ | 1.9 |
| Glucose | 6.7 × 10⁻¹⁰ | 0.67 |
| Acides aminés | ~5 × 10⁻¹⁰ | 0.5 |
| NH₄⁺ (ammonium) | 1.9 × 10⁻⁹ | 1.9 |
| Phosphate (HPO₄²⁻) | 7.5 × 10⁻¹⁰ | 0.75 |
| K⁺ | 1.96 × 10⁻⁹ | 1.96 |
| Na⁺ | 1.33 × 10⁻⁹ | 1.33 |

**Dans sol/sédiment** : multiplier D par tortuosité τ² ≈ 0.3–0.5 (diffusion ralentie par obstacles)

#### Consommation par organismes
```gdscript
# Uptake nutriment de Michaelis-Menten
func nutrient_uptake(concentration: float, Vmax: float, Km: float) -> float:
    return Vmax * concentration / (Km + concentration)
```
- Vmax = taux max d'absorption
- Km = concentration à demi-saturation (typique glucose : 0.1–10 µM)

---

### 7. Simulation Lumière/Ombre pour Photosynthèse

#### Shadowcasting 2D discret
Algorithme recommandé : **recursive shadowcasting** (Björn Bergström) ou **digital differential analyzer (DDA)** raycast.

```gdscript
# Propagation lumière simplifiée : atténuation par distance + obstacles
func compute_light_grid(light_sources: Array, obstacles: Array) -> Array:
    var light = grid_zeros()
    for source in light_sources:
        for each cell in radius:
            var ray = cast_ray(source.pos, cell.pos)
            if not ray.blocked:
                var dist = source.pos.distance_to(cell.pos)
                light[cell.y][cell.x] += source.intensity / (dist * dist + 1)
    return light
```

#### Modèle photosynthèse
Courbe de réponse lumineuse (Michaelis-Menten similaire) :
```
P = Pmax * I / (Ik + I)
```
- P = taux de photosynthèse
- I = intensité lumineuse
- Ik = intensité de saturation (typique algues : 50–200 µmol photons/m²/s)
- Inhibition à haute intensité : **photoinhibition** → clamp au-delà d'un seuil

**Atténuation dans l'eau** (loi de Beer-Lambert) :
```
I(z) = I0 * exp(-k * z)
```
- k = coefficient d'extinction (eau claire : 0.03 m⁻¹, eau turbide : 1–5 m⁻¹)
- z = profondeur

---

### 8. Performances — Milliers d'Agents sans Lag

#### ECS (Entity Component System)
Architecture data-oriented : composants contigus en mémoire → cache-friendly.
```
Agent = {position, velocity, energy, species_id, ...}
Stocké en Structure of Arrays (SoA) plutôt que Array of Structures (AoS)
```
- Godot 4 ne dispose pas d'ECS natif mais supporte des patterns similaires via `Array` typés
- Librairie externe : **Godex** (ECS pour Godot 4)
- Alternative : **MultiMeshInstance2D** pour rendu + arrays GDScript pour logique

#### Spatial Hashing
Diviser l'espace en cellules, chaque agent indexé dans sa cellule :
```gdscript
func cell_key(pos: Vector2, cell_size: float) -> Vector2i:
    return Vector2i(int(pos.x / cell_size), int(pos.y / cell_size))

# Recherche voisins = seulement les cellules adjacentes (~9 cellules max)
```
- Complexité recherche : O(1) moyen vs O(n) naïf
- Taille cellule optimale ≈ 2× rayon d'interaction des agents

#### Benchmarks indicatifs (Godot 4, GDScript)
| Agents | Sans optimisation | Avec spatial hash | Avec ECS/SoA |
|---|---|---|---|
| 1 000 | 60 FPS | 60 FPS | 60 FPS |
| 5 000 | ~20 FPS | 55 FPS | 60 FPS |
| 20 000 | <5 FPS | 30 FPS | 55 FPS |
| 100 000 | ingérable | 10 FPS | 30–45 FPS |

**Grilles** : toujours préférer les compute shaders Godot 4 pour diffusion et gradient. Une grille 512×512 mise à jour 10x/sec coûte <0.5ms en compute shader.

#### Chunking et LOD comportemental
- Diviser la carte en chunks 64×64
- Agents hors caméra : update toutes les 10 ticks au lieu de 1
- LOD comportemental : agents lointains = décisions simplifiées

---

### 9. Discrétisation du Temps

#### Tick-based vs Continuous

| Critère | Tick-based | Continuous (delta-time) |
|---|---|---|
| Reproducibilité | Parfaite | Dépend de la framerate |
| Biologie | Naturel (générations) | Artificiel |
| Déterminisme | Total | Partiel |
| Complexité | Simple | Gestion drift |
| Parallélisme | Facile | Race conditions |

**Recommandation pour sim biologique** : tick-based obligatoire.

#### Paramètres tick recommandés
```
tick_rate = 10 Hz (100ms/tick)   → évènements biologiques
render_rate = 60 Hz              → découplé du tick
```
- Tick biologique ≈ 100ms réels = 1 "seconde sim" selon échelle
- Sous-ticks possibles : grille physique update 60Hz, agents update 10Hz

#### Multi-rate simulation
```gdscript
var physics_accumulator: float = 0.0
const PHYSICS_TICK = 1.0 / 60.0  # grille diffusion
const BIO_TICK = 1.0 / 10.0      # agents, métabolisme

func _process(delta: float) -> void:
    physics_accumulator += delta
    while physics_accumulator >= PHYSICS_TICK:
        update_diffusion_grids()
        physics_accumulator -= PHYSICS_TICK
    
    bio_accumulator += delta
    while bio_accumulator >= BIO_TICK:
        update_agents()
        bio_accumulator -= BIO_TICK
```

---

### 10. Valeurs Numériques de Référence

#### Coefficients de diffusion dans l'eau à 25°C (complet)
```
O₂              : 2.10 × 10⁻⁹ m²/s
CO₂             : 1.92 × 10⁻⁹ m²/s
H₂O             : 2.30 × 10⁻⁹ m²/s
Glucose (C6H12O6): 6.73 × 10⁻¹⁰ m²/s
Saccharose      : 5.23 × 10⁻¹⁰ m²/s
Acides aminés   : 4–8 × 10⁻¹⁰ m²/s
ATP             : ~3 × 10⁻¹⁰ m²/s
NH₄⁺            : 1.96 × 10⁻⁹ m²/s
NO₃⁻            : 1.90 × 10⁻⁹ m²/s
PO₄³⁻           : 6.1 × 10⁻¹⁰ m²/s
H⁺ (proton)     : 9.31 × 10⁻⁹ m²/s  ← très rapide
OH⁻             : 5.27 × 10⁻⁹ m²/s
```

#### Conversion pour simulation
Si 1 cellule = 10µm et 1 tick = 100ms :
```
D_sim = D_real * dt / dx²
D_sim(O₂)      = 2.1e-9 * 0.1 / (10e-6)² ≈ 2.1  (adimensionnel)
D_sim(glucose) = 6.73e-10 * 0.1 / (10e-6)² ≈ 0.67
```
Condition stabilité : D_sim ≤ 0.25 → **réduire dt ou augmenter dx**.

#### Paramètres biologiques typiques
```
Bactérie E. coli :
  - Vitesse nage : 20–30 µm/s
  - Taux division : 20–30 min (37°C)
  - Consommation glucose : ~2 × 10⁻¹⁷ mol/s/cellule
  - Km glucose : 0.1–1 µM

Levure :
  - Division : 90 min (30°C)
  - Rayon : 3–5 µm

Algue unicellulaire :
  - Photosynthèse Pmax : 1–5 µmol O₂/mg_chl/h
  - Ik (saturation lumière) : 50–150 µmol photons/m²/s
```

---

## Architecture Recommandée pour Primordia

```
PhysicsWorld
├── ChemicalGrid (compute shader, 512×512 × N couches)
│   ├── Layer 0 : O₂
│   ├── Layer 1 : CO₂
│   ├── Layer 2 : Glucose/Nutriments
│   └── Layer N : extensible
├── ThermalGrid (même shader, paramétrique)
├── LightGrid (raycast 2D, mis à jour 10Hz)
├── FluidField (optionnel, Shallow Water)
└── AgentManager
    ├── SpatialHashMap (lookup O(1))
    ├── AgentPool (pre-allocated, ECS-style)
    └── BehaviorScheduler (tick multi-rate)
```

**Unique grille générique** avec paramètre `D` et `decay_rate` — O₂, CO₂, chaleur, lumière sont des instances du même composant. Réduction massive de duplication code + cohérence comportementale.
