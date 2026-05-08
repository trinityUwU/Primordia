# Écologie & Chaîne Alimentaire — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Écologie & chaîne alimentaire
**État** : final
**Sources** :
- Lindeman, R.L. (1942). "The trophic-dynamic aspect of ecology." *Ecology* 23(4):399–417
- Lotka, A.J. (1925). *Elements of Physical Biology*. Williams & Wilkins.
- Volterra, V. (1926). "Fluctuations in the abundance of a species considered mathematically." *Nature* 118:558–560
- Pimm, S.L. (1982). *Food Webs*. Chapman & Hall.
- Terborgh, J. et al. (2001). "Ecological Meltdown in Predator-Free Forest Fragments." *Science* 294:1923–1926
- Hairston, N.G., Smith, F.E., Slobodkin, L.B. (1960). "Community structure, population control, and competition." *Am. Naturalist* 94:421–425
- De Angelis, D.L. (1992). *Dynamics of Nutrient Cycling and Food Webs*. Springer.
- Whittaker, R.H. (1975). *Communities and Ecosystems*. Macmillan.

---

## Synthèse actionnable pour la simulation

### 1. Architecture de la chaîne alimentaire

| Niveau | Rôle | Exemples | Énergie disponible |
|--------|------|----------|--------------------|
| Niveau 0 — Décomposeurs | Recyclage matière organique morte | Champignons, bactéries, vers de terre | Reçoivent ~90% de l'énergie non transférée |
| Niveau 1 — Producteurs | Photosynthèse / chimiosynthèse | Plantes, algues, phytoplancton | 100% (base) |
| Niveau 2 — Consommateurs primaires | Herbivores | Lapins, insectes, zooplancton | ~10% de N1 |
| Niveau 3 — Consommateurs secondaires | Carnivores / omnivores | Renards, petits poissons | ~1% de N1 |
| Niveau 4 — Consommateurs tertiaires | Grands prédateurs | Loups, aigles, requins | ~0.1% de N1 |
| Niveau 5 — Supraprédateurs | Apex prédators | Orcas, grands félins | ~0.01% de N1 |

**Implication simulation** : pour supporter 1 loup (N4), il faut ~10 000 unités d'énergie végétale (N1). Ratio proies/prédateur typique : **10:1 à 100:1** selon l'écosystème.

### 2. Règle des 10% — Loi de Lindeman

- **Principe** : seul ~10% de l'énergie d'un niveau trophique est transférée au niveau supérieur
- **90% restants** : chaleur (respiration), excrétion, matière non digestible, décomposition
- **Efficacité réelle** : varie entre **5% et 20%** selon l'espèce et l'écosystème
  - Écosystèmes marins : 10–15% (phytoplancton → zooplancton très efficace)
  - Forêts tempérées : 5–10% (cellulose difficile à digérer)
  - Herbivores ruminants : ~15% (fermentation microbienne)
  - Carnivores : ~20% (protéines plus assimilables)

```
Biomasse typique (g/m²) :
  Plantes      : 200–2000 g/m²
  Herbivores   : 10–150 g/m²
  Carnivores 1 : 1–15 g/m²
  Carnivores 2 : 0.1–1.5 g/m²
```

**Pour Primordia** : chaque entité consommant une unité de nourriture ne récupère que 10–20% en énergie utilisable. Le reste est "perdu" (chaleur, déchets → nourrit décomposeurs).

### 3. Équations de Lotka-Volterra

#### Équation proie (dx/dt)
```
dx/dt = αx - βxy

x  = taille population proies
α  = taux de croissance intrinsèque proies (naissances nettes sans prédateur)
β  = taux de prédation (efficacité capture × rencontres)
xy = interactions proie-prédateur
```

#### Équation prédateur (dy/dt)
```
dy/dt = δxy - γy

y  = taille population prédateurs
δ  = efficacité conversion proies en naissances prédateurs
γ  = taux de mortalité intrinsèque prédateurs (sans nourriture)
xy = interactions proie-prédateur
```

#### Points d'équilibre
```
Équilibre trivial     : (0, 0) — extinction totale
Équilibre non-trivial : x* = γ/δ,  y* = α/β
```

#### Valeurs typiques pour la faune tempérée
| Paramètre | Symbole | Valeur typique | Notes |
|-----------|---------|----------------|-------|
| Croissance proie | α | 0.5–2.0 /an | Lapin : ~1.5, cerf : ~0.3 |
| Taux prédation | β | 0.01–0.05 | Dépend densité et territoire |
| Conv. proie→prédateur | δ | 0.005–0.02 | ~10% de β (règle des 10%) |
| Mortalité prédateur | γ | 0.1–0.5 /an | Loup : ~0.2, lion : ~0.15 |

#### Comportement oscillatoire
- Les populations oscillent en **quadrature de phase** : le pic prédateurs suit le pic proies de ~¼ de période
- Période typique : **3–10 ans** (cycle du lièvre/lynx canadien : ~10 ans, documenté depuis 1845)
- Ratio d'amplitude : prédateurs oscillent avec **amplitude ~1/5** de celle des proies
- L'oscillation est **neutralement stable** (Lotka-Volterra pur) → en réalité légèrement amorties ou entretenues par l'environnement

#### Version avec carrying capacity (Lotka-Volterra modifié)
```
dx/dt = αx(1 - x/K) - βxy   ← proie avec limite logistique
dy/dt = δxy - γy             ← prédateur inchangé

K = carrying capacity des proies
```
Cet ajout rend le système **convergent vers l'équilibre** (spirale vers x*, y*) plutôt que purement oscillatoire.

### 4. Carrying Capacity & Régulation densité-dépendante

#### Croissance logistique
```
dN/dt = rN × (1 - N/K)

N = population actuelle
r = taux de croissance intrinsèque (r_max)
K = carrying capacity (limite supportable par l'environnement)
```

#### Valeurs K typiques par espèce/biome
| Espèce | K (individus/km²) | r_max (/an) | Temps génération |
|--------|-------------------|-------------|------------------|
| Lapin | 500–2000 | 3–5 | 3–4 mois |
| Cerf/chevreuil | 20–80 | 0.3–0.5 | 2–3 ans |
| Loup | 1–5 | 0.2–0.4 | 3–4 ans |
| Lion | 0.5–3 | 0.15–0.25 | 4–5 ans |
| Souris | 5000–50000 | 6–10 | 1–2 mois |
| Aigle | 0.1–0.5 | 0.05–0.15 | 5–8 ans |
| Truite | 100–500 | 0.5–1.5 | 2–4 ans |
| Sauterelle | 10⁵–10⁷ | 5–15 | 2–3 mois |

#### Mécanismes densité-dépendants
1. **Compétition intra-spécifique** : ressources se raréfient → r diminue
2. **Stress & maladie** : densité élevée → épidémies, immunodépression
3. **Prédation accrue** : plus de proies = plus faciles à trouver
4. **Comportement territorial** : exclusion des individus en surplus
5. **Régulation fécondité** : portées plus petites, intervalles plus longs

**Pour Primordia** : quand N > 0.7K → pénalités croissance. Quand N > K → mortalité accrue. Jamais de population infinie.

### 5. Extinction en cascade & Keystone Species

#### Définition keystone species
Espèce dont l'impact sur l'écosystème est **disproportionné par rapport à sa biomasse**. Suppression → effondrement en cascade (trophic cascade).

#### Exemples quantifiés
| Espèce clé | Écosystème | Effet de sa suppression |
|------------|------------|------------------------|
| Loup (Canis lupus) | Yellowstone | +600% cervidés → surpâturage → érosion rivières → disparition castors, oiseaux |
| Loutre de mer | Côte Pacifique | +∞ oursins → destruction kelp → disparition poissons, pinnipèdes |
| Éléphant | Savane africaine | Fermeture canopée → perte de 30–50% espèces de plaine |
| Figuier (Ficus spp.) | Forêt tropicale | Frugivores perdent 50–70% source alimentaire en saison sèche |
| Étoile de mer (Pisaster) | Estran Pacifique | +moules → élimination 25 espèces concurrentes |

#### Mécanisme cascade
```
Suppression apex prédateur
  → explosion consommateurs secondaires
    → effondrement consommateurs primaires
      → explosion producteurs (ou leur destruction)
        → changement structure physique habitat
          → disparitions en chaîne (10–50 espèces affectées)
```

**Délai typique** : 2–5 ans pour la cascade complète, 10–20 ans pour la restructuration.

**Pour Primordia** : les apex prédateurs doivent avoir un poids spécial. Leur disparition doit déclencher un événement en cascade avec délai temporel simulé.

### 6. Compétition inter et intraspécifique

#### Principe d'exclusion compétitive (Gause, 1934)
Deux espèces occupant exactement la même niche écologique **ne peuvent pas coexister indéfiniment** → l'une élimine l'autre.

#### Coexistence possible par :
1. **Différentiation de niche** : ressources légèrement différentes
2. **Exploitation temporelle** : actif à des heures différentes
3. **Exploitation spatiale** : strates différentes
4. **Prédation keystone** : un prédateur maintient les deux populations sous K

#### Coefficients de compétition (modèle Lotka-Volterra compétition)
```
dN1/dt = r1·N1·(K1 - N1 - α12·N2) / K1
dN2/dt = r2·N2·(K2 - N2 - α21·N1) / K2

α12 = impact d'un individu sp2 sur sp1 (0 = pas de compétition, >1 = compétition forte)
α21 = impact d'un individu sp1 sur sp2
```

Coexistence stable si : **α12 × α21 < 1** (compétition interspécifique < intra)

### 7. Biomes — Ressources & Productivité

| Biome | Productivité primaire nette (g C/m²/an) | K relatif herbivores | Saison active | Particularités |
|-------|----------------------------------------|---------------------|---------------|----------------|
| Forêt tropicale humide | 1000–3500 | Très élevé | Toute l'année | Stratification verticale, biodiversité maximale |
| Forêt tempérée | 400–800 | Élevé | 6–8 mois | Saisonnalité marquée, litière importante |
| Forêt boréale (taïga) | 200–400 | Moyen | 4–5 mois | Peu d'espèces, grandes oscillations L-V |
| Prairie/savane | 300–700 | Très élevé (herbivores) | Variable | Feu = perturbation clé, mégaherbivores |
| Désert chaud | 10–200 | Très faible | Nuit / saison des pluies | K très bas, r_max élevé (espèces r-stratèges) |
| Toundra | 50–200 | Faible | 2–3 mois | Pergélisol, cycles rapides, lemmings ↔ renards |
| Zones humides | 500–2000 | Élevé | Variable | Décomposeurs dominants, cycles N/P rapides |
| Océan ouvert | 50–150 | Faible (mais vaste) | Variable | Phytoplancton = base, cycles saisonniers |
| Récif corallien | 500–1500 | Élevé | Toute l'année | Biodiversité maximale marine, très fragile |

### 8. Cycles biogéochimiques — Recyclage dans l'écosystème

#### Cycle du carbone
```
Photosynthèse    : CO2 + H2O → CH2O + O2  (fixation : 120 GtC/an terrestres)
Respiration      : CH2O + O2 → CO2 + H2O  (retour ~119 GtC/an)
Décomposition    : matière organique → CO2 + CH4 (via décomposeurs)
Stockage         : sol (1500 GtC), végétation (600 GtC), atmosphère (870 GtC)
Temps de retour  : feuille = 1–3 ans, bois = 10–100 ans, humus = 100–1000 ans
```

**Pour simulation** : chaque organisme mort libère son carbone progressivement (délai 1–7 jours sim.) qui retourne en nutriments disponibles pour les plantes.

#### Cycle de l'azote
```
Fixation N2 → NH3    : bactéries fixatrices (Rhizobium, Azotobacter) — 140 TgN/an
Nitrification        : NH3 → NO2- → NO3- (bactéries nitrifiantes)
Assimilation         : plantes absorbent NO3-, NH4+
Dénitrification      : NO3- → N2 (retour atmosphère, anaérobiose)
Minéralisation       : protéines mortes → NH4+ (décomposeurs)
```

**Goulot d'étranglement** : l'azote est souvent le facteur limitant la productivité primaire. K des plantes dépend de l'azote disponible dans le sol.

#### Cycle du phosphore (sans phase gazeuse)
```
Altération roches → PO4³- soluble → absorption plantes
Décomposition matière organique → retour PO4³- au sol
Lessivage → cours d'eau → sédiments (perte lente du système)
```

**Point clé** : le phosphore est le facteur limitant des écosystèmes aquatiques. Apport excessif → eutrophisation → effondrement O2 → mort poissons.

---

## Détails scientifiques

### Dynamique temporelle des populations — données empiriques

#### Cycles proie/prédateur documentés
| Système | Période cycle | Ratio max proies/prédateurs | Source |
|---------|--------------|----------------------------|--------|
| Lièvre arctique / Lynx du Canada | ~10 ans | 200:1 à 10:1 | Hudson's Bay Co. records 1845–1935 |
| Lemming / Renard arctique | 3–4 ans | 500:1 à 50:1 | Elton 1924 |
| Caribou / Loup | 15–25 ans | 50:1 à 5:1 | Mech & Peterson 2003 |
| Cerf / Puma | 8–15 ans | 100:1 à 15:1 | Beier 1995 |
| Anchois / Thon | 5–8 ans | 10000:1 à 1000:1 | FAO fisheries data |

#### Temps de génération et paramètres démographiques
| Espèce | Temps génération | Portée/an | Maturité sexuelle | Longévité max |
|--------|-----------------|-----------|-------------------|---------------|
| Souris | 6 semaines | 5–10 × 8–12 | 6 semaines | 2–3 ans |
| Lapin | 3 mois | 4–5 × 4–8 | 3–4 mois | 8–12 ans |
| Renard | 1 an | 1 × 4–6 | 10 mois | 12–14 ans |
| Loup | 2 ans | 1 × 4–7 | 2 ans | 13–16 ans |
| Cerf | 2–3 ans | 1 × 1–2 | 1.5–2 ans | 15–20 ans |
| Aigle royal | 5 ans | 1 × 1–3 | 5 ans | 30–40 ans |
| Truite | 3 ans | 1 × 500–5000 œufs | 2–3 ans | 10–20 ans |
| Saumon | 4 ans | 1 × 2000–8000 | 4 ans (mort post-frai) | 4–7 ans |
| Éléphant | 15 ans | 1 × 1 / 4–5 ans | 12–14 ans | 60–70 ans |
| Lion | 3 ans | 1 × 2–4 / 2 ans | 3–4 ans | 15–18 ans |

### Paramètres Lotka-Volterra calibrés — exemples réels

#### Système Lièvre / Lynx (calibration Elton & Nicholson)
```
Lièvre (proie)  : α = 1.0/an,  β = 0.1/lynx/an
Lynx (prédateur): δ = 0.075/an, γ = 0.25/an
Équilibre       : x* = γ/δ = 3.33 lynx/km²
                  y* = α/β = 10 lièvres/km²
Période oscillation théorique : 2π/√(αγ) ≈ 6.3 ans
(observé : ~10 ans → influences environnementales rallongent la période)
```

#### Système Proie générique / Prédateur générique (pour simulation)
```
Proie  : α = 0.8, β = 0.02
Prédateur : δ = 0.01, γ = 0.3
→ oscillation stable, période ~8 unités de temps
→ ratio moyen proies/prédateurs : α×γ/(β×δ) ≈ 120:1
```

### Structure réseau trophique réel

#### Forêt tempérée — connexions typiques
```
Niveau 1 : Chênes, hêtres, herbes, champignons (mycorhizes)
    ↓ 10%
Niveau 2 : Cerfs, lapins, sangliers, écureuils, insectes herbivores
    ↓ 10%
Niveau 3 : Renards, blaireaux, hiboux, couleuvres, araignées
    ↓ 10%
Niveau 4 : Loups, lynx, aigles
    ↓ décomposeurs ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
Décomposeurs : champignons, bactéries, cloportes, lombrics
    → recyclage nutriments → Niveau 1
```

**Connectance moyenne** d'un réseau trophique : 0.1–0.2 (chaque espèce interagit avec 10–20% des autres)
**Longueur chaîne alimentaire** : 3–5 niveaux (rarement plus, limite thermodynamique des 10%)

### Seuils critiques pour la simulation

#### Seuils d'extinction
- Population < **50 individus** → risque extinction stochastique élevé (consanguinité, events aléatoires)
- Population < **500 individus** → risque extinction moyen terme (minimum viable population, MVP)
- Population = 0 → déclencher analyse cascade (quelles espèces dépendent de cette proie/prédateur ?)

#### Règles de remplacement
- Si apex prédateur disparaît → herbivores × 3–10 en 5–15 ans
- Si herbivore-clé disparaît → végétation × 2–5, prédateurs −50–70%
- Si plante-clé disparaît (figuier, chêne) → 20–40% espèces associées −30–60%

#### Indices de stabilité écosystème
```
Shannon diversity index : H = -Σ(pi × ln(pi))
  H > 2.5 : écosystème stable et résilient
  H 1.5–2.5 : sous stress, vulnérable
  H < 1.5 : écosystème dégradé, cascade probable

Connectance (C) : C = L / S²  (L = liens, S = espèces)
  C < 0.1 : réseau fragile
  C 0.1–0.3 : résilient
  C > 0.3 : hyperstable (redondance fonctionnelle)
```

---

## Recommandations d'implémentation Godot 4

### Architecture système conseillée

```
EcosystemManager (Autoload)
├── TrophicNetwork          # Graphe orienté des relations alimentaires
│   ├── nodes[species_id]   # Nœuds = espèces
│   └── edges[pred→prey]    # Arêtes = relations avec β, δ
├── PopulationSimulator     # Intègre Lotka-Volterra en discret (Δt = 1 jour sim.)
│   ├── lotka_volterra_step(dt)
│   ├── apply_carrying_capacity(species, biome)
│   └── check_extinction_thresholds()
├── NutrientCycler          # Azote/phosphore/carbone disponibles par tile
│   ├── decompose(dead_biomass, tile)
│   └── nutrient_map[tile_id] → {N, P, C}
└── CascadeDetector         # Surveille keystone species
    ├── keystone_species[]
    └── trigger_cascade(species_id, delay_days)
```

### Intégration discrète Lotka-Volterra (Euler, Δt = 1 jour sim.)

```gdscript
func lotka_volterra_step(prey: Species, predator: Species, dt: float) -> void:
    var x := prey.population
    var y := predator.population

    var dx := (prey.alpha * x - prey.beta * x * y) * dt
    var dy := (predator.delta * x * y - predator.gamma * y) * dt

    prey.population = max(0.0, x + dx)
    predator.population = max(0.0, y + dy)

    # Carrying capacity logistique
    if prey.population > 0:
        var logistic_factor := 1.0 - (prey.population / prey.carrying_capacity)
        prey.population *= (1.0 + prey.alpha * logistic_factor * dt)
```

**Attention** : Euler explicite instable pour Δt grands → préférer **Runge-Kutta 4** si Δt > 0.1 an simulé, ou **méthode de Heun** (RK2) comme compromis.

### Paramètres suggérés pour 3 archétypes de départ

#### Archétype Forêt tempérée
```
Herbe/Arbuste : K=10000, r=2.0, biomasse_unit=0.1
Herbivore léger (lapin) : K=500, α=1.5, γ=0.8, β=0.02, δ=0.015
Carnivore moyen (renard): K=50,  α=0.4, γ=0.3, β=0.05, δ=0.01
Apex (loup) : K=5, α=0.2, γ=0.2, β=0.08, δ=0.008
```

#### Archétype Prairie/Savane
```
Graminées : K=50000, r=3.0
Mégaherbivore (bison/zèbre) : K=200, α=0.6, γ=0.4
Grand carnivore (lion) : K=3, α=0.25, γ=0.2
```

#### Archétype Aquatique (lac/rivière)
```
Algues/phytoplancton : K=100000, r=5.0 (limitation phosphore)
Zooplancton/petits poissons : K=2000, α=2.0, γ=1.5
Prédateur apex (brochet/truite) : K=20, α=0.5, γ=0.3
```

---

*Document généré pour Primordia — simulation écologique 2D Godot 4*
*Données issues de la littérature écologique établie (Lindeman, Lotka, Volterra, Pimm, Mech et al.)*
