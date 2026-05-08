# Génétique & Évolution — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Génétique & évolution pour simulation 2D
**État** : final
**Sources** : connaissances synthétisées (biologie évolutive, algorithmes génétiques)
— Références de base : Hartl & Clark *Principles of Population Genetics*, Dawkins *The Selfish Gene*,
  Goldberg *Genetic Algorithms in Search, Optimization, and Machine Learning*,
  Species ALRE / Ecosystem / Niche (game design references)

---

## Synthèse actionnable pour la simulation

### 1. Encodage génomique minimal viable

**Principe** : chaque agent possède un génome = tableau de N gènes, chaque gène = float [0.0, 1.0] ou int sur plage définie.

```
Genome {
  // Physique
  size:           float  // 0.2 → 2.0 (facteur multiplicateur taille corps)
  speed:          float  // 0.0 → 1.0 (normalisé, converti en px/s en runtime)
  strength:       float  // 0.0 → 1.0
  stamina:        float  // 0.0 → 1.0 (taux de récupération énergie)

  // Sensoriel
  vision_range:   float  // 0.0 → 1.0
  vision_angle:   float  // 0.0 → 1.0 (60° → 360°)
  smell_range:    float  // 0.0 → 1.0

  // Comportement
  aggression:     float  // 0.0 → 1.0
  curiosity:      float  // 0.0 → 1.0
  sociability:    float  // 0.0 → 1.0 (tendance à rester en groupe)

  // Métabolisme
  metabolism:     float  // 0.0 → 1.0 (coût énergétique par tick)
  diet_type:      float  // 0.0 = herbivore pur, 1.0 = carnivore pur
  gestation_time: float  // 0.0 → 1.0
  offspring_count: int   // 1 → 8

  // Camouflage / signaux
  color_r:        float
  color_g:        float
  color_b:        float

  // Résistances environnementales
  heat_tolerance:  float
  cold_tolerance:  float
  humidity_pref:   float
}
```

**Taille recommandée** : 16–24 gènes pour Phase 1. Au-delà de 64 → explosion combinatoire, pas de gain biologique visible à petite échelle.

---

### 2. Taux de mutation — valeurs numériques calibrées

| Contexte biologique réel           | Taux par base par génération |
|------------------------------------|------------------------------|
| Bactéries (E. coli)                | ~1×10⁻⁹                      |
| Invertébrés (Drosophile)           | ~1×10⁻⁸                      |
| Mammifères (souris, humain)        | ~1×10⁻⁸ – 2.5×10⁻⁸           |
| Virus ARN                          | ~10⁻³ – 10⁻⁵ (très élevé)    |

**Traduction pour simulation** :
- **Taux de mutation par gène** : 1–5% par génération (valeur recommandée : **2–3%**)
- **Magnitude de la mutation** (si le gène mute) : ±5–20% de sa valeur courante, distribution gaussienne centrée sur 0
- **Mutations catastrophiques** (rares) : 0.1% de chance qu'un gène soit retiré à une valeur aléatoire totale
- **Règle** : au-dessus de 10% par gène → évolution chaotique, convergence impossible. En dessous de 0.5% → stagnation trop lente pour être visible en jeu.

**Implémentation GDScript suggestive** :
```gdscript
func mutate(genome: Dictionary, rate: float = 0.025) -> Dictionary:
    var mutated = genome.duplicate()
    for key in mutated:
        if randf() < rate:
            var delta = randfn(0.0, 0.08)  # sigma = 8%
            mutated[key] = clamp(mutated[key] + delta, 0.0, 1.0)
    return mutated
```

---

### 3. Types de mutations

| Type           | Description                                    | Simulation |
|----------------|------------------------------------------------|------------|
| Substitution   | Un gène change de valeur                       | ±delta sur float |
| Insertion      | Nouveau gène ajouté (si génome variable)       | Ajouter un trait à un pool optionnel |
| Délétion       | Gène perdu / silencé                           | Gène mis à 0 ou masqué |
| Duplication    | Un gène est copié (redondance)                 | Pas nécessaire Phase 1 |
| Inversion      | Deux gènes échangent leurs valeurs             | Swap de deux positions du tableau |

Pour Phase 1 : implémenter **substitution + délétion partielle** (mise à 0). Le reste est cosmétique.

---

### 4. Hérédité — transmission des traits

**Génome à deux parents (sexué)** :
- **Crossover uniforme** : pour chaque gène, choisir aléatoirement parent A ou parent B (50/50)
- **Crossover à un point** : couper le génome en un index, hériter gauche de A et droite de B
- Recommandé : **crossover uniforme** — meilleure exploration génétique

**Dominance/récessivité** :
- Modèle simplifié : chaque gène a un allèle A (dominant) et allèle B (récessif)
- Expression phénotypique = si allèle A présent → A s'exprime, sinon B
- En simulation float, la dominance peut être modélisée : `pheno = 0.7 * allele_A + 0.3 * allele_B`

**Polygénisme** :
- Un trait phénotypique = somme pondérée de plusieurs gènes
- Exemple : `attack_power = 0.5 * strength + 0.3 * size + 0.2 * aggression`
- Permet des interactions riches sans complexité d'implémentation excessive

---

### 5. Sélection naturelle — 4 types

#### Sélection positive (directionnelle)
- Un trait augmente la survie dans un environnement spécifique → se répand dans la population
- Exemple : zone aride → `heat_tolerance` élevée → meilleure survie → plus de reproduction
- **Implémentation** : la fitness function intègre le contexte biome courant

#### Sélection négative (purifiante)
- Les mutations délétères sont éliminées → maintien de la "norme fonctionnelle"
- **Implémentation** : agents avec métabolisme trop coûteux meurent avant reproduction → pression automatique

#### Sélection stabilisatrice
- Les extrêmes sont désavantagés → la moyenne est favorisée
- Exemple : taille — trop petit (vulnérable) ou trop grand (coût énergétique excessif) → optimum central
- **Implémentation** : courbe en cloche dans la fitness function pour certains traits

#### Sélection disruptive
- Les deux extrêmes sont favorisés, la moyenne est désavantagée
- Mécanisme de spéciation possible
- Exemple : coloration — très sombre (forêt) ou très claire (désert), gris intermédiaire non optimal
- **Implémentation** : deux niches écologiques avec fitness inverses coexistantes

---

### 6. Fitness Function — calcul de l'aptitude

**Principe** : la fitness n'est pas un score absolu. C'est une probabilité de survie et de reproduction dans un contexte donné.

**Architecture recommandée** :
```gdscript
func calculate_fitness(agent: Agent, environment: Environment) -> float:
    var f = 1.0

    # Survie énergétique
    var energy_efficiency = agent.genome.stamina - agent.genome.metabolism
    f *= 1.0 + 0.3 * energy_efficiency

    # Adéquation biome
    var biome_match = environment.get_tolerance_score(agent.genome)
    f *= 0.5 + 0.5 * biome_match  # jamais à 0, toujours une chance

    # Compétition alimentaire
    var food_access = environment.get_food_access(agent)
    f *= food_access

    # Prédation
    var predation_risk = environment.get_predation_pressure(agent)
    f *= (1.0 - predation_risk)

    return clamp(f, 0.01, 10.0)
```

**Règles de design** :
- La fitness n'est jamais 0 (extinction trop brutale) → floor à 0.01
- Elle est relative à la population locale, pas absolue
- Ne pas hardcoder "grand = fort" → contextualiser (grand = fort en combat, lent en fuite)

---

### 7. Dérive génétique

**Définition** : variation aléatoire des fréquences alléliques non liée à la sélection — pur hasard statistique.

**Impact sur petites populations** :
- Population < 50 individus → dérive domine sur la sélection
- Population < 10 → quasi-certitude de fixation ou perte d'un allèle en quelques générations
- Population efficace (Ne) : correspond souvent à 30–50% de la population totale (les reproducteurs actifs)

**Effet fondateur** :
- Un petit groupe isole d'une grande population → génome appauvri, traits rares du fondateur sur-représentés
- Exemple réel : daltonisme élevé sur l'île de Pingelap (Pacifique) suite à un typhon
- **Implémentation** : lors d'une migration ou isolation d'un groupe, conserver UNIQUEMENT les gènes du sous-groupe → divergence rapide garantie

**Goulot d'étranglement (bottleneck)** :
- Réduction catastrophique de la population (sécheresse, maladie, prédateur)
- Si 95% de la population est éliminée → la diversité génétique chute drastiquement
- **Implémentation** : événement catastrophique → tuer N% de la population au hasard (pas par fitness) → observer dérive

**Seuils pratiques pour simulation** :
| Taille population | Régime dominant |
|-------------------|-----------------|
| > 500             | Sélection naturelle prime |
| 100 – 500         | Sélection + dérive mixte |
| 50 – 100          | Dérive significative |
| < 50              | Dérive domine, sélection quasi-inefficace |
| < 10              | Fixation ou extinction imminente |

---

### 8. Spéciation — critères et seuils

**Définition opérationnelle** : deux populations forment deux espèces quand elles ne peuvent plus se reproduire viablement.

**Mécanismes principaux** :

| Mécanisme | Description | Déclencheur simulation |
|-----------|-------------|------------------------|
| Allopatrique | Séparation géographique → divergence indépendante | Barrière physique (rivière, montagne) entre deux groupes |
| Sympatrique | Même zone, niches différentes | Sélection disruptive intense → divergence comportementale |
| Péripatrique | Petit groupe en bordure → effet fondateur + dérive | Migration périphérique d'un sous-groupe isolé |
| Parapatrique | Zones adjacentes avec gradient → cline génétique | Gradient environnemental continu |

**Critère de spéciation simulé — seuil de divergence génomique** :
- Calculer la distance génomique : `d = mean(|genome_A[i] - genome_B[i]|)` sur tous les gènes
- Si `d > SPECIATION_THRESHOLD` → reproduction impossible (ou viabilité de la progéniture réduite)
- **Valeur recommandée** : `SPECIATION_THRESHOLD = 0.35` (35% de divergence moyenne)
- Valeur progressive possible : à partir de 25% → fertilité réduite (0.5×), à 40% → stérile

```gdscript
func can_reproduce(genome_a: Dictionary, genome_b: Dictionary) -> float:
    var distance = 0.0
    var keys = genome_a.keys()
    for key in keys:
        distance += abs(genome_a[key] - genome_b[key])
    distance /= keys.size()

    if distance < 0.25:
        return 1.0       # Compatible
    elif distance < 0.40:
        return remap(distance, 0.25, 0.40, 1.0, 0.0)  # Fertilité décroissante
    else:
        return 0.0       # Incompatible → espèces distinctes
```

---

### 9. Co-évolution — course aux armements

**Principe** : prédateur et proie évoluent ensemble dans une dynamique de pression mutuelle.

**Modèle de base (Red Queen Hypothesis)** :
- La proie évolue pour fuir mieux → le prédateur évolue pour chasser mieux → cycle continu
- Aucun des deux ne "gagne" définitivement → équilibre dynamique
- Si le prédateur évolue trop vite → extinction des proies → famine du prédateur → extinction en cascade

**Traits concernés** :
```
Proie → speed, camouflage (color), vision, group_behavior (sociabilité)
Prédateur → speed, strength, vision_range, aggression, stamina
```

**Mécanismes concrets pour simulation** :
1. **Pression asymétrique** : la proie perd plus (mort) que le prédateur (repas raté) → la proie évolue légèrement plus vite
2. **Lag évolutif** : la sélection ne s'applique qu'à la prochaine génération → délai réaliste
3. **Évitement de l'arms race runaway** : plafonner les traits via coût métabolique (speed élevé → metabolism élevé)

**Trade-offs obligatoires** (évite l'optimisation totale) :
| Trait fort | Coût associé |
|------------|--------------|
| Speed élevé | metabolism élevé |
| Vision range élevée | cerveau coûteux → stamina réduit |
| Size élevée | nourriture nécessaire accrue |
| Camouflage parfait | mobilité réduite |
| Aggression élevée | sociabilité réduite |

---

### 10. Algorithmes évolutionnaires dans les jeux existants

#### Species ALRE (Aaronmander)
- Génome : 20–30 traits flottants par espèce
- Sélection : basée sur l'énergie accumulée dans le tick
- Spéciation : distance génétique + isolement géographique
- Point fort : visualisation en temps réel des arbres phylogénétiques
- **Leçon** : la spéciation automatique par distance génomique fonctionne bien mais nécessite un suivi de lignée

#### Ecosystem (Underhanded Arts)
- Génome comportemental : arbre de décision évolué
- Fitness = survie à long terme, pas un score instantané
- **Leçon** : évaluer la fitness sur une fenêtre de N derniers ticks, pas tick par tick

#### Niche (Team Niche)
- Gènes exprimés en camouflage, taille, résistances
- Sélection tournée (joueur guide l'environnement)
- **Leçon** : rendre les gènes lisibles par le joueur → couleur, forme → immersion ++

#### Spore (Maxis, 2008)
- Gènes = parties du corps éditées manuellement
- Pas d'évolution autonome → pédagogique mais non-simulation
- **Leçon** : séparation claire entre évolution visible (phénotype) et mécanique interne (génotype)

---

### 11. Paramètres de configuration recommandés pour Primordia

```gdscript
# evolution_config.gd
const MUTATION_RATE           : float = 0.025   # 2.5% par gène par génération
const MUTATION_MAGNITUDE      : float = 0.08    # sigma de la gaussienne
const MUTATION_CATASTROPHIC   : float = 0.001   # reset aléatoire total du gène
const SPECIATION_THRESHOLD    : float = 0.35    # divergence génomique → isolement
const SPECIATION_SOFT_START   : float = 0.25    # début de réduction fertilité
const MIN_VIABLE_POPULATION   : int   = 8       # en dessous → risque extinction
const DRIFT_DOMINANT_POP      : int   = 50      # en dessous → dérive > sélection
const GENOME_SIZE             : int   = 20      # nombre de gènes par individu
const FITNESS_WINDOW_TICKS    : int   = 100     # évaluation sur N derniers ticks
const CROSSOVER_TYPE          : String = "uniform"  # uniform | single_point
```

---

## Détails scientifiques

### Taux de mutation réels — données précises

- **Humain** : ~1.1 × 10⁻⁸ substitutions/pb/génération → ~64 mutations par individu/génération (sur 6 Gb de génome)
- **Souris** : ~5 × 10⁻⁹/pb/génération
- **Drosophile** : ~3.5 × 10⁻⁹/pb/génération
- **E. coli** : ~1 × 10⁻¹⁰/pb/réplication

Les taux réels sont infinitésimaux car les génomes sont immenses (millions à milliards de paires de bases). En simulation, avec des génomes de 20 gènes, un taux de 2–5% est biologiquement équivalent.

### Modèle Hardy-Weinberg — équilibre de référence

Conditions d'équilibre (population non-évolutive) :
1. Population infinie
2. Panmixie (reproduction aléatoire)
3. Pas de mutation
4. Pas de migration
5. Pas de sélection

La simulation **viole volontairement toutes ces conditions** → l'évolution émerge des violations.

### Coefficient de sélection (s) et dominance (h)

- `s` = désavantage sélectif d'un allèle (0 = neutre, 1 = létal)
- `h` = coefficient de dominance (0 = récessif complet, 1 = dominant complet, 0.5 = codominance)
- Fréquence allèle après n générations : `p(n) = p(0) / (p(0) + (1-p(0)) × e^(-s×n))` (approximation)

### Nombre effectif de population (Ne)

- Ne ≠ N (census population)
- Ne prend en compte : ratio sexes, variance reproductive, fluctuations temporelles
- Estimation : `Ne ≈ 0.25 × N` à `0.5 × N` selon la structure de reproduction
- **Impact sur dérive** : la dérive est proportionnelle à `1/(2×Ne)` — plus Ne est petit, plus la dérive est forte

### Isolement reproductif — types biologiques

| Type | Mécanisme | Pré/post-zygotique |
|------|-----------|--------------------|
| Comportemental | Préférence d'accouplement | Pré |
| Temporel | Saisons de reproduction différentes | Pré |
| Mécanique | Incompatibilité morphologique | Pré |
| Gamétique | Incompatibilité biochimique | Pré |
| Hybride non-viable | Descendance non fonctionnelle | Post |
| Stérilité hybride | Mulet (âne × cheval) | Post |

En simulation : modéliser **l'isolement gamétique via la distance génomique** — le mécanisme le plus direct.

### Polygénisme — traits quantitatifs

Les traits continus (taille, couleur, comportement) sont gouvernés par de nombreux gènes à effet faible :
- Distribution en cloche dans la population (loi centrale des grands nombres)
- Héritabilité (`h²`) : proportion de la variance phénotypique due à la génétique
  - Taille humaine : h² ≈ 0.8 (très héréditaire)
  - Comportement : h² ≈ 0.3–0.6
  - Résistance aux maladies : h² ≈ 0.1–0.4

**Pour simulation** : chaque trait = combinaison linéaire de 2–4 gènes + bruit environnemental.

### Co-évolution — modèles mathématiques

**Modèle Lotka-Volterra (proie-prédateur)** :
```
dV/dt = rV - αVP       # proies : croissance - prédation
dP/dt = βVP - mP       # prédateurs : gains - mortalité

r = taux reproduction proie
α = efficacité prédation
β = conversion proie → biomasse prédateur
m = mortalité naturelle prédateur
```

L'évolution modifie `α` et `β` au fil du temps — c'est la co-évolution.

**Red Queen** : formalisé par Van Valen (1973) — les espèces doivent évoluer en continu simplement pour maintenir leur fitness relative dans un environnement biotique qui évolue lui aussi.

---

*Recherche produite le 2026-05-08 — base pour l'implémentation du système génétique Primordia Phase 1.*
