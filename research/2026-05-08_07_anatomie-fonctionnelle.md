# Anatomie Fonctionnelle — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Anatomie fonctionnelle
**État** : final
**Sources** : connaissances corpus (biologie/médecine établie)

---

## Synthèse actionnable pour la simulation

| Paramètre | Valeur simulable | Notes |
|---|---|---|
| Volume sanguin | 7% du poids corporel | 70 mL/kg chez humanoïde |
| Seuil hémorragique léger | -10% volume | Tachycardie compensatoire |
| Seuil hémorragique grave | -30% volume | Choc hypovolémique |
| Seuil létal | -40% volume | Mort sans intervention |
| Seuil lactate fatigue | 4 mmol/L | Transition aérobie→anaérobie |
| Temps réaction réflexe | 15–50 ms | Spinal, involontaire |
| Temps réaction volontaire | 150–300 ms | Cortical |
| Fièvre modérée | 38.5°C | Activation immunitaire |
| Fièvre critique | 40°C | Convulsions possibles |
| Fièvre létale | ≥42°C | Dénaturation protéique |
| BMR petit animal (~20g) | ~20 kcal/jour | Formule Kleiber |
| BMR grand herbivore (~500kg) | ~8700 kcal/jour | Formule Kleiber |
| Atrophie musculaire | -1 à -3% masse/semaine | Par inactivité totale |
| VO2max élite humain | 70–85 mL/kg/min | Référence |
| Coagulation primaire | 1–3 min | Plug plaquettaire |
| Coagulation complète | 5–10 min | Fibrine |

---

## Détails scientifiques

---

### 1. Système Sanguin

#### Volume et composition
- Volume sanguin total : **7% du poids corporel** (≈ 70 mL/kg)
  - Humanoïde 70 kg → ~5 L de sang
  - Petit mammifère 500 g → ~35 mL
  - Insecte/arthropode → hémolymphe, pas de séparation plasma/cellules
- Hématocrite normal : 38–52% (globules rouges / volume total)
- Hémoglobine : 12–17 g/dL selon sexe/espèce
- Durée de vie d'un globule rouge : **120 jours**

#### Transport d'O2 et nutriments
- Chaque molécule d'hémoglobine transporte **4 molécules d'O2**
- Saturation O2 normale : SaO2 ≥ 95%
- Saturation critique : SaO2 < 90% → hypoxie tissulaire
- Saturation létale (aiguë) : SaO2 < 70%
- Débit cardiaque repos : 5 L/min
- Débit cardiaque effort maximal : 20–25 L/min

#### Seuils hémorragiques critiques
| Classe | Perte volume | Symptômes | FC | TA systolique |
|---|---|---|---|---|
| Classe I | < 15% (~750 mL) | Aucun | < 100 bpm | Normale |
| Classe II | 15–30% (750–1500 mL) | Anxiété, tachycardie | 100–120 bpm | Normale ou ↑ |
| Classe III | 30–40% (1500–2000 mL) | Confusion, hypotension | 120–140 bpm | 70–90 mmHg |
| Classe IV | > 40% (> 2000 mL) | Perte de conscience, mort | > 140 bpm | < 70 mmHg |

- **10% de perte** : compensé spontanément, symptômes discrets
- **20% de perte** : choc hypovolémique compensé, intervention nécessaire
- **40% de perte** : choc décompensé, seuil létal sans transfusion immédiate
- Hémorragie interne : identique en lésions, mais invisible — le danger est le retard de détection

#### Coagulation
- Phase primaire (plug plaquettaire) : **1–3 minutes**
- Phase secondaire (cascade coagulation / fibrine) : **5–10 minutes**
- Lysis du caillot (fibrinolyse) : 24–72 heures
- Facteurs inhibiteurs : hypothermie (< 35°C), acidose (pH < 7.1), dilution (transfusion massive)
- Hémophilie simulée : absence de facteurs VIII ou IX → coagulation absente

#### Simulation
```gdscript
const BLOOD_VOLUME_RATIO = 0.07  # 7% du poids
const HEMORRHAGE_THRESHOLDS = {
    "light":    0.10,   # 10% → tachycardie légère
    "moderate": 0.20,   # 20% → choc compensé
    "severe":   0.30,   # 30% → choc décompensé
    "lethal":   0.40    # 40% → mort
}
const COAGULATION_RATE = 0.005  # 0.5% du volume/min si plaie non traitée
```

---

### 2. Système Musculaire

#### Types de fibres
| Type | Nom | Vitesse | Fatigue | Métabolisme | Usage |
|---|---|---|---|---|---|
| I | Lentes (SO) | Lente | Faible | Aérobie (oxydatif) | Endurance, posture |
| IIa | Rapides intermédiaires (FOG) | Rapide | Modérée | Mixte | Course prolongée |
| IIb / IIx | Rapides (FG) | Très rapide | Élevée | Anaérobie (glycolytique) | Sprints, sauts |

- Fibres de type I : ~50% chez humain sédentaire, 70–80% chez marathon
- Fibres de type II : plus développées chez sprinter, prédateur à embuscade (lion, guépard)
- Muscle cardiaque (myocarde) : type intermédiaire, ne fatigue jamais en conditions normales

#### Métabolisme de la fatigue
- Seuil lactate : **4 mmol/L** (aussi noté "seuil anaérobie")
  - En dessous : aérobie, durable
  - Au-dessus : production acide lactique > élimination → acidose musculaire → crampes
- Baisse de pH musculaire de 7.0 à 6.4 lors d'effort maximal
- Déplétion glycogène musculaire : après 90–120 min d'effort intense → "mur"
- Resynthèse du glycogène : 24–48 heures avec alimentation adéquate

#### Temps de récupération
| Effort | Type | Récupération complète |
|---|---|---|
| Sprint 10 sec | PCr (phosphocréatine) | 3–5 min |
| Effort intense 1 min | Anaérobie lactique | 20–30 min |
| Effort soutenu 60 min | Aérobie/glycogène | 24–48 h |
| Entraînement résistance | Micro-déchirures | 48–72 h |
| Trauma musculaire (DOMS) | Réparation structurelle | 3–7 jours |

#### Atrophie et hypertrophie
- Atrophie par inactivité : **-1 à -3% de masse musculaire par semaine** (alitement complet)
- Atrophie de dénervation (nerf sectionné) : plus rapide, -5% semaine, irréversible sans réinnervation
- Hypertrophie : +0.1 à 0.3% par semaine en entraînement optimal
- Cachexie (cancer, sepsis) : -5 à -10% par semaine

#### Force et puissance
- Force maximale d'un muscle : ~30 N/cm² de section transversale
- Puissance humain moyen : ~70–100 W en continu, ~1000 W en sprint 1 sec
- Effet levier osseux : force effective multipliée selon structure squelettique

---

### 3. Système Nerveux Simplifié

#### Temps de réaction
| Type | Temps | Substrat neurologique |
|---|---|---|
| Réflexe monosynaptique (myotatique) | 15–30 ms | Moelle épinière |
| Réflexe polysynaptique (retrait) | 50–150 ms | Moelle épinière |
| Réaction simple (son → bouton) | 150–200 ms | Cortex moteur |
| Réaction complexe (choix) | 200–400 ms | Cortex préfrontal |
| Réaction fatigué/blessé | +20 à +100% baseline | Inhibition |

- Vitesse de conduction nerveuse : 0.5 m/s (fibres C, douleur lente) à 70 m/s (fibres Aα, motricité)
- Délai synaptique : 0.5–1 ms par synapse

#### Douleur et nociception
- Seuil de douleur : variable selon espèce, état émotionnel, contexte
- Douleur aiguë : signal d'alarme, fibres Aδ (rapide, localisée)
- Douleur chronique : fibres C (lente, diffuse), souvent déconnectée du tissu
- Endorphines endogènes : analgésie en situation de stress extrême (combat) → possible ignorer blessure

#### Apprentissage conditionné
- Conditionnement classique (Pavlov) : 5–50 associations pour acquis
- Extinction : 10–30 essais sans renforcement
- Réponse conditionnée de peur : très persistante, résistante à l'extinction (amygdale)
- Mémoire procédurale (ganglions de la base) : stable même sous stress extrême
- Mémoire de travail (cortex préfrontal) : dégradée sous cortisol élevé

#### Altérations
- Hypoglycémie < 50 mg/dL : confusion, tremblements, agressivité
- Hypoglycémie < 30 mg/dL : perte de conscience, convulsions
- Hypoxie (SaO2 < 85%) : confusion en 5–10 min
- Hypoxie (SaO2 < 70%) : perte de conscience en 2–5 min
- Hypothermie (< 32°C) : confusion, ralentissement cognitif
- Hypothermie (< 28°C) : arythmie, perte de conscience

---

### 4. Organes Vitaux

#### Cœur
- Fréquence cardiaque repos : **60–100 bpm** (humanoïde)
  - Athlète entraîné : 40–50 bpm
  - Petit mammifère (<1 kg) : 200–600 bpm
  - Baleine : 10–30 bpm
- Fréquence maximale effort : **220 - âge** (formule Haskell) ≈ 180–220 bpm adulte
- Zone de dangerosité : FC > 200 bpm prolongée → arythmie possible
- Débit cardiaque (Q) = VES × FC (Volume d'éjection systolique × Fréquence)
  - Repos : Q ≈ 5 L/min
  - Effort max : Q ≈ 20–25 L/min
- Défaillance cardiaque : FC > 180 bpm + hypotension → choc cardiogénique
- Arrêt cardiaque : survie sans réanimation ≤ 4–6 min (lésions cérébrales irréversibles)

#### Poumons et VO2max
- Volume courant repos : 500 mL/respiration, 12–20 respi/min → 6–10 L/min
- Volume courant effort : 2–3 L/respiration, 40–60 respi/min → 80–120 L/min
- VO2max :
  - Sédentaire humain : 30–40 mL/kg/min
  - Entraîné : 55–65 mL/kg/min
  - Élite (ski fond, cyclisme) : 70–85 mL/kg/min
  - Cheval pur-sang : 150–180 mL/kg/min
  - Chien de traîneau en course : 240 mL/kg/min
- Hypoxie altitude : VO2max diminue ~1% par 100 m au-delà de 1500 m

#### Foie
- Détoxification : métabolise médicaments, alcool, ammoniaque, bilirubine
- Alcool : métabolisme de **0.1 g/kg/h** → ~7 g/h pour 70 kg → 1 verre standard/heure
- Régénération hépatique : le foie peut se régénérer jusqu'à 70% de perte de masse en 4–6 semaines
- Défaillance hépatique aiguë : > 80% de nécrose → mort en 1–2 jours sans transplant
- Glycogène hépatique stocké : ~100 g (vs 400 g musculaire) → glucose systémique maintenu ~4–8h à jeun

#### Reins
- Filtration glomérulaire (DFG) : **120 mL/min** (180 L/jour filtrés, 1.5 L urine excrétée)
- Elimination de déchets : créatinine, urée, potassium, H+
- Défaillance rénale aiguë : DFG < 15 mL/min → dialyse nécessaire
- Ischémie rénale tolérance : **20–30 min** à chaud (sans sang)
- Accumulation urée (urémie) : létale en 1–3 semaines sans traitement
- Déshydratation critique : urine < 0.5 mL/kg/h → insuffisance rénale imminente

---

### 5. Métabolisme Énergétique

#### Loi de Kleiber — BMR selon la masse
**BMR (kcal/jour) = 70 × M^0.75** (M en kg)

| Animal | Masse | BMR estimé |
|---|---|---|
| Souris | 0.02 kg | ~4 kcal/j |
| Rat | 0.3 kg | ~30 kcal/j |
| Chat | 4 kg | ~185 kcal/j |
| Humain | 70 kg | ~1700 kcal/j |
| Loup | 40 kg | ~1100 kcal/j |
| Cheval | 500 kg | ~8700 kcal/j |
| Vache | 600 kg | ~10200 kcal/j |
| Éléphant | 4000 kg | ~50000 kcal/j |

- Correction temperature corporelle : endothermie coûte ~5× plus cher que ectothermie à masse égale
- Un reptile 70 kg dépense ~340 kcal/j (vs 1700 pour mammifère)

#### ATP et substrats
- ATP disponible immédiat (pool libre) : ~3 sec d'effort maximal
- PCr (phosphocréatine) : 8–10 sec supplémentaires
- Glycolyse anaérobie : 30–90 sec supplémentaires (lactate produit)
- Oxydation du glucose (aérobie) : 1–2h selon glycogène disponible
- Oxydation des lipides : quasi-illimitée en temps, mais lente (max ~50% VO2max)

#### Dépense par activité (humanoïde 70 kg)
| Activité | Dépense |
|---|---|
| Sommeil / repos | 1 kcal/min |
| Marche lente | 3–4 kcal/min |
| Course 10 km/h | 10–12 kcal/min |
| Sprint | 20–25 kcal/min |
| Combat intense | 15–20 kcal/min |
| Thermorégulation froid extrême | +30 à +100% BMR |

#### Conséquences de la privation
- Jeûne complet : glycogène épuisé en **18–24h**, puis lipolyse, puis catabolisme protéique
- Hypoglycémie symptomatique : glycémie < **3.5 mmol/L** (63 mg/dL)
- Hypoglycémie critique : < **2.5 mmol/L** (45 mg/dL) → coma
- Déshydratation 1–2% : performance cognitive -10 à -20%
- Déshydratation 5–7% : hallucinations, défaillance organique
- Déshydratation > 10–15% : mort

---

### 6. Blessures et Guérison

#### Types de dommages tissulaires
| Type | Description | Guérison |
|---|---|---|
| Contusion | Écrasement sans plaie ouverte | 3–14 jours |
| Lacération | Déchirure cutanée | 7–21 jours |
| Fracture simple | Os cassé, fragments alignés | 4–8 semaines |
| Fracture comminutive | Fragments multiples | 3–6 mois |
| Rupture ligamentaire | Ligament déchiré | 6–12 semaines |
| Rupture tendineuse | Tendon sectionné | 3–6 mois sans chirurgie |
| Brûlure 1er degré | Épiderme seul | 3–7 jours |
| Brûlure 2e degré | Derme atteint | 14–21 jours |
| Brûlure 3e degré | Derme détruit | Non spontanée, greffe |
| Lésion moelle épinière | Section partielle | Variable, 0–18 mois |

#### Taux de régénération tissulaire
- Peau (lacération) : ~1 mm/jour de fermeture par contraction
- Os (fracture) : cal osseux apparent à J14, consolidation J42–56
- Muscle (déchirure partielle) : fibrocicatrice en 2–4 semaines, rémodelage 2–3 mois
- Nerf périphérique : repousse axonale **1–3 mm/jour** → nerf de 30 cm = 10–30 semaines
- Nerf central (SNC) : régénération quasi nulle (inhibition myéline centrale)
- Foie : régénération rapide, 70% résection → reconstitué en 4–6 semaines
- Rein : aucune régénération néphron (cellules de remplacement, pas nouvelles unités)
- Cardiomyocytes : renouvellement ~1%/an, pas de régénération fonctionnelle post-infarctus

#### Seuils de mort par blessure
- Perte de sang > 40% volume → létal sans traitement
- Destruction cerveau (tronc cérébral) → mort immédiate
- Écrasement thorax (pneumothorax compressif) → mort en 5–15 min
- Sepsis sans traitement → mort en 24–72h
- Brûlures > 60% surface corporelle → létalité > 90% sans réanimation lourde
- Section aorte / artère principale → mort en 30 sec à 3 min

---

### 7. Impact des Maladies

#### Fièvre — seuils fonctionnels
| Température | Stade | Effets |
|---|---|---|
| 37.0°C | Normal | Baseline |
| 37.5°C | Subfébrile | Léger inconfort |
| 38.5°C | Fièvre modérée | Activation immunitaire, +10% BMR |
| 39.5°C | Fièvre élevée | Fatigue marquée, tachycardie |
| 40.0°C | Fièvre critique | Convulsions possibles, confusion |
| 41.0°C | Hyperpyrexie | Dommages cellulaires, rhabdomyolyse |
| 42.0°C | Létal | Dénaturation enzymatique, mort en heures |

- Dépense énergétique : +10% par degré Celsius au-dessus de 37°C
- Avantage : fièvre inhibe réplication bactérienne et virale, active immunité
- Inconvénient : déshydratation accélérée, dénaturation protéique si prolongée

#### Inflammation
- Phase aiguë (0–72h) : vasodilatation, oedème, afflux neutrophiles
- Phase chronique (> 2 semaines) : macrophages, fibrose
- Inflammation systémique (SIRS) : définie par 2+ critères parmi FC > 90, FR > 20, T > 38 ou < 36, GB > 12 000 ou < 4 000
- Tempête cytokinique : inflammation incontrôlée → défaillance multi-organes

#### Nécrose
- Nécrose de coagulation (ischémie) : cellules mortes mais architecture conservée temporairement
- Nécrose de liquéfaction (infection bactérienne) : lyse complète → pus
- Nécrose gazeuse (gangrène gazeuse, Clostridium) : progression **2–3 cm/h**, létal si non amputé
- Nécrose cutanée sèche (gangrène sèche, ischémie distale) : lente, jours à semaines

#### Sepsis
- Définition : réponse inflammatoire systémique à infection → défaillance organique
- Progression : infection locale → bactériémie → sepsis → choc septique
- Délai infection → sepsis : 6–48h selon virulence
- Choc septique : hypotension réfractaire malgré remplissage → mortalité 30–50%
- Sans traitement antibiotique : mort en **24–72h** pour sepsis fulminant
- Indicateurs : lactate > 2 mmol/L, hypotension, confusion, oligurie (< 0.5 mL/kg/h)

---

### 8. Modèles de Référence — RimWorld & Dwarf Fortress

#### RimWorld — système de parties du corps
- Chaque créature = **arbre hiérarchique de parties corporelles**
  - `Body` → `Torso` → `Lung (x2)`, `Heart`, `Liver`, `Kidney (x2)`, `Spine`
  - `Torso` → `Arm (x2)` → `Hand` → `Finger (x5)`
  - `Torso` → `Leg (x2)` → `Foot` → `Toe (x5)`
  - `Head` → `Brain`, `Eye (x2)`, `Ear (x2)`, `Nose`, `Jaw`
- Chaque partie a un attribut `hitPoints` (HP) et un `maxHitPoints`
- Dommage localisé : réduction HP de la partie, effets fonctionnels selon la partie
  - Jambe détruite → handicap locomoteur (-40% vitesse de déplacement)
  - Poumon à 50% → -25% VO2max simulé
  - Rein unique → seuil de tolérance réduit aux toxines

**Hémorragie RimWorld :**
- Toute blessure ouverte génère un taux `bleedingRate` (par tick)
- `bloodLoss` s'accumule jusqu'à 1.0 → mort
- Seuils : 0.1 = légère, 0.5 = grave, 1.0 = mortelle
- Coagulation spontanée des petites blessures au bout de ~X ticks
- La blessure traitée (bandage) réduit `bleedingRate` à 0

**Maladies RimWorld :**
- `Severity` (0.0–1.0) évolue au fil du temps selon une courbe paramétrique
- Chaque état (`Malaria`, `Flu`, `Plague`) a ses propres `initialSeverity`, `naturalHealingFactor`, `letterSeverity`
- Immunité se développe séparément : si `immunityGainSpeed` > `severityPerDay` → guérison

#### Dwarf Fortress — simulation anatomique avancée
- Modèle basé sur la **physique des matériaux** : chaque tissu a des propriétés (densité, ténacité, élasticité)
- Frappe → calcul de pénétration selon arme + tissu + os + organe en dessous
- **Hémorragie interne** : artères et veines modélisées, section → hémorragie interne selon débit
- **Système nerveux** : section de nerf → paralysie de la zone distale
- Fracture : os fracturé → douleur, handicap, risque d'embolie graisseuse
- **Conscience** : fonction de la douleur totale, perte de sang, dommages cérébraux
  - `pain > threshold` → KO
- Organes manquants : le nain continue à fonctionner avec un seul rein, une seule main, etc.
- Régénération : DF ne simule pas de régénération (contrairement à RimWorld avec médecine)
- Matériaux biologiques dans DF :
  - Peau : `SKIN_LAYER`, absorption choc
  - Graisse sous-cutanée : amortissement
  - Muscle : force, résistance aux impacts
  - Os : dureté, résistance compression

**Comparaison RimWorld vs DF pour Primordia :**
| Aspect | RimWorld | Dwarf Fortress | Recommandation Primordia |
|---|---|---|---|
| Granularité | Organes/parties | Tissus/couches | Organes + quelques tissus |
| Hémorragie | Rate par tick | Débit vasculaire | Rate par tick, modulé par taille vaisseau |
| Douleur | Implicite (incap) | Score explicite | Score 0.0–1.0 avec seuils |
| Maladies | Severity 0–1 | Infection par contaminant | Severity + vecteur |
| Régénération | Via soins/médecine | Non simulée | Par soins + temps + nutrition |

---

### 9. Implémentation GDScript — Classe `BodySystem`

```gdscript
## body_system.gd
## Système anatomique d'une entité — simulation physiologique complète
## Utilisé par : Entity, Creature, Player
## Standards : une responsabilité, < 500 lignes, pas de logique inline

class_name BodySystem
extends Node

# ─── Constantes ───────────────────────────────────────────────────
const BLOOD_VOLUME_RATIO := 0.07        # 7% du poids corporel
const HEMORRHAGE_LETHAL := 0.40         # 40% perte = mort
const HEMORRHAGE_SEVERE := 0.30
const HEMORRHAGE_MODERATE := 0.20
const HEMORRHAGE_LIGHT := 0.10

const LACTATE_THRESHOLD := 4.0          # mmol/L → fatigue anaérobie
const FEVER_MODERATE := 38.5
const FEVER_CRITICAL := 40.0
const FEVER_LETHAL := 42.0

const COAGULATION_RATE_SMALL := 0.002   # 0.2% volume/min petite plaie
const COAGULATION_RATE_LARGE := 0.008   # 0.8% volume/min grande plaie

# ─── Signaux ──────────────────────────────────────────────────────
signal health_critical(system_name: String, severity: float)
signal organ_failed(organ_name: String)
signal hemorrhage_state_changed(level: String)
signal death_triggered(cause: String)

# ─── Types internes ───────────────────────────────────────────────
enum HemorrhageLevel { NONE, LIGHT, MODERATE, SEVERE, LETHAL }

class BodyPart:
    var name: String
    var hp: float
    var max_hp: float
    var bleed_rate: float = 0.0     ## % volume sanguin perdu/min
    var is_vital: bool = false
    var functional: bool = true
    
    func _init(p_name: String, p_max_hp: float, p_vital: bool = false) -> void:
        name = p_name
        max_hp = p_max_hp
        hp = p_max_hp
        is_vital = p_vital
    
    func hp_ratio() -> float:
        return hp / max_hp if max_hp > 0.0 else 0.0

class DiseaseState:
    var name: String
    var severity: float = 0.0           ## 0.0 = sain, 1.0 = létal
    var immunity: float = 0.0           ## 0.0 = aucune, 1.0 = immunisé
    var severity_per_day: float = 0.1
    var immunity_gain_per_day: float = 0.05
    
    func tick(delta_days: float) -> void:
        if immunity < severity:
            severity += severity_per_day * delta_days
            severity = clampf(severity, 0.0, 1.0)
        immunity += immunity_gain_per_day * delta_days
        immunity = clampf(immunity, 0.0, 1.0)

# ─── État physiologique ───────────────────────────────────────────
var body_weight_kg: float = 70.0

## Sang
var blood_volume_max: float
var blood_volume_current: float
var hemorrhage_level: HemorrhageLevel = HemorrhageLevel.NONE

## Énergie
var energy_kcal: float = 2000.0
var energy_max: float = 2000.0
var bmr_per_hour: float

## Température
var body_temp_celsius: float = 37.0

## Fatigue musculaire
var lactate_mmol: float = 0.0
var muscle_fatigue: float = 0.0     ## 0.0 = frais, 1.0 = épuisé

## Douleur
var pain_score: float = 0.0        ## 0.0–1.0 → 0.5+ = incapacité partielle, 0.8+ = KO

## Parties du corps
var body_parts: Dictionary = {}    ## String → BodyPart

## Maladies actives
var diseases: Array[DiseaseState] = []

# ─── Initialisation ───────────────────────────────────────────────
func _ready() -> void:
    _init_blood_system()
    _init_bmr()
    _init_body_parts()

func _init_blood_system() -> void:
    blood_volume_max = body_weight_kg * BLOOD_VOLUME_RATIO * 1000.0  # en mL
    blood_volume_current = blood_volume_max

func _init_bmr() -> void:
    ## Formule Kleiber : BMR (kcal/j) = 70 × M^0.75
    var bmr_per_day := 70.0 * pow(body_weight_kg, 0.75)
    bmr_per_hour = bmr_per_day / 24.0

func _init_body_parts() -> void:
    _add_part("brain",       100.0, true)
    _add_part("heart",       100.0, true)
    _add_part("lung_left",    80.0, false)
    _add_part("lung_right",   80.0, false)
    _add_part("liver",       120.0, false)
    _add_part("kidney_left",  60.0, false)
    _add_part("kidney_right", 60.0, false)
    _add_part("spine",       150.0, true)
    _add_part("arm_left",    100.0, false)
    _add_part("arm_right",   100.0, false)
    _add_part("leg_left",    120.0, false)
    _add_part("leg_right",   120.0, false)
    _add_part("torso",       200.0, false)
    _add_part("head",        100.0, false)

func _add_part(p_name: String, p_max_hp: float, p_vital: bool) -> void:
    body_parts[p_name] = BodyPart.new(p_name, p_max_hp, p_vital)

# ─── Tick physiologique ───────────────────────────────────────────
func tick(delta_seconds: float) -> void:
    var delta_hours := delta_seconds / 3600.0
    _tick_hemorrhage(delta_seconds)
    _tick_energy(delta_hours)
    _tick_temperature()
    _tick_fatigue(delta_seconds)
    _tick_diseases(delta_hours / 24.0)
    _evaluate_death()

func _tick_hemorrhage(delta_seconds: float) -> void:
    var total_bleed := 0.0
    for part in body_parts.values():
        total_bleed += part.bleed_rate
    
    var blood_lost_ml := total_bleed * blood_volume_max * delta_seconds / 60.0
    blood_volume_current = maxf(0.0, blood_volume_current - blood_lost_ml)
    
    var loss_ratio := 1.0 - (blood_volume_current / blood_volume_max)
    var new_level := _compute_hemorrhage_level(loss_ratio)
    if new_level != hemorrhage_level:
        hemorrhage_level = new_level
        hemorrhage_state_changed.emit(HemorrhageLevel.keys()[new_level])

func _compute_hemorrhage_level(loss_ratio: float) -> HemorrhageLevel:
    if loss_ratio >= HEMORRHAGE_LETHAL:   return HemorrhageLevel.LETHAL
    if loss_ratio >= HEMORRHAGE_SEVERE:   return HemorrhageLevel.SEVERE
    if loss_ratio >= HEMORRHAGE_MODERATE: return HemorrhageLevel.MODERATE
    if loss_ratio >= HEMORRHAGE_LIGHT:    return HemorrhageLevel.LIGHT
    return HemorrhageLevel.NONE

func _tick_energy(delta_hours: float) -> void:
    ## Consommation BMR de base + fièvre
    var fever_multiplier := 1.0 + maxf(0.0, body_temp_celsius - 37.0) * 0.10
    var consumed := bmr_per_hour * delta_hours * fever_multiplier
    energy_kcal = maxf(0.0, energy_kcal - consumed)

func _tick_temperature() -> void:
    ## Régulation homéostatique passive — dériver vers 37°C
    body_temp_celsius = move_toward(body_temp_celsius, 37.0, 0.01)

func _tick_fatigue(delta_seconds: float) -> void:
    ## Récupération lactate au repos : -0.05 mmol/L/min
    lactate_mmol = maxf(0.0, lactate_mmol - 0.05 * delta_seconds / 60.0)
    if lactate_mmol < LACTATE_THRESHOLD:
        muscle_fatigue = move_toward(muscle_fatigue, 0.0, 0.001 * delta_seconds)

func _tick_diseases(delta_days: float) -> void:
    for disease in diseases:
        disease.tick(delta_days)
        if disease.severity >= 1.0:
            death_triggered.emit("disease:" + disease.name)

# ─── Dommages ─────────────────────────────────────────────────────
func apply_damage(part_name: String, damage: float, bleed_rate: float = 0.0) -> void:
    if not body_parts.has(part_name):
        return
    var part: BodyPart = body_parts[part_name]
    part.hp = maxf(0.0, part.hp - damage)
    part.bleed_rate = maxf(part.bleed_rate, bleed_rate)
    
    _update_part_function(part)
    
    if part.hp <= 0.0 and part.is_vital:
        organ_failed.emit(part_name)
        death_triggered.emit("organ_failure:" + part_name)

func treat_wound(part_name: String) -> void:
    if body_parts.has(part_name):
        body_parts[part_name].bleed_rate = 0.0

func _update_part_function(part: BodyPart) -> void:
    part.functional = part.hp > 0.0

# ─── Activité physique ────────────────────────────────────────────
func apply_exertion(intensity: float, delta_seconds: float) -> void:
    ## intensity : 0.0 = repos, 1.0 = sprint maximal
    var lactate_production := intensity * 0.5  ## mmol/L/min à intensité max
    lactate_mmol += lactate_production * delta_seconds / 60.0
    lactate_mmol = clampf(lactate_mmol, 0.0, 20.0)
    
    if lactate_mmol > LACTATE_THRESHOLD:
        muscle_fatigue += 0.01 * delta_seconds * (lactate_mmol - LACTATE_THRESHOLD)
        muscle_fatigue = clampf(muscle_fatigue, 0.0, 1.0)

# ─── Maladies ─────────────────────────────────────────────────────
func contract_disease(p_name: String, initial_severity: float,
        severity_per_day: float, immunity_gain: float) -> void:
    var d := DiseaseState.new()
    d.name = p_name
    d.severity = initial_severity
    d.severity_per_day = severity_per_day
    d.immunity_gain_per_day = immunity_gain
    diseases.append(d)

# ─── Lecture d'état ───────────────────────────────────────────────
func get_mobility() -> float:
    ## 0.0 = immobile, 1.0 = pleine mobilité
    var leg_l: BodyPart = body_parts.get("leg_left")
    var leg_r: BodyPart = body_parts.get("leg_right")
    var mobility := (leg_l.hp_ratio() + leg_r.hp_ratio()) / 2.0
    mobility *= (1.0 - muscle_fatigue * 0.5)
    return clampf(mobility, 0.0, 1.0)

func get_consciousness() -> float:
    ## Basé sur sang, douleur, énergie, cerveau
    var blood_factor := blood_volume_current / blood_volume_max
    var pain_factor := 1.0 - maxf(0.0, pain_score - 0.5) * 2.0
    var energy_factor := energy_kcal / energy_max
    var brain: BodyPart = body_parts.get("brain")
    var brain_factor := brain.hp_ratio() if brain else 1.0
    return clampf(blood_factor * pain_factor * energy_factor * brain_factor, 0.0, 1.0)

func is_alive() -> bool:
    if blood_volume_current / blood_volume_max <= (1.0 - HEMORRHAGE_LETHAL):
        return false
    var brain: BodyPart = body_parts.get("brain")
    if brain and brain.hp <= 0.0:
        return false
    return true

func _evaluate_death() -> void:
    if not is_alive():
        death_triggered.emit("physiological_failure")
```

---

### 10. Paramètres de simulation par type de créature

| Paramètre | Mammifère petit | Mammifère grand | Reptile | Insecte/arthropode |
|---|---|---|---|---|
| Masse ref | 0.5 kg | 500 kg | 2 kg | 0.005 kg |
| BMR (kcal/j) | ~33 | ~8700 | ~6 | ~0.3 |
| FC repos (bpm) | 200–400 | 30–50 | 30–50 | N/A |
| Vol sanguin (% poids) | 7% | 7% | 5–6% | Hémolymphe, 20–40% |
| VO2max relatif | Élevé | Moyen | Très faible | Variable |
| Regen peau | Rapide (jours) | Lente (semaines) | Très lente | Mue (pas regen) |
| Coagulation | Minutes | Minutes | Très lente | Hémolymphe coagule vite |

---

*Document de référence interne Primordia — valeurs numériques validées pour implémentation directe en GDScript.*
