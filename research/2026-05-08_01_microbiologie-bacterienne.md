# Microbiologie Bactérienne — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Microbiologie bactérienne
**État** : final
**Sources** : Connaissances de formation (corpus scientifique couvert jusqu'à août 2025) — Berg HC "E. coli in Motion" (2004), Madigan et al. "Brock Biology of Microorganisms" (16e éd.), Bassler BL quorum sensing reviews, Errington J sporulation reviews, Nikaido H outer membrane reviews.

---

## Synthèse actionnable pour la simulation

### Valeurs numériques directement utilisables dans Godot

| Paramètre | Valeur réelle | Valeur simulée suggérée |
|---|---|---|
| Taille bactérie (E. coli) | 1–5 µm de long, 0.5–1 µm de large | 1 pixel = 0.1 µm → sprite 5–15 px |
| Temps de division (optimal) | 20 min (E. coli 37°C) | tick_division = 1200 frames @60fps |
| Temps de division (lent) | 1–24h selon espèce/condition | multiplier × conditions |
| Vitesse de déplacement flagellé | 20–50 µm/s | ~2–5 px/frame @60fps |
| Vitesse de nage (Vibrio) | jusqu'à 200 µm/s | jusqu'à 20 px/frame |
| Durée run (chimiotaxie) | ~1 s moyenne | 60 frames |
| Durée tumble | ~0.1 s | 6 frames |
| Seuil quorum sensing | ~10⁷–10⁸ bactéries/mL | configurable : N > 50 entités dans rayon |
| Sporulation déclenchée après | ~1–2h de famine | 3600–7200 frames sans nutriment |
| Germination spore (conditions optimales) | 30 min – 2h | 1800–7200 frames |
| Survie spore (dormance) | Années à siècles | en jeu : permanent jusqu'à trigger |
| Taux de mutation par division | ~10⁻⁷ par gène par génération | P(mutation) = 0.0001 par division |
| Énergie consommée (ATP) | ~10⁹ molécules ATP/seconde | energy_cost = 1 unit/frame, division = 100 units |

---

## Détails scientifiques

### 1. Cycle de vie bactérien

**Phases de croissance (en culture) :**
1. **Phase lag** : adaptation au milieu, synthèse enzymatique, pas de division. Durée : 30 min à plusieurs heures.
2. **Phase exponentielle (log)** : division binaire à taux maximal. Population double à chaque génération. C'est ici que la simulation est la plus active.
3. **Phase stationnaire** : épuisement des nutriments ou accumulation de déchets → taux de division = taux de mort. Population stable.
4. **Phase de déclin (mort)** : mort > naissance. Population s'effondre.

**Division binaire :**
- Réplication de l'ADN circulaire → ségrégation des chromosomes → formation du septum (anneau de FtsZ au centre) → scission en deux cellules filles identiques.
- Chaque cellule fille est génétiquement identique à la mère sauf mutation.
- Condition : assez d'énergie (ATP) + nutriments (azote, carbone, phosphore).

**Mort bactérienne — causes :**
- Famine énergétique : réserves épuisées → lyse
- Toxines environnementales
- pH extrême, température létale
- Attaque du système immunitaire / prédation (phages, protozoaires)
- Compétition interspécifique (antibiotiques produits par voisins)

**Pour la simulation — états à implémenter :**
```
STATES = [LAG, GROWING, DIVIDING, STATIONARY, DYING, DEAD, SPORE]
energy: float  # 0.0–1.0
nutrients_available: bool
```

---

### 2. Chimiotaxie

**Mécanisme run-and-tumble :**
- La bactérie alterne entre deux modes :
  - **Run** : flagelles en rotation CCW → faisceau coordonné → déplacement rectiligne ~1 s
  - **Tumble** : un flagelle passe en CW → faisceau se défait → réorientation aléatoire ~0.1 s
- L'orientation après tumble est aléatoire (pas dirigée), mais la **fréquence de tumble est modulée** selon le gradient chimique.

**Signalisation moléculaire :**
- Récepteurs membranaires (MCPs) détectent attractants (glucose, acides aminés) et répulsifs (ions H⁺, toxines).
- Attractant détecté → phosphorylation réduite de CheY → moins de tumbles → runs plus longs vers la source.
- Répulsif détecté → plus de tumbles → changement de direction fréquent (fuite).
- Adaptation : méthylation des récepteurs → la bactérie "oublie" le gradient passé et se recalibre sur le gradient présent.

**Gradients chimiques en jeu :**
- Attractants : glucose, acides aminés, O₂ (aérobies)
- Répulsifs : acides (pH bas), éthanol, antibiotiques, lumière UV

**Pour la simulation — algorithme simplifié :**
```gdscript
func update_run_tumble():
    var gradient = sample_chemical_gradient(position)
    var tumble_probability = base_tumble_rate * (1.0 - gradient_bias * gradient)
    if randf() < tumble_probability:
        direction = Vector2.from_angle(randf() * TAU)  # tumble
    else:
        position += direction * run_speed * delta  # run
```

---

### 3. Sporulation

**Espèces concernées :** Bacillus subtilis (gram+), Clostridium (gram+, anaérobie). Les gram- ne sporulent pas.

**Conditions déclenchantes (par ordre de priorité) :**
1. Famine en carbone, azote ou phosphore (signal principal)
2. Surpopulation (densité trop élevée)
3. Stress : chaleur, dessication, pH extrême
4. Signal quorum (Spo0A phosphorylation cascade, déclenchée par AIs)

**Stades de sporulation (Bacillus) :**
| Stade | Description | Durée approximative |
|---|---|---|
| 0 | Cellule végétative normale | — |
| I | Condensation chromosome axial | 0–30 min |
| II | Formation du pré-septum polaire | 30–60 min |
| III | Engulfment du pré-spore | 1–2h |
| IV–V | Synthèse du cortex + coat protéique | 2–4h |
| VI–VII | Maturation, libération de la spore | 4–8h total |

**État de dormance :**
- Métabolisme quasi nul (< 1% activité normale)
- Résistance extrême : chaleur (> 100°C), UV, dessication, acide, antibiotiques
- Durée : indéfinie (spores viables retrouvées après 250 millions d'années dans du sel)

**Germination (réveil) :**
- Déclenchée par : nutriments disponibles (L-alanine, glucose), eau, chaleur modérée
- Processus : activation → initiation → élongation → croissance végétative
- Durée : 30 min – 2h

**Pour la simulation :**
```gdscript
func check_sporulation():
    if energy < 0.1 and nutrient_level < 0.05 and is_gram_positive:
        if sporulation_timer > SPORULATION_THRESHOLD:
            transition_to(STATES.SPORE)

func check_germination():
    if state == STATES.SPORE:
        if nutrient_level > 0.3 and temperature_ok:
            transition_to(STATES.LAG)
```

---

### 4. Résistance et Adaptation

**Mécanismes de résistance aux antibiotiques :**

| Mécanisme | Description | Exemple |
|---|---|---|
| Pompes efflux | Exportent l'antibiotique hors de la cellule | Résistance fluoroquinolones |
| Enzymes de dégradation | Dégradent la molécule active | Bêta-lactamases → pénicilline |
| Modification de cible | La cible cellulaire change de forme | Résistance méthicilline (MRSA) |
| Imperméabilité | Réduction des porines membranaires | Gram- multi-résistants |
| Biofilm | Matrice extracellulaire protectrice | Résistance × 1000 |

**Mutation et pression sélective :**
- Taux de mutation spontanée : ~10⁻⁷ à 10⁻¹⁰ par paire de bases par réplication
- En présence d'antibiotiques : seules les mutantes résistantes survivent → sélection rapide
- Transfert horizontal de gènes (HGT) : résistance partagée via plasmides entre bactéries non apparentées (conjugaison, transformation, transduction)

**HGT — mécanismes :**
- **Conjugaison** : contact direct, transfert plasmide via pili. Portée : contact physique.
- **Transformation** : absorption d'ADN libre dans l'environnement.
- **Transduction** : phage bactérien transporte de l'ADN entre bactéries.

**Pour la simulation :**
```gdscript
var resistance_traits: Dictionary = {
    "antibiotic_efflux": false,
    "beta_lactamase": false,
    "biofilm_producer": false
}

func on_division():
    var child = spawn_child()
    # Transmission des traits + possible mutation
    for trait in resistance_traits:
        child.resistance_traits[trait] = resistance_traits[trait]
        if randf() < MUTATION_RATE:  # 0.0001
            child.resistance_traits[trait] = !child.resistance_traits[trait]
    
    # HGT via conjugaison si voisine proche
    var neighbor = find_nearest_bacterium(MAX_CONJUGATION_RANGE)
    if neighbor and randf() < CONJUGATION_RATE:  # 0.001
        neighbor.resistance_traits.merge(resistance_traits)
```

---

### 5. Gram+ vs Gram-

**Différences structurelles fondamentales :**

| Caractéristique | Gram+ | Gram- |
|---|---|---|
| Paroi peptidoglycane | Épaisse (20–80 nm) | Fine (2–7 nm) |
| Membrane externe | Absente | Présente (LPS) |
| Espace périplasmique | Faible | Important |
| Coloration Gram | Violet (retient cristal violet) | Rose (décolorée) |
| Sensibilité pénicilline | Élevée | Faible (membrane externe) |
| Résistance naturelle | Moindre | Plus grande (double membrane) |
| Sporulation | Possible (Bacillus, Clostridium) | Non |
| LPS (endotoxine) | Absent | Présent → réponse inflammatoire |

**Exemples gram+ :** Staphylococcus aureus, Streptococcus, Bacillus, Clostridium, Lactobacillus
**Exemples gram- :** E. coli, Salmonella, Pseudomonas, Vibrio, Helicobacter pylori

**Impact gameplay :**
- Gram+ : plus sensibles aux antibiotiques ciblant la paroi, peuvent sporuler
- Gram- : double membrane → résistance naturelle accrue, LPS peut déclencher réponse immunitaire de l'hôte

```gdscript
enum GramType { POSITIVE, NEGATIVE }

var gram_type: GramType
var base_antibiotic_resistance: float:
    get:
        return 0.2 if gram_type == GramType.POSITIVE else 0.5
var can_sporulate: bool:
    get:
        return gram_type == GramType.POSITIVE
```

---

### 6. Types Métaboliques

**Aérobie strict :**
- Requiert O₂ pour la respiration cellulaire
- Chaîne respiratoire → ATP maximal (~30–32 ATP/glucose)
- Exemples : Pseudomonas aeruginosa, Mycobacterium tuberculosis
- En jeu : se déplace vers zones riches en O₂, meurt en anaérobie

**Anaérobie strict :**
- O₂ est toxique (absence de superoxyde dismutase)
- Fermentation ou respiration anaérobie → ATP faible (~2–4 ATP/glucose)
- Exemples : Clostridium, Bacteroides
- En jeu : fuit les zones oxygénées, prospère dans zones profondes/sans O₂

**Anaérobie facultatif :**
- Utilise O₂ si disponible, bascule en fermentation sans
- Exemples : E. coli, Staphylococcus aureus (le plus polyvalent)
- En jeu : s'adapte → métabolisme plus coûteux mais survie étendue

**Microaérophile :**
- Requiert de faibles concentrations d'O₂ (2–10%, vs 21% atmosphérique)
- Exemples : Helicobacter pylori, Campylobacter
- En jeu : cherche gradient O₂ précis, zone cible étroite

**Extrémophiles :**
| Type | Condition optimale | Exemple |
|---|---|---|
| Thermophile | 50–80°C | Thermus aquaticus |
| Hyperthermophile | > 80°C | Pyrococcus furiosus |
| Psychrophile | 0–15°C | Polaromonas vacuolata |
| Halophile | > 15% NaCl | Halobacterium |
| Acidophile | pH 1–4 | Acidithiobacillus |
| Alcaliphile | pH 9–12 | Natronobacterium |
| Barophile | > 100 atm | Shewanella benthica |

**Pour la simulation :**
```gdscript
var metabolism_type: String  # "aerobe", "anaerobe", "facultative", "microaerophile"
var optimal_o2: float        # 0.0–1.0
var o2_tolerance: float      # largeur de la plage viable

func get_metabolism_efficiency(local_o2: float) -> float:
    var delta = abs(local_o2 - optimal_o2)
    return max(0.0, 1.0 - (delta / o2_tolerance))
```

---

### 7. Quorum Sensing

**Principe :**
Les bactéries sécrètent en permanence de petites molécules signal appelées **autoinducteurs (AI)**. Quand leur concentration dépasse un seuil (reflétant une densité de population élevée), des gènes cibles sont activés collectivement.

**Gram- : système LuxI/LuxR (acyl-homoserine lactones, AHL)**
- LuxI : enzyme qui synthétise l'AHL
- L'AHL diffuse librement à travers les membranes
- À haute densité : AHL s'accumule → lie LuxR → activation transcriptionnelle
- Comportements déclenchés : bioluminescence (Vibrio fischeri), formation de biofilm, sécrétion de toxines, sporulation

**Gram+ : peptides signal (CSP, AIP)**
- Peptides sécrétés activement, détectés par récepteurs à deux composants
- Système plus spécifique à l'espèce → moins de cross-talk

**AI-2 : système universel**
- Molécule signal produite par gram+ et gram-
- Permet communication inter-espèces
- Synthèse via LuxS

**Seuils numériques :**
- Densité de déclenchement typique : 10⁷–10⁸ cellules/mL
- Concentration d'AHL déclenchante : ~10–100 nM
- Rayon de diffusion effectif en milieu liquide : centaines de µm

**Comportements déclenchés par quorum :**
- Formation de biofilm (protection collective)
- Sécrétion de toxines / enzymes de virulence
- Sporulation coordonnée
- Compétence génétique (absorption d'ADN)
- Bioluminescence
- Inhibition de la croissance des compétiteurs

**Pour la simulation :**
```gdscript
class_name QuorumSensor

const QS_RANGE := 50.0          # pixels — rayon de détection
const QS_THRESHOLD := 10        # nombre de voisins pour activer
const AI_EMISSION_RATE := 0.1   # unités/frame

var local_ai_concentration: float = 0.0
var quorum_active: bool = false

func update_quorum(neighbors: Array) -> void:
    local_ai_concentration = neighbors.size() * AI_EMISSION_RATE
    quorum_active = neighbors.size() >= QS_THRESHOLD
    
    if quorum_active:
        parent.activate_quorum_behaviors()  # biofilm, toxines, etc.

func activate_quorum_behaviors() -> void:
    if not biofilm_formed and energy > 0.5:
        form_biofilm()
    virulence_factor = min(virulence_factor * 1.5, MAX_VIRULENCE)
```

**Inhibition du quorum sensing (anti-virulence) :**
- Certaines plantes et bactéries produisent des quorum quenchers (dégradation des AHL)
- Stratégie thérapeutique alternative aux antibiotiques
- En jeu : événement possible — molécule environnementale désactive le QS d'un groupe

---

## Récapitulatif — Variables de simulation prioritaires

```gdscript
# BacteriumBase.gd — propriétés core
var species_id: String
var gram_type: GramType             # POSITIVE | NEGATIVE
var metabolism_type: String         # aerobe | anaerobe | facultative | microaerophile
var can_sporulate: bool             # = gram_type == POSITIVE

var energy: float                   # 0.0–1.0
var size: float                     # µm (1.0–5.0)
var age: float                      # frames depuis naissance
var generation: int                 # compteur de divisions

# Mouvement
var run_speed: float                # px/frame (2.0–20.0 selon espèce)
var base_tumble_rate: float         # 0.0–1.0
var chemotaxis_bias: float          # sensibilité gradient

# Division
var division_threshold: float      # énergie min pour diviser (0.7)
var division_cooldown: float        # frames entre divisions (1200 = 20min @60fps)

# Résistance
var resistance_traits: Dictionary
var antibiotic_resistance: float    # 0.0–1.0

# Quorum
var ai_secretion_rate: float        # autoinducteur/frame
var quorum_active: bool

# État
var state: int                      # LAG | GROWING | DIVIDING | STATIONARY | DYING | DEAD | SPORE
```

---

## Notes de game design

1. **Performance** : à haute densité, ne pas simuler chaque bactérie individuellement → spatial hashing + LOD comportemental (bactéries lointaines = update toutes les 10 frames).

2. **Gradients chimiques** : stocker dans une grille 2D (texture float) mise à jour par diffusion-dissipation chaque frame. Évite de calculer la distance à chaque source pour chaque bactérie.

3. **Quorum en grille** : bucket spatial → comptage local O(1) au lieu de O(N²).

4. **Sporulation** : les spores n'ont besoin d'aucun update logique → pool séparé, très peu coûteux.

5. **Mutation visuelle** : légère variation de teinte sur les mutantes résistantes pour que le joueur voie l'évolution en temps réel.

6. **Échelle de temps** : 1 seconde de jeu = 1 minute réelle → division toutes les 20s de jeu. Accélérable via time_scale.
