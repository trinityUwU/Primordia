# Parasitisme & Symbiose — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Parasitisme & symbiose
**État** : final
**Sources** : connaissances corpus (biologie établie)

---

## Synthèse actionnable pour la simulation

### Relations inter-agents à implémenter

| Relation | Code ID | Effet sur fitness hôte | Effet sur fitness partenaire |
|---|---|---|---|
| Parasitisme obligatoire | `PARASITISM_OBL` | −fitness × 0.05–0.40/tick | +energie × 0.3–0.8/tick |
| Parasitisme facultatif | `PARASITISM_FAC` | −fitness × 0.02–0.15/tick | +energie × 0.1–0.4/tick |
| Mutualisme obligatoire | `MUTUALISM_OBL` | +fitness × 0.05–0.25/tick | +fitness × 0.05–0.25/tick |
| Mutualisme facultatif | `MUTUALISM_FAC` | +fitness × 0.02–0.10/tick | +fitness × 0.02–0.10/tick |
| Commensalisme | `COMMENSALISM` | ±0 (neutre) | +fitness × 0.01–0.08/tick |
| Amensalisme | `AMENSALISM` | −fitness × 0.01–0.05/tick | ±0 (neutre) |

### Paramètres charge parasitaire

```
PARASITE_THRESHOLD_SUBCLINICAL = 10    // unités parasites/agent — pas de symptôme
PARASITE_THRESHOLD_CLINICAL    = 50    // symptômes comportementaux déclenchés
PARASITE_THRESHOLD_LETHAL      = 200   // mort probable (P_mort = 0.85 par tick)
PARASITE_TRANSMISSION_RATE     = 0.03–0.15  // probabilité/tick/contact selon type
PARASITE_DECAY_RATE            = 0.05  // baisse naturelle/tick sans hôte
PARASITE_REPLICATION_RATE      = 1.2–3.5×  // doublement dans hôte tolérant
```

### Cycle de vie parasite (en ticks simulés)

```
Incubation         : 5–20 ticks  (hôte infecté, pas encore transmetteur)
Phase patente      : 20–100 ticks (transmission active, coût fitness max)
Phase chronique    : 100–500 ticks (charge réduite, coût fitness modéré)
Immunité acquise   : après phase chronique → résistance × 0.5 pour reinfection
```

### Manipulation comportementale — flags agent

```
BEHAVIOR_FLAG_BOLDNESS     : +0.3 à +0.8  // Toxoplasma-like, réduit évitement prédateur
BEHAVIOR_FLAG_GROOMING     : +0.5          // ectoparasites, augmente temps allogrooming
BEHAVIOR_FLAG_MOVEMENT     : −0.2 à −0.6  // parasites castrants, réduit mobilité
BEHAVIOR_FLAG_REPRODUCTION : −0.3 à −1.0  // parasites castrants (Sacculina-like)
BEHAVIOR_FLAG_ZOMBIE       : true/false    // Ophiocordyceps-like, contrôle total
```

### Coévolution — mécanisme Red Queen

```
Chaque N générations (N = 50–200 ticks générationnels) :
  host_resistance += delta_resistance  // delta ∈ [−0.1, +0.1] par mutation
  parasite_virulence += delta_virulence
  
  Si resistance > virulence → parasite population -30%
  Si virulence > resistance × 1.5 → host population -15%, virulence −0.05 (auto-régulation)
```

### Modèle Anderson & May (épidémiologie)

```
dS/dt = b(N) − β·S·I − μ·S                    // susceptibles
dI/dt = β·S·I − (μ + α + γ)·I                  // infectés
dR/dt = γ·I − μ·R                               // récupérés

b    = taux de naissance          ~ 0.01/tick
β    = taux de transmission       ~ 0.001–0.05/contact/tick
μ    = mortalité naturelle        ~ 0.002/tick
α    = mortalité due au parasite  ~ 0.01–0.20/tick
γ    = taux de guérison           ~ 0.005–0.05/tick

R₀ = β·N / (μ + α + γ)
  R₀ < 1 → extinction parasite
  R₀ > 1 → endémie
  Valeurs typiques : R₀ ∈ [0.5, 8] selon type
```

---

## Détails scientifiques

### 1. Taxonomie des relations symbiotiques

#### 1.1 Parasitisme
Relation −/+ où le parasite extrait des ressources de l'hôte au détriment de sa fitness. Distinction fondamentale :

**Par localisation :**
- **Ectoparasites** : vivent à la surface de l'hôte (tiques, puces, poux). Contact direct, transmission par proximité physique. Coût fitness modéré mais visible (comportement de grattage, allotémoin). Charge critique plus haute avant impact létal.
- **Endoparasites** : vivent dans les tissus ou cavités de l'hôte. Sous-catégories :
  - *Intracellulaires* : Plasmodium, Toxoplasma — accès aux mécanismes cellulaires, manipulation possible des signaux immunitaires
  - *Extracellulaires* : helminthes — compétition nutriments, obstruction mécanique
  - *Microsporidies* : parasites unicellulaires à cycle intracellulaire, très efficaces énergétiquement

**Par dépendance :**
- **Parasites obligatoires** : ne peuvent compléter leur cycle de vie sans hôte spécifique
- **Parasites facultatifs** : peuvent survivre hors hôte mais profitent de l'opportunité

**Par spécificité hôte :**
- **Monoxènes** : un seul hôte définitif (ex. oxyures)
- **Hétéroxènes/Dixènes** : requièrent deux hôtes (intermédiaire + définitif). Ex. Toxoplasma : rongeur → félin. Modèle très intéressant pour Primordia car implique une chaîne d'agents.

#### 1.2 Mutualisme
Relation +/+ bénéfique aux deux parties.

- **Endosymbiose obligatoire** : mitochondries (origine α-protéobactérie), chloroplastes. Dans le contexte Primordia : un agent peut héberger un symbionte interne qui augmente son métabolisme.
- **Mutualisme de nettoyage** : poissons nettoyeurs / requins. Dans Primordia : agent spécialisé nettoie les parasites d'un autre → réduction ectoparasite, gain énergie pour le nettoyeur.
- **Mutualisme de dispersion** : mycorhizes, pollinisateurs. Agent A transporte fragments/graines de l'agent B, B nourrit A.
- **Défense mutualiste** : fourmis-acacia. Agent défenseur protège territoire d'un agent ressource, reçoit nourriture en retour.

#### 1.3 Commensalisme
Relation +/0. L'un profite, l'autre est indifférent. Souvent difficile à distinguer du mutualisme car effets peuvent être minimes mais non nuls.

Exemples biologiques :
- Rémoras et requins (transport sans bénéfice/coût pour requin)
- Epiphytes sur arbres (lumière, pas de parasitisme racinaire)
- Bactéries commensales intestinales (présence sans effet mesurable)

Dans Primordia : agent qui suit un plus grand pour bénéficier de ses restes de chasse.

#### 1.4 Amensalisme
Relation −/0. Un agent nuit à l'autre sans bénéfice pour lui-même.

- Allélopathie végétale : noyer noir sécrète juglone, inhibe plantes voisines
- Antibiotiques naturels : Penicillium détruit bactéries sans en bénéficier directement
- Fouling : barnacles sur coquillages réduisent mobilité sans en tirer profit direct

Dans Primordia : excrétion de toxines environnementales, compétition par interférence.

---

### 2. Manipulation comportementale par parasites

#### 2.1 Toxoplasma gondii — modèle neurologique
Parasite intracellulaire obligatoire, cycle rongeur → félin.

**Mécanisme chez le rongeur** :
- Infection des neurones → formation de kystes dans amygdale et cortex préfrontal
- Production locale de dopamine via la tyrosine hydroxylase (enzyme encodée dans le génome du parasite)
- Réduction de la réponse à la peur (atténuation du signal olfactif prédateur)
- Effet net : rongeur infecté perd 40–70% de son comportement d'évitement des chats

**Paramètres pour Primordia** :
```
fear_response_multiplier = 1.0 - (parasite_load / THRESHOLD_LETHAL) × 0.7
// A charge max : peur réduite à 30% de la normale
dopamine_level_bonus = +0.3  // comportement plus explorateur, moins prudent
```

**Chez l'humain** : association épidémiologique avec prise de risque accrue, schizophrénie (dopamine). Non évolutif pour l'humain — effet by-product du cycle principal.

#### 2.2 Ophiocordyceps unilateralis — contrôle total
Champignon entomopathogène. Cible les fourmis charpentières (Camponotus).

**Mécanisme** :
- Invasion des fibres musculaires (pas du cerveau) via composés pharmacologiques
- Libération de sphingosines et d'acide guanobutique → contrôle moteur
- Comportement "zombie" : la fourmi grimpe 25 cm au-dessus du sol (zone optimale humidité/température pour le champignon), se fixe sur nervure foliaire à ±270° de l'axe optimal, mord
- L'hôte meurt à heure précise (corrélée à rythme circadien de l'hôte)
- Fructification 2–3 semaines après mort

**Paramètres pour Primordia** :
```
ZOMBIE_CONTROL_THRESHOLD = PARASITE_THRESHOLD_LETHAL × 0.8
// Quand charge > seuil : BEHAVIOR_FLAG_ZOMBIE = true
// Agent se dirige vers position optimale pour parasite (gradient environnemental)
// Agent meurt après N_zombie_ticks = 5–15
// Position mort → spawn_point pour spores du parasite
spore_range  = 5 unités grid
spore_count  = 50–200 spores/mort
```

#### 2.3 Leucochloridium paradoxum — manipulation visuelle
Trématode. Hôte intermédiaire : escargot. Hôte définitif : oiseau.

- Infection des tentacules oculaires de l'escargot → sporockystes pulsatiles mimant une chenille
- Escargot phobie lumière → parasite inverse cette photophobie, expose tentacules
- Oiseaux attaqués : sporockystes ingérés → cycle complété

**Principe pour Primordia** : modification des attributs visuels d'un agent pour attirer des prédateurs → vecteur de transmission.

#### 2.4 Parasites castrants
- **Sacculina** (cirripède) sur crabes : remplace gonades, contrôle comportement reproducteur
- **Glochidies** (moules) sur poissons : enkystement, croissance aux dépens du poisson

**Paramètres** :
```
castration_probability = 0.3  // si charge > THRESHOLD_CLINICAL
BEHAVIOR_FLAG_REPRODUCTION = 0.0  // stérilisation complète
energy_drain_rate *= 1.5          // coût métabolique accru
```

---

### 3. Co-évolution hôte-parasite

#### 3.1 Hypothèse de la Reine Rouge (Van Valen, 1973)
Course aux armements évolutive : hôte et parasite évoluent conjointement, chacun forçant l'autre à s'adapter pour maintenir sa fitness relative. Aucune des deux parties ne "gagne" durablement — c'est un équilibre dynamique.

**Mécanisme génétique** :
- Sélection fréquence-dépendante : allèles de résistance rares → avantageux (parasite non adapté)
- Quand allèle résistance devient commun → parasite sélectionné pour contourner cette résistance
- Cycle continu

**Implémentation Primordia** :
```
Cycle génération = 100 ticks
Chaque génération :
  Pour chaque genotype hôte (resistance_allele_frequency[i]) :
    Si parasite_strain[j] correspond → infection_rate × 1.5
    Sinon → infection_rate × 0.3
    
  Sélection naturelle : génotypes fréquents ciblés par parasite
  Génotypes rares : protégés (parasite pas adapté)
  
  Résultat : oscillations des fréquences alléliques (cycle ~200–500 ticks)
```

#### 3.2 Virulence évolutive — trade-off exploitation/transmission
Modèle Ewald/Levin : virulence optimale ≠ virulence maximale. Parasite trop virulent tue hôte avant transmission. Trop peu virulent → faible charge = faible transmission.

```
virulence_optimal = argmax(transmission_rate(v) / (μ + α(v) + γ))

Où :
  v = virulence (0.0 → 1.0)
  transmission_rate(v) = k × v^a  // augmente avec virulence, mais plateau
  α(v) = mortalité hôte ∝ v       // coût de la virulence
  
  Optimum typique : v* ∈ [0.2, 0.5] pour transmission horizontale
  Transmission verticale (mère → descendant) → sélectionne virulence basse
```

#### 3.3 Résistance vs tolérance
Distinction biologique fondamentale :

- **Résistance** : réduire la charge parasitaire (immunité active). Coût métabolique élevé (inflammation, fièvre).
- **Tolérance** : maintenir la fitness malgré charge parasitaire élevée. Pas d'élimination du parasite — co-existence.

**Pour Primordia** : deux traits distincts dans le génotype agent :
```
trait_resistance   : 0.0–1.0  // réduit parasite_load_growth_rate
trait_tolerance    : 0.0–1.0  // réduit fitness_loss_per_parasite_unit

// Trade-off possible : investir dans résistance OU tolérance
// Résistance coûte énergie/tick : energy_drain += 0.02 × trait_resistance
// Tolérance coûte moins mais le parasite continue à se répliquer
```

---

### 4. Modèles mathématiques — Anderson & May

#### 4.1 Modèle SIR classique (Anderson & May, 1979)
Voir équations dans synthèse actionnable. Extensions importantes :

**Modèle SI sans guérison** (parasites chroniques) :
```
dS/dt = b − β·S·I − μ·S
dI/dt = β·S·I − (μ + α)·I
Équilibre endémique : I* = (b/μ) × (1 − 1/R₀)
```

**Modèle macroparasite** (helminthes — charge variable) :
```
dM/dt = Λ(t) − (μ_p + μ_h + γ)·M
// M = charge parasitaire moyenne dans la population
// Λ = taux d'acquisition
// Distribution négative binomiale de la charge (agrégation typique)
// k = paramètre d'agrégation ∈ [0.1, 1.0] — faible k = forte agrégation
```

#### 4.2 R₀ — nombre de reproduction de base

```
R₀ = β × N / (μ + α + γ)

Seuil d'extinction : R₀ < 1
Épidémie : R₀ > 1
Herd immunity threshold : 1 − 1/R₀

Exemples biologiques réels :
  Rougeole          R₀ ≈ 12–18
  Grippe saisonnière R₀ ≈ 2–3
  Paludisme          R₀ ≈ 5–100 (dépend de la densité moustiques)
  VIH               R₀ ≈ 2–5
```

#### 4.3 Dynamique de la charge parasitaire par agent
```
load(t+1) = load(t) × replication_rate
           + contacts × β × (load_source / MAX_LOAD)
           - load(t) × (decay_rate + resistance_effect)
           - treatment_effect

// Agrégation : 20% des hôtes portent 80% des parasites (règle 80/20)
// Implémenter via distribution de susceptibilité dans la population
```

---

### 5. Impact sur fitness de l'agent simulé

#### 5.1 Composantes de fitness affectées

| Composante | Parasite léger (<50) | Parasite modéré (50–100) | Parasite lourd (>100) |
|---|---|---|---|
| Vitesse de déplacement | −5% | −20% | −45% |
| Efficacité fourragement | −10% | −30% | −60% |
| Reproduction | −5% | −25% | −70% |
| Détection prédateurs | −0% | −15% | −40% |
| Espérance de vie | −2% | −20% | −60% |
| Coût immunitaire | +5% énergie | +15% énergie | +25% énergie |

#### 5.2 Bénéfices de la tolérance symbiotique
Un agent porteur d'un parasite à faible virulence peut bénéficier de résistances croisées (primo-infection par souche faible → protection contre souche forte) :

```
cross_immunity_bonus = 0.3 × trait_tolerance
// Réduit de 30% l'infection_rate pour parasites du même groupe taxonomique
```

#### 5.3 Coûts de la symbiose mutualiste
Même les relations bénéfiques ont des coûts :

- **Mutualisme obligatoire** : dépendance — si symbionte absent, fitness chute de 40–80%
- **Coût immunitaire** : hôte doit tolérer le symbionte → allocation immunitaire réduite contre d'autres pathogènes
- **Coût comportemental** : comportements de maintenance (grooming, attractance symbiontes) → temps non alloué à d'autres activités

```
dependency_penalty = 0.6 × is_obligate_mutualist × symbiont_absent
maintenance_cost   = 0.05 × symbiont_diversity  // énergie/tick
immune_tolerance_cost = 0.10 × mutualist_load   // réduction défense générale
```

---

### 6. Dynamiques de population — effets macroscopiques

#### 6.1 Régulation des populations
Les parasites sont des régulateurs démographiques majeurs (Anderson & May, 1978). Supprimer les parasites d'une simulation → explosion démographique des hôtes → effondrement ressources → crash population. Cycles prédateur-proie classiques sont modifiés par parasites.

**Cycle typique avec parasite** :
```
Population hôte ↑ → Contact rate ↑ → Prévalence parasite ↑
→ Fitness hôte ↓ → Mortalité ↑ → Population hôte ↓
→ Parasite decline (R₀ < 1 à faible densité hôte)
→ Population hôte récupère → cycle recommence

Période oscillation : 3–10× temps de génération hôte
Amplitude : 20–60% de variation autour de l'équilibre
```

#### 6.2 Virulence et structure sociale
- Parasites à transmission fécale-orale → sélectionnent contre comportements de regroupement
- Parasites sexuellement transmis → contre-sélectionnent la promiscuité
- Parasites vectoriels → sélectionnent pour comportements d'évitement du vecteur

**Pour Primordia** : les comportements sociaux émergents peuvent être co-déterminés par la pression parasitaire — un paramètre évolutif, pas seulement environnemental.

#### 6.3 Immunité collective
```
herd_immunity_threshold = 1 − 1/R₀

// Au-dessus de ce seuil d'agents résistants : extinction parasite certaine
// En dessous : endémie possible

Exemples :
  R₀ = 2 → 50% résistants suffisent
  R₀ = 5 → 80% résistants requis
  R₀ = 10 → 90% résistants requis
```

---

### 7. Références biologiques clés

- **Anderson, R.M. & May, R.M. (1979)** — "Population biology of infectious diseases" — Nature 280. Fondamental pour dynamique macroparasite.
- **Van Valen, L. (1973)** — "A new evolutionary law" — Evolutionary Theory 1. Hypothèse Reine Rouge.
- **Ewald, P.W. (1994)** — "Evolution of Infectious Disease" — Oxford. Trade-off virulence/transmission.
- **Hughes et al. (2011)** — Mécanisme Ophiocordyceps, muscle vs cerveau — BMC Ecology.
- **Webster, J.P. (2007)** — Toxoplasma et comportement rongeur — Parasitology 134.
- **Sacculina** : Høeg & Lützen (1995) — Advances in Parasitology 35.
- **Leucochloridium** : Wesołowska & Wesołowski (2014) — Journal of Zoology 292.
