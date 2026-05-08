# Épidémiologie — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Épidémiologie et modèles de propagation
**État** : final
**Sources** : connaissances académiques établies (Anderson & May 1991, Kermack & McKendrick 1927, WHO disease fact sheets, CDC epidemiology data, Nature superspreading studies Lloyd-Smith et al. 2005)

---

## Synthèse actionnable pour la simulation

### Paramètres à exposer dans Godot

| Paramètre | Type | Plage recommandée | Description |
|---|---|---|---|
| `beta` | float | 0.05 – 1.5 | Taux de transmission par contact/jour |
| `gamma` | float | 0.02 – 0.5 | Taux de rétablissement (1/durée infectieuse) |
| `sigma` | float | 0.1 – 0.5 | Taux d'exposition→infection (1/période incubation) |
| `delta` | float | 0.0 – 0.05 | Perte d'immunité (SEIRS only, 0 = SEIR) |
| `mu` | float | 0.0 – 0.15 | Taux de mortalité de la maladie |
| `dispersion_k` | float | 0.1 – 10.0 | Paramètre surdispersion (k < 1 = superspreaders actifs) |
| `spatial_decay` | float | 0.5 – 5.0 | Décroissance transmission avec distance |

### Modèle recommandé pour Primordia : SEIRS spatial

SEIRS couvre tous les cas :
- Delta = 0 → SEIR (immunité permanente)
- Sigma très grand → SIR (pas de latence visible)
- Gamma = 0 → SIS (endémie perpétuelle)
- Delta > 0 + mu > 0 → épidémies cycliques réalistes

### Seuil d'alerte épidémique

R0 effectif = β / γ × (S/N)

- R0_eff > 1 → épidémie en croissance
- R0_eff = 1 → endémie stable
- R0_eff < 1 → extinction naturelle

**Seuil immunité collective** : p_c = 1 - 1/R0

---

## Détails scientifiques

### 1. Modèle SIR (Kermack–McKendrick, 1927)

Population divisée en 3 compartiments : S (Susceptible), I (Infecté), R (Rétabli/Retiré).

**Équations différentielles :**
```
dS/dt = -β × S × I / N
dI/dt =  β × S × I / N  -  γ × I
dR/dt =  γ × I
```

Avec N = S + I + R = constante (pas de naissance/mort).

**Paramètres :**
- **β** (beta) : taux de transmission. β = contact_rate × probabilité_transmission_par_contact. Unité : jour⁻¹
- **γ** (gamma) : taux de rétablissement = 1 / durée_infectieuse_moyenne. Unité : jour⁻¹
- **R0** = β / γ : nombre de reproduction de base (cas secondaires par cas index en population naïve)

**Comportement clé :**
- Épidémie démarre si S₀ > γ/β (soit R0 > 1)
- Pic d'infection : quand S(t) = γ/β
- La courbe I(t) est une cloche asymétrique
- Le modèle prédit toujours un reliquat de susceptibles non infectés

**Limitations :** pas de période d'incubation, immunité permanente, population homogène.

---

### 2. Modèle SEIR

Ajout du compartiment **E (Exposé)** : individu infecté mais pas encore contagieux (période d'incubation).

**Équations :**
```
dS/dt = -β × S × I / N
dE/dt =  β × S × I / N  -  σ × E
dI/dt =  σ × E  -  γ × I
dR/dt =  γ × I
```

- **σ** (sigma) = 1 / durée_incubation_moyenne. Unité : jour⁻¹
- Retarde le pic épidémique vs SIR
- Plus réaliste pour maladies avec incubation longue (COVID, Ebola, grippe)

**Impact sur la simulation :** le compartiment E crée un délai entre exposition et détection. Crucial pour simuler la propagation silencieuse avant qu'une épidémie soit visible.

---

### 3. Extensions

#### SEIRS — Réinfection possible
```
dS/dt = -β×S×I/N  +  δ×R
dR/dt =  γ×I  -  δ×R
```
- **δ** = 1 / durée_immunité. Si δ > 0, les guéris perdent leur immunité → cycles épidémiques
- Modélise : grippe saisonnière, COVID variants, certaines bactéries

#### SIS — Pas d'immunité
```
dS/dt = -β×S×I/N  +  γ×I
dI/dt =  β×S×I/N  -  γ×I
```
- Équilibre endémique : I* = N × (1 - γ/β) si R0 > 1
- Modélise : certaines IST, infections bactériennes sans immunité durable

#### SEIRD — Avec mortalité
```
dD/dt = μ × I
dI/dt = σ×E - γ×I - μ×I
```
- μ = taux de létalité (CFR ajusté à la durée infectieuse)
- N n'est plus constant

#### Modèles spatiaux

**Patch model :** diviser la carte en cellules, chaque cellule a ses propres S/E/I/R, avec un terme de couplage de migration :
```
dS_i/dt = -β×S_i×I_i/N_i  +  Σ_j m_ij × (S_j - S_i)
```
- m_ij = taux de migration entre patch i et j

**Kernel de transmission :** probabilité de transmission entre individus à distance d :
```
P(transmission, d) = β × exp(-d / L)
```
- L = longueur caractéristique (ex: 2 cellules pour contact direct, 20 pour aérosol)

**Réseau de contacts :** chaque agent a un graphe de contacts (famille, travail, aléatoire). Plus réaliste mais computationnellement lourd.

---

### 4. R0 et seuils d'immunité collective par maladie réelle

| Maladie | R0 | Seuil immunité (p_c) | Durée incubation | Durée infectieuse | Vecteur |
|---|---|---|---|---|---|
| Rougeole (Measles) | 12–18 | 92–94% | 10–14 j | 8 j | Aérosol |
| Coqueluche | 12–17 | 92–94% | 7–10 j | 21 j | Gouttelettes |
| Diphtérie | 6–7 | 85% | 2–5 j | 14–28 j | Contact/gouttelettes |
| Variole (Smallpox) | 5–7 | 80–85% | 7–19 j | 14 j | Aérosol/contact |
| Polio | 5–7 | 80–86% | 7–14 j | 7–10 j | Féco-oral |
| COVID-19 (souche originale) | 2.5–3.5 | 60–72% | 5–6 j | 7–10 j | Aérosol/gouttelettes |
| COVID-19 (Omicron) | 8–15 | 87–93% | 3–4 j | 5–7 j | Aérosol |
| Grippe 1918 (H1N1) | 2–3 | 50–67% | 1–3 j | 4–7 j | Gouttelettes/aérosol |
| Grippe saisonnière | 1.2–1.4 | 17–33% | 1–4 j | 3–7 j | Gouttelettes |
| Ebola (Zaïre) | 1.5–2.5 | 33–60% | 2–21 j (moy 8) | 6–12 j | Contact direct/fluides |
| Peste bubonique | 1.3–3.0 | 23–67% | 2–6 j | 3–6 j (sans tx) | Piqûre puce / contact |
| Peste pneumonique | 2.0–4.0 | 50–75% | 1–3 j | 3–5 j | Aérosol |
| Choléra | 2–6 | 50–83% | 1–5 j | 7–14 j | Eau contaminée |
| Typhus | 2–3 | 50–67% | 7–14 j | 12–14 j | Pou/puce |
| Dengue | 2–4 | 50–75% | 3–14 j | 6–7 j | Moustique |

**Note R0 :** ces valeurs sont pour populations denses non vaccinées. En simulation, R0 effectif = R0_base × (S/N) × facteur_densité.

---

### 5. Superspreaders

#### Définition
Un superspreader infecte un nombre de cas secondaires significativement supérieur à la moyenne R0. Définition opérationnelle : individu causant > 3× R0 infections.

#### Paramètre de dispersion k (Lloyd-Smith et al., Nature 2005)

La distribution des cas secondaires suit une **loi binomiale négative** de paramètre k :
- **k petit (< 0.1)** : forte surdispersion, épidémies dominées par superspreaders (SARS, MERS, Ebola)
- **k grand (> 1)** : distribution homogène, chaque infecté propage de façon similaire (rougeole, grippe)
- **Règle 20/80** : pour k faible, ~20% des infectés causent ~80% des transmissions

| Maladie | k estimé | Surdispersion |
|---|---|---|
| SARS-CoV-1 | 0.16 | Forte |
| MERS | 0.26 | Forte |
| COVID-19 | 0.1–0.3 | Forte |
| Ebola | 0.18 | Forte |
| Grippe 1918 | ~1.0 | Faible |
| Rougeole | ~1.0 | Faible |

#### Facteurs biologiques/comportementaux
- Charge virale élevée (shed viral plus important)
- Anatomie des voies respiratoires (aérosols produits différemment)
- Comportement social : contacts nombreux, environnements confinés
- Profession : soignant, enseignant, vendeur
- Immunodéprimé (portage chronique plus long)

#### Impact sur simulation
- Avec k faible : clusters explosifs localisés → une fête, un marché peut déclencher une épidémie
- Extinction stochastique plus probable (beaucoup d'introductions sans suite)
- La détection d'un cluster = signal épidémique fort
- **Implémentation :** attribuer à chaque agent un `transmission_multiplier` tiré d'une loi log-normale ou binomiale négative

---

### 6. Vecteurs de contamination

| Vecteur | Portée | Exemples maladies | Facteur densité | Paramètre simulation |
|---|---|---|---|---|
| Contact direct (peau/fluides) | 0–1 m | Ebola, gale, MST | Très fort | Nécessite proximité physique |
| Gouttelettes (droplets) | 1–2 m | Grippe, COVID classique | Fort | Rayon de transmission 1–2 tiles |
| Aérosol (airborne) | 2–10+ m | Rougeole, tuberculose, COVID Omicron | Modéré (pièce fermée) | Différer par ventilation |
| Féco-oral | Indirect | Choléra, polio, typhus | Lié à l'eau/nourriture | Contamination source d'eau |
| Vecteur biologique (piqûre) | Indirect | Dengue, paludisme, Yersinia | Lié à densité vecteur | Modèle SIR séparé pour le vecteur |
| Sol/fomites | Indirect | Anthrax, tétanos | Faible sauf confinement | Demi-vie de contamination sur tile |
| Alimentaire | Indirect | Salmonelle, E.coli | Lié aux bâtiments/marchés | Contamination source de nourriture |

---

### 7. Impact de la densité de population

La densité affecte β directement via le taux de contact :
```
β_effectif = β_base × f(densité)
```

Relation empirique approximative :
```
f(ρ) = (ρ / ρ_ref)^α    avec α ≈ 0.8–1.0
```

- ρ = densité locale (agents/km² ou agents/tile)
- ρ_ref = densité de référence pour β_base

**Effets observés :**
- Villes (>1000 hab/km²) : R0 multiplié par 2–5× vs rural
- Bidonvilles/slums : densité extrême → épidémies explosives (choléra Haïti 2010)
- Migration : flux de population = vecteur de dissémination inter-régions
- Confinement : réduit ρ_effective → équivalent à baisser β

**Pour Primordia :** calculer la densité locale par tile (rayon 5–10 tiles) et moduler β en conséquence. Les marchés, places publiques, tavernes = hotspots de transmission.

---

### 8. Épidémies historiques — Données pour templates de maladies

#### Peste Noire (Yersinia pestis, 1347–1351)
- Mortalité Europe : 30–60% de la population
- Vecteur : puces sur rats → humains (bubonique) ; aérosol (pneumonique)
- R0 bubonique : 1.3–3.0 ; pneumonique : 2.0–4.0
- CFR sans traitement : 30–90% (bubonique) ; 90–100% (pneumonique/septicémique)
- Durée incubation : 2–6 j (bubonique), 1–3 j (pneumonique)
- Progression : bubons en 1–3 j, décès en 3–6 j sans traitement
- Pattern spatial : progression le long des routes commerciales, ports d'abord

#### Grippe 1918 (H1N1 "Espagnole")
- Mortalité : ~50–100 millions morts (2–3% pop mondiale)
- R0 : 2–3 ; CFR : 2–3% (exceptionnel pour grippe)
- 3 vagues distinctes : printemps 1918 (légère), automne 1918 (dévastatrice), hiver 1919
- Caractéristique : mortalité en W (jeunes adultes 20–40 ans touchés, immunité croisée 1890?)
- Durée incubation : 1–3 j ; durée infectieuse : 4–7 j
- Contexte aggravant : WWI, tranchées, dénutrition, déplacements massifs

#### Ebola (Zaïre/EBOV, épidémie Afrique de l'Ouest 2014–2016)
- ~11 000 morts, 28 000 cas
- R0 initial : 1.5–2.5 ; réduit à <1 par mesures de contrôle
- CFR : 40–70%
- Vecteur : contact direct avec fluides biologiques (sang, vomissures, cadavres)
- Durée incubation : 2–21 j (médiane 8–10 j)
- Durée infectieuse : 6–12 j
- Superspreaders : enterrements traditionnels = clusters majeurs
- k ≈ 0.18 : ~3% des cas causaient ~38% des transmissions

#### COVID-19 (SARS-CoV-2, 2020–2022)
- Pandémie : >600 millions cas, >6 millions morts officiels
- R0 original : 2.5–3.5 ; Omicron : 8–15
- CFR : 0.5–3% (variant-dépendant)
- Vecteur : aérosol dominant, gouttelettes, fomites (secondaire)
- Durée incubation : 5–6 j (original) ; 3–4 j (Omicron)
- Durée infectieuse : 7–10 j ; contagiosité max J-2 à J+5 symptômes
- Présymptomatique : 40–50% de la transmission avant symptômes
- k ≈ 0.1–0.3 : forte surdispersion, clusters en espaces confinés

#### Choléra (Vibrio cholerae, pandémies multiples)
- 7 pandémies depuis 1817 ; encore endémique dans 47 pays
- R0 : 2–6 selon accès à l'eau potable
- CFR sans traitement : 25–50% ; avec traitement : <1%
- Vecteur : eau/aliments contaminés par fèces
- Durée incubation : quelques heures à 5 j (médiane 2 j)
- Mort par déshydratation en 6–12h sans traitement (pertes hydrique 10–20 L/j)
- Pattern : explosif près des sources d'eau contaminées (pompe de Broad Street, John Snow 1854)

---

### 9. Durées de phases — Tableau de référence pour Godot

| Paramètre | Valeur min | Valeur typique | Valeur max | Notes |
|---|---|---|---|---|
| Période incubation (E→I) | 1 j | 5 j | 21 j | COVID: 5j ; Ebola: 8j ; grippe: 2j |
| Durée infectieuse (I→R) | 3 j | 7 j | 28 j | Grippe: 5j ; Ebola: 9j ; rougeole: 8j |
| Durée immunité (R→S) | 90 j | 365 j | ∞ | Grippe: 1–2 ans ; COVID: 3–6 mois (Omicron) |
| Délai mort (I→D) | 3 j | 8 j | 20 j | Ebola: 6–9j ; peste: 3–6j |
| Seuil déclenchement alarme | 1 cas / 10k | 5 cas / 10k | — | Dépend du CFR et détection |

---

### 10. Implémentation recommandée pour Primordia

#### Architecture système

```
EpidemicSystem
  ├── DiseaseDefinition (Resource Godot)
  │     ├── beta: float
  │     ├── gamma: float
  │     ├── sigma: float
  │     ├── delta: float
  │     ├── mu: float (CFR)
  │     ├── k_dispersion: float
  │     ├── transmission_vector: Enum [DIRECT, DROPLET, AEROSOL, WATER, VECTOR]
  │     └── incubation_days: Vector2 (min, max)
  │
  ├── AgentHealthComponent
  │     ├── state: Enum [S, E, I, R, D]
  │     ├── days_in_state: int
  │     ├── transmission_multiplier: float  ← tiré à la création (log-normale)
  │     └── immunity_duration: float
  │
  └── TransmissionResolver
        ├── calculate_contact_probability(agent_a, agent_b, disease) -> float
        ├── apply_spatial_decay(distance, vector_type) -> float
        └── roll_transmission(probability) -> bool
```

#### Pseudo-code transmission par contact

```gdscript
func attempt_transmission(infected: Agent, susceptible: Agent, disease: DiseaseDefinition) -> bool:
    var distance = infected.position.distance_to(susceptible.position)
    var base_prob = disease.beta / infected.contacts_per_day
    var spatial_factor = exp(-distance / disease.spatial_decay_length)
    var superspreader_factor = infected.transmission_multiplier
    var density_factor = get_local_density(infected.position) / REFERENCE_DENSITY
    
    var final_prob = base_prob * spatial_factor * superspreader_factor * pow(density_factor, 0.8)
    return randf() < final_prob
```

#### Valeurs initiales suggérées par template de maladie

| Template | β | γ | σ | μ | k | Incubation |
|---|---|---|---|---|---|---|
| Grippe | 0.5 | 0.25 | 0.5 | 0.001 | 1.0 | 2 j |
| Peste pneumonique | 0.8 | 0.15 | 0.5 | 0.7 | 0.3 | 2 j |
| Peste bubonique | 0.3 | 0.1 | 0.25 | 0.5 | 0.4 | 4 j |
| Ebola-like | 0.35 | 0.1 | 0.12 | 0.5 | 0.18 | 8 j |
| Grippe 1918 | 0.6 | 0.2 | 0.4 | 0.025 | 1.0 | 2 j |
| Variole | 0.5 | 0.07 | 0.07 | 0.3 | 0.8 | 13 j |
| Rougeole | 1.2 | 0.14 | 0.08 | 0.002 | 1.0 | 12 j |
| Choléra (eau) | — | 0.14 | 0.5 | 0.25 | 0.5 | 2 j |

**Note choléra :** β dépend du taux de contact avec eau contaminée, pas inter-humain direct. Modéliser comme contamination de source (tile d'eau) plutôt que transmission agent-agent.

---

### 11. Phénomènes émergents à simuler

1. **Vague épidémique** : R0 > 1 → croissance exponentielle → pic → déclin (épuisement des susceptibles)
2. **Épidémie cyclique** (SEIRS) : vagues saisonnières si δ > 0 et population renouvelée
3. **Extinction stochastique** : avec k faible, un pathogène avec R0 > 1 peut quand même s'éteindre si les premiers cas ne trouvent pas de contacts
4. **Endémie** (SIS) : équilibre I* = N(1 - 1/R0) — la maladie ne disparaît jamais
5. **Effet fondateur** : une ville isolée peut rester indemne longtemps si le pathogène ne voyage pas
6. **Seuil de détection** : épidémie visible seulement quand I dépasse ~0.1% population (signal epidémique)
7. **Comportement adaptatif** : si les agents fuient les malades → β diminue dynamiquement
